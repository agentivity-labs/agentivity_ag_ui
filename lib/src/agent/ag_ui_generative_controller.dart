import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../protocol/ag_ui_protocol.dart';
import '../tools/ag_ui_frontend_tool.dart';
import '../tools/ag_ui_widget_registry.dart';

// ── Item model ────────────────────────────────────────────────────────────────

/// A single renderable item in a generative conversation.
sealed class AgUiGenerativeItem {
  const AgUiGenerativeItem();
}

/// A streamed or completed text message.
class AgUiTextItem extends AgUiGenerativeItem {
  const AgUiTextItem({
    required this.messageId,
    required this.role,
    required this.text,
    this.isStreaming = false,
  });
  final String messageId;
  final String role;
  final String text;

  /// `true` while the message is still being streamed.
  final bool isStreaming;
}

/// A reasoning / chain-of-thought block.
class AgUiReasoningItem extends AgUiGenerativeItem {
  const AgUiReasoningItem({
    required this.messageId,
    required this.text,
    this.isStreaming = false,
  });
  final String messageId;
  final String text;
  final bool isStreaming;
}

/// A dynamically rendered component resolved from [AgUiWidgetRegistry].
class AgUiComponentItem extends AgUiGenerativeItem {
  const AgUiComponentItem({required this.component, required this.props});
  final String component;
  final Map<String, dynamic> props;
}

/// Agent-generated HTML for open-ended generative UI.
///
/// Rendered by [AgUiGenerativeView] via its [AgUiGenerativeView.htmlBuilder].
/// If no [htmlBuilder] is provided, a labelled placeholder is shown instead.
///
/// Triggered by a `CUSTOM` event with `name == "html"` or `"ag-ui:html"`:
/// ```json
/// {"type":"CUSTOM","name":"ag-ui:html","value":{"html":"<h1>Hello</h1>","height":200}}
/// ```
class AgUiHtmlItem extends AgUiGenerativeItem {
  const AgUiHtmlItem({required this.html, this.height});

  /// The raw HTML string emitted by the agent.
  final String html;

  /// Suggested render height in logical pixels, or `null` for unconstrained.
  final double? height;
}

enum AgUiToolCallStatus { pending, running, completed, failed }

/// A tool call in progress or completed.
class AgUiToolCallItem extends AgUiGenerativeItem {
  const AgUiToolCallItem({
    required this.toolCallId,
    required this.toolCallName,
    required this.status,
    this.result,
    this.error,
  });
  final String toolCallId;
  final String toolCallName;
  final AgUiToolCallStatus status;

  /// The tool result. String for backend tools; arbitrary for frontend tools.
  final dynamic result;
  final String? error;

  AgUiToolCallItem copyWith({
    AgUiToolCallStatus? status,
    dynamic result,
    String? error,
  }) =>
      AgUiToolCallItem(
        toolCallId: toolCallId,
        toolCallName: toolCallName,
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

/// Processes a `Stream<AgUiEvent>` and maintains a live list of [AgUiGenerativeItem]s
/// for rendering by [AgUiGenerativeView].
///
/// Generative UI works in two complementary ways:
///
/// **Via tool calls**: the agent calls a tool whose name matches a component in
/// [widgetRegistry]. The controller replaces the tool-call placeholder with the
/// rendered component.
///
/// **Via CUSTOM events**: the agent emits `{"type":"CUSTOM","name":"render","value":
/// {"component":"MyCard","props":{...}}}`. The controller resolves it through
/// [widgetRegistry].
///
/// Frontend tools (in [toolRegistry]) are executed locally on the device; their
/// results are shown inline without a round-trip to the backend.
class AgUiGenerativeController extends ChangeNotifier {
  AgUiGenerativeController({
    required Stream<AgUiEvent> events,
    this.toolRegistry,
    this.widgetRegistry,
  }) {
    _sub = events.listen(_onEvent, onError: (_) {}, cancelOnError: false);
  }

  final AgUiFrontendToolRegistry? toolRegistry;
  final AgUiWidgetRegistry? widgetRegistry;

  List<AgUiGenerativeItem> _items = const [];
  final Map<String, _PendingText> _pendingTexts = {};
  final Map<String, _PendingReasoning> _pendingReasoning = {};
  final Map<String, _PendingTool> _pendingTools = {};
  StreamSubscription<AgUiEvent>? _sub;

  List<AgUiGenerativeItem> get items => List.unmodifiable(_items);

  // ── Event dispatch ──────────────────────────────────────────────────────────

  void _onEvent(AgUiEvent event) {
    switch (event) {
      case TextMessageStartEvent e:
        _pendingTexts[e.messageId] = _PendingText(e.messageId, e.role);
        _items = [
          ..._items,
          AgUiTextItem(messageId: e.messageId, role: e.role, text: '', isStreaming: true),
        ];
        notifyListeners();

      case TextMessageContentEvent e:
        _pendingTexts[e.messageId]?.buffer.write(e.delta);
        _patchText(e.messageId);
        notifyListeners();

      case TextMessageEndEvent e:
        _pendingTexts.remove(e.messageId);
        _patchText(e.messageId, isStreaming: false);
        notifyListeners();

      case TextMessageChunkEvent e:
        final id = e.messageId;
        final delta = e.delta;
        if (id != null && delta != null) {
          if (!_pendingTexts.containsKey(id)) {
            _pendingTexts[id] = _PendingText(id, e.role ?? 'assistant');
            _items = [
              ..._items,
              AgUiTextItem(
                  messageId: id, role: e.role ?? 'assistant', text: '', isStreaming: true),
            ];
          }
          _pendingTexts[id]!.buffer.write(delta);
          _patchText(id);
          notifyListeners();
        }

      case ReasoningMessageStartEvent e:
        _pendingReasoning[e.messageId] = _PendingReasoning(e.messageId);
        _items = [
          ..._items,
          AgUiReasoningItem(messageId: e.messageId, text: '', isStreaming: true),
        ];
        notifyListeners();

      case ReasoningMessageContentEvent e:
        _pendingReasoning[e.messageId]?.buffer.write(e.delta);
        _patchReasoning(e.messageId);
        notifyListeners();

      case ReasoningMessageEndEvent e:
        _pendingReasoning.remove(e.messageId);
        _patchReasoning(e.messageId, isStreaming: false);
        notifyListeners();

      case ReasoningMessageChunkEvent e:
        final id = e.messageId;
        final delta = e.delta;
        if (id != null && delta != null) {
          if (!_pendingReasoning.containsKey(id)) {
            _pendingReasoning[id] = _PendingReasoning(id);
            _items = [
              ..._items,
              AgUiReasoningItem(messageId: id, text: '', isStreaming: true),
            ];
          }
          _pendingReasoning[id]!.buffer.write(delta);
          _patchReasoning(id);
          notifyListeners();
        }

      case ToolCallStartEvent e:
        _pendingTools[e.toolCallId] = _PendingTool(e.toolCallId, e.toolCallName);
        _items = [
          ..._items,
          AgUiToolCallItem(
            toolCallId: e.toolCallId,
            toolCallName: e.toolCallName,
            status: AgUiToolCallStatus.pending,
          ),
        ];
        notifyListeners();

      case ToolCallArgsDeltaEvent e:
        _pendingTools[e.toolCallId]?.argsBuffer.write(e.delta);

      case ToolCallChunkEvent e:
        final id = e.toolCallId;
        if (id != null) {
          if (!_pendingTools.containsKey(id) && e.toolCallName != null) {
            _pendingTools[id] = _PendingTool(id, e.toolCallName!);
            _items = [
              ..._items,
              AgUiToolCallItem(
                toolCallId: id,
                toolCallName: e.toolCallName!,
                status: AgUiToolCallStatus.pending,
              ),
            ];
            notifyListeners();
          }
          final delta = e.delta;
          if (delta != null && _pendingTools.containsKey(id)) {
            _pendingTools[id]!.argsBuffer.write(delta);
          }
        }

      case ToolCallEndEvent e:
        _completeTool(e.toolCallId);

      case ToolCallResultEvent e:
        _applyBackendResult(e.toolCallId, e.content);

      case CustomEvent e
          when e.name == 'render' || e.name == 'ag-ui:render':
        _applyRenderEvent(e.value);

      case CustomEvent e when e.name == 'html' || e.name == 'ag-ui:html':
        _applyHtmlEvent(e.value);

      default:
        break;
    }
  }

  // ── Tool completion ─────────────────────────────────────────────────────────

  void _completeTool(String toolCallId) {
    final pending = _pendingTools.remove(toolCallId);
    if (pending == null) return;

    final args = _parseArgs(pending.argsBuffer.toString());

    if (widgetRegistry != null && widgetRegistry!.has(pending.toolCallName)) {
      _replaceItem(
        toolCallId,
        AgUiComponentItem(component: pending.toolCallName, props: args),
      );
      notifyListeners();
      return;
    }

    if (toolRegistry != null && toolRegistry!.has(pending.toolCallName)) {
      _patchToolItem(toolCallId, status: AgUiToolCallStatus.running);
      notifyListeners();
      toolRegistry!.execute(pending.toolCallName, args).then((result) {
        _patchToolItem(toolCallId, status: AgUiToolCallStatus.completed, result: result);
        notifyListeners();
      }).catchError((Object e) {
        _patchToolItem(toolCallId, status: AgUiToolCallStatus.failed, error: e.toString());
        notifyListeners();
      });
      return;
    }

    _patchToolItem(toolCallId, status: AgUiToolCallStatus.running);
    notifyListeners();
  }

  void _applyBackendResult(String toolCallId, String content) {
    _patchToolItem(toolCallId, status: AgUiToolCallStatus.completed, result: content);
    notifyListeners();
  }

  void _applyRenderEvent(dynamic value) {
    if (value is! Map) return;
    final component = value['component']?.toString();
    if (component == null || component.isEmpty) return;
    final props = value['props'] is Map
        ? Map<String, dynamic>.from(value['props'] as Map)
        : <String, dynamic>{};
    _items = [..._items, AgUiComponentItem(component: component, props: props)];
    notifyListeners();
  }

  void _applyHtmlEvent(dynamic value) {
    final html = value is Map
        ? value['html']?.toString()
        : value?.toString();
    if (html == null || html.isEmpty) return;
    final height = value is Map && value['height'] is num
        ? (value['height'] as num).toDouble()
        : null;
    _items = [..._items, AgUiHtmlItem(html: html, height: height)];
    notifyListeners();
  }

  // ── Item patching helpers ───────────────────────────────────────────────────

  void _patchText(String messageId, {bool? isStreaming}) {
    final pending = _pendingTexts[messageId];
    final idx = _indexOfText(messageId);
    final role = pending?.role ??
        (idx >= 0 ? (_items[idx] as AgUiTextItem).role : 'assistant');
    final streaming = isStreaming ?? (idx >= 0 ? (_items[idx] as AgUiTextItem).isStreaming : false);
    final updated = AgUiTextItem(
      messageId: messageId,
      role: role,
      text: pending?.buffer.toString() ?? (idx >= 0 ? (_items[idx] as AgUiTextItem).text : ''),
      isStreaming: streaming,
    );
    if (idx >= 0) {
      _items = List<AgUiGenerativeItem>.from(_items)..[idx] = updated;
    } else {
      _items = [..._items, updated];
    }
  }

  void _patchReasoning(String messageId, {bool? isStreaming}) {
    final pending = _pendingReasoning[messageId];
    final idx = _indexOfReasoning(messageId);
    final streaming =
        isStreaming ?? (idx >= 0 ? (_items[idx] as AgUiReasoningItem).isStreaming : false);
    final text = pending?.buffer.toString() ??
        (idx >= 0 ? (_items[idx] as AgUiReasoningItem).text : '');
    final updated = AgUiReasoningItem(
        messageId: messageId, text: text, isStreaming: streaming);
    if (idx >= 0) {
      _items = List<AgUiGenerativeItem>.from(_items)..[idx] = updated;
    } else {
      _items = [..._items, updated];
    }
  }

  void _patchToolItem(String toolCallId,
      {AgUiToolCallStatus? status, dynamic result, String? error}) {
    final idx = _indexOfTool(toolCallId);
    if (idx < 0) return;
    final existing = _items[idx] as AgUiToolCallItem;
    _items = List<AgUiGenerativeItem>.from(_items)
      ..[idx] = existing.copyWith(status: status, result: result, error: error);
  }

  void _replaceItem(String toolCallId, AgUiGenerativeItem replacement) {
    final idx = _indexOfTool(toolCallId);
    if (idx >= 0) {
      _items = List<AgUiGenerativeItem>.from(_items)..[idx] = replacement;
    } else {
      _items = [..._items, replacement];
    }
  }

  int _indexOfText(String messageId) => _items
      .indexWhere((i) => i is AgUiTextItem && i.messageId == messageId);

  int _indexOfReasoning(String messageId) => _items
      .indexWhere((i) => i is AgUiReasoningItem && i.messageId == messageId);

  int _indexOfTool(String toolCallId) => _items
      .indexWhere((i) => i is AgUiToolCallItem && i.toolCallId == toolCallId);

  static Map<String, dynamic> _parseArgs(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  /// Remove all items and cancel pending state. Does not cancel the stream.
  void clear() {
    _items = const [];
    _pendingTexts.clear();
    _pendingReasoning.clear();
    _pendingTools.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ── Private state bags ────────────────────────────────────────────────────────

class _PendingText {
  _PendingText(this.messageId, this.role);
  final String messageId;
  final String role;
  final StringBuffer buffer = StringBuffer();
}

class _PendingReasoning {
  _PendingReasoning(this.messageId);
  final String messageId;
  final StringBuffer buffer = StringBuffer();
}

class _PendingTool {
  _PendingTool(this.toolCallId, this.toolCallName);
  final String toolCallId;
  final String toolCallName;
  final StringBuffer argsBuffer = StringBuffer();
}
