import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../protocol/ag_ui_protocol.dart';
import '../protocol/ag_ui_sse_channel.dart';
import '../protocol/run_agent_input.dart';

/// A connector for any backend that natively speaks the AG-UI protocol over SSE.
///
/// Use this when your backend already emits AG-UI events (e.g. via the official
/// [ag-ui Python adapter](https://github.com/ag-ui-protocol/ag-ui), the
/// LangGraph ag-ui bridge, or any other AG-UI-compliant endpoint).
///
/// The connector POSTs a [RunAgentInput] body to [baseUrl] + [path], then
/// consumes the SSE response as a stream of [AgUiEvent]s. The underlying
/// [AgUiSseChannel] handles reconnection with exponential back-off and a
/// watchdog timer; the stream ends cleanly when a [RunFinishedEvent] or
/// [RunErrorEvent] is received.
///
/// ## Basic usage
///
/// ```dart
/// final connector = AgUiGenericConnector(
///   baseUrl: 'https://my-backend.example.com',
///   headers: {'Authorization': 'Bearer $token'},
/// );
///
/// final stream = connector.run(
///   path: '/api/agent',
///   input: RunAgentInput(
///     threadId: 'thread-1',
///     runId: 'run-1',
///     messages: [
///       buildAgUiMessage('user', text: 'Find me a great espresso machine'),
///     ],
///   ),
/// );
///
/// final ctrl = AgUiGenerativeController(events: stream.asBroadcastStream());
/// ctrl.addListener(() => setState(() {}));
/// ```
///
/// ## Feeding all four controllers
///
/// ```dart
/// final broadcast = connector.run(path: '/api/agent', input: input)
///     .asBroadcastStream();
///
/// _lifecycle = AgUiRunLifecycleController(events: broadcast);
/// _activity  = AgUiActivityController(events: broadcast);
/// _state     = AgUiStateController(events: broadcast);
/// _gen       = AgUiGenerativeController(events: broadcast);
/// ```
class AgUiGenericConnector {
  AgUiGenericConnector({
    required this.baseUrl,
    this.headers = const {},
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Root URL of your AG-UI-compatible backend (no trailing slash).
  ///
  /// Example: `'https://my-backend.example.com'`
  final String baseUrl;

  /// HTTP headers added to every request.
  ///
  /// Common use: `{'Authorization': 'Bearer $token'}`.
  /// `Accept: text/event-stream` and `Content-Type: application/json` are
  /// set automatically.
  final Map<String, String> headers;

  final Dio _dio;

  /// Starts an agent run at [baseUrl] + [path] and returns a live stream of
  /// [AgUiEvent]s.
  ///
  /// The stream terminates automatically when a [RunFinishedEvent] or
  /// [RunErrorEvent] arrives. Reconnection is handled internally by
  /// [AgUiSseChannel].
  ///
  /// [input] is serialised as the POST body. Pass `null` to send an empty
  /// object (useful for stateless single-shot agents).
  Stream<AgUiEvent> run({
    required String path,
    RunAgentInput? input,
  }) =>
      _runStream(path: path, body: input?.toJson() ?? const {});

  // ── Internal ───────────────────────────────────────────────────────────────

  Stream<AgUiEvent> _runStream({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String> extraHeaders = const {},
  }) async* {
    final channel = AgUiSseChannel<AgUiEvent>(
      opener: (p, {lastEventId, cancelToken}) async {
        final response = await _dio.post<ResponseBody>(
          baseUrl + p,
          data: body,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Accept': 'text/event-stream',
              'Content-Type': 'application/json',
              if (lastEventId != null) 'Last-Event-ID': lastEventId,
              ...headers,
              ...extraHeaders,
            },
          ),
        );
        return response.data!;
      },
      path: path,
      parser: _parseAgUiEvent,
    );

    channel.start();
    try {
      await for (final event in channel.stream) {
        yield event;
        if (event is RunFinishedEvent || event is RunErrorEvent) break;
      }
    } finally {
      await channel.dispose();
    }
  }

  static AgUiEvent? _parseAgUiEvent(String event, String? id, String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) return AgUiEvent.fromJson(json);
    } catch (_) {
      // Malformed frame — silently discard.
    }
    return null;
  }
}
