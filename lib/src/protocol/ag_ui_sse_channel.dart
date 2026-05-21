import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Opens a raw SSE byte stream at [path].
///
/// The implementation is responsible for setting the correct headers
/// (Accept: text/event-stream, Last-Event-ID if provided).
/// [cancelToken] allows in-flight requests to be aborted on reconnect/dispose.
typedef AgUiSseOpener = Future<ResponseBody> Function(
  String path, {
  String? lastEventId,
  CancelToken? cancelToken,
});

/// Parses a raw SSE frame into a typed event [T].
/// Return `null` to silently discard the event.
typedef AgUiSseParser<T> = T? Function(String event, String? id, String? data);

/// Generic, reconnecting SSE channel.
///
/// Usage:
/// ```dart
/// final channel = AgUiSseChannel<MyEvent>(
///   opener: (path, {lastEventId, cancelToken}) => dio.get<ResponseBody>(
///     path,
///     cancelToken: cancelToken,
///     options: Options(
///       responseType: ResponseType.stream,
///       headers: {
///         'Accept': 'text/event-stream',
///         if (lastEventId != null) 'Last-Event-ID': lastEventId,
///       },
///     ),
///   ).then((r) => r.data!),
///   path: '/streams/runs/$runId/events',
///   parser: (event, id, data) => MyEvent.fromSse(event, data),
/// );
/// channel.start();
/// channel.stream.listen((event) { … });
/// await channel.dispose();
/// ```
class AgUiSseChannel<T> {
  static const Duration _defaultRetryDelay = Duration(seconds: 5);
  static const Duration _maxRetryDelay = Duration(minutes: 1);
  static const Duration _watchdogInterval = Duration(seconds: 15);
  static const Duration _inactivityTimeout = Duration(seconds: 45);

  AgUiSseChannel({
    required AgUiSseOpener opener,
    required String path,
    required AgUiSseParser<T> parser,
  })  : _opener = opener,
        _path = path,
        _parser = parser;

  final AgUiSseOpener _opener;
  final String _path;
  final AgUiSseParser<T> _parser;

  final StreamController<T> _controller = StreamController<T>.broadcast();
  final ValueNotifier<bool> connectedNotifier = ValueNotifier<bool>(false);

  Stream<T> get stream => _controller.stream;
  bool get isConnected => connectedNotifier.value;

  StreamSubscription<String>? _lineSub;
  CancelToken? _cancelToken;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  String? _lastEventId;
  DateTime? _lastActivityAt;
  Duration _serverRetryDelay = _defaultRetryDelay;
  int _reconnectAttempts = 0;
  final math.Random _random = math.Random();
  bool _started = false;
  bool _disposed = false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_connect());
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    connectedNotifier.value = false;
    connectedNotifier.dispose();
    await _lineSub?.cancel();
    _lineSub = null;
    _cancelToken?.cancel('disposed');
    _cancelToken = null;
    await _controller.close();
  }

  Future<void> _connect() async {
    if (_disposed) return;
    _cancelToken?.cancel('reconnect');
    _cancelToken = CancelToken();

    try {
      final responseBody = await _opener(
        _path,
        lastEventId: _lastEventId,
        cancelToken: _cancelToken,
      );
      if (_disposed || (_cancelToken?.isCancelled ?? false)) return;

      _reconnectAttempts = 0;
      connectedNotifier.value = true;
      _recordActivity();
      _startWatchdog();

      final frameParser = _SseFrameParser(onEvent: _handleFrame);
      _lineSub = responseBody.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          _recordActivity();
          frameParser.addLine(line);
        },
        onError: (Object error, StackTrace stackTrace) {
          frameParser.close();
          final isCancelled = error is DioException && CancelToken.isCancel(error);
          if (!_disposed && !isCancelled) {
            debugPrint('AgUiSseChannel error on $_path: $error');
          }
          _handleDisconnect();
        },
        onDone: () {
          frameParser.close();
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } on Object catch (error) {
      final isCancelled = error is DioException && CancelToken.isCancel(error);
      if (_disposed || isCancelled) return;
      debugPrint('AgUiSseChannel failed to connect $_path: $error');
      _handleDisconnect();
    }
  }

  void _handleFrame(_SseFrame frame) {
    _recordActivity();
    if (frame.id != null && frame.id!.trim().isNotEmpty) {
      _lastEventId = frame.id!.trim();
    }
    if (frame.retryDelay != null) _serverRetryDelay = frame.retryDelay!;
    if (_controller.isClosed) return;
    try {
      final parsed = _parser(frame.event, frame.id, frame.data);
      if (parsed != null) _controller.add(parsed);
    } on Object catch (e) {
      debugPrint('AgUiSseChannel parser error on $_path: $e');
    }
  }

  void _handleDisconnect() {
    connectedNotifier.value = false;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _lineSub = null;
    _cancelToken = null;
    if (_disposed || _reconnectTimer != null) return;
    final delay = _computeReconnectDelay();
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_disposed) unawaited(_connect());
    });
  }

  void _recordActivity() => _lastActivityAt = DateTime.now().toUtc();

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      if (_disposed) return;
      final last = _lastActivityAt;
      if (last == null) return;
      if (DateTime.now().toUtc().difference(last) >= _inactivityTimeout) {
        debugPrint('AgUiSseChannel watchdog reconnect on $_path.');
        _lineSub?.cancel();
        _lineSub = null;
        _cancelToken?.cancel('watchdog-timeout');
        _cancelToken = null;
        _handleDisconnect();
      }
    });
  }

  Duration _computeReconnectDelay() {
    final baseMs = _serverRetryDelay.inMilliseconds;
    final cappedMs = math.min(
      baseMs * (1 << math.min(_reconnectAttempts, 5)),
      _maxRetryDelay.inMilliseconds,
    );
    _reconnectAttempts += 1;
    return Duration(milliseconds: cappedMs + _random.nextInt(750));
  }
}

// ── SSE frame parser (RFC 8895) ───────────────────────────────────────────────

class _SseFrameParser {
  _SseFrameParser({required this.onEvent});

  final void Function(_SseFrame frame) onEvent;

  final List<String> _dataLines = <String>[];
  String _event = 'message';
  String? _id;
  Duration? _retryDelay;
  bool _hasContent = false;

  void addLine(String line) {
    if (line.isEmpty) {
      _dispatch();
      return;
    }
    if (line.startsWith(':')) return; // comment

    final sep = line.indexOf(':');
    final field = sep < 0 ? line : line.substring(0, sep);
    var value = sep < 0 ? '' : line.substring(sep + 1);
    if (value.startsWith(' ')) value = value.substring(1);

    switch (field) {
      case 'event':
        _event = value;
        _hasContent = true;
      case 'data':
        _dataLines.add(value);
        _hasContent = true;
      case 'id':
        _id = value;
        _hasContent = true;
      case 'retry':
        final ms = int.tryParse(value);
        if (ms != null && ms > 0) _retryDelay = Duration(milliseconds: ms);
        _hasContent = true;
    }
  }

  void close() => _dispatch();

  void _dispatch() {
    if (!_hasContent) return;
    onEvent(_SseFrame(
      event: _event,
      data: _dataLines.isEmpty ? null : _dataLines.join('\n'),
      id: _id,
      retryDelay: _retryDelay,
    ));
    _event = 'message';
    _dataLines.clear();
    _id = null;
    _retryDelay = null;
    _hasContent = false;
  }
}

class _SseFrame {
  const _SseFrame({required this.event, this.data, this.id, this.retryDelay});

  final String event;
  final String? data;
  final String? id;
  final Duration? retryDelay;
}
