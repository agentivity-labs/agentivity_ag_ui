import 'dart:convert';

/// AG-UI standard event types.
///
/// Based on the AG-UI open protocol spec: https://docs.ag-ui.com/concepts/events
///
/// Parse raw SSE frames with [AgUiEvent.fromJson], or use the ready-made
/// [agUiEventParser] with [AgUiSseChannel].
sealed class AgUiEvent {
  const AgUiEvent({required this.type, this.timestamp});

  final String type;

  /// Unix timestamp in milliseconds, if provided by the backend.
  final int? timestamp;

  factory AgUiEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final ts = _parseInt(json['timestamp']);
    return switch (type) {
      // Run lifecycle
      'RUN_STARTED' => RunStartedEvent._(
          type: type,
          timestamp: ts,
          threadId: _opt(json, 'threadId'),
          runId: _str(json, 'runId'),
          parentRunId: _opt(json, 'parentRunId'),
          input: json['input'] is Map
              ? Map<String, dynamic>.from(json['input'] as Map)
              : null),
      'RUN_FINISHED' => RunFinishedEvent._(
          type: type,
          timestamp: ts,
          threadId: _opt(json, 'threadId'),
          runId: _str(json, 'runId'),
          outcome: _parseOutcome(json['outcome']),
          result: json['result']),
      'RUN_ERROR' => RunErrorEvent._(
          type: type,
          timestamp: ts,
          message: _str(json, 'message'),
          code: _opt(json, 'code')),
      // Steps
      'STEP_STARTED' => StepStartedEvent._(
          type: type, timestamp: ts, stepName: _str(json, 'stepName')),
      'STEP_FINISHED' => StepFinishedEvent._(
          type: type, timestamp: ts, stepName: _str(json, 'stepName')),
      // Text messages — streaming
      'TEXT_MESSAGE_START' => TextMessageStartEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          role: _str(json, 'role').isEmpty ? 'assistant' : _str(json, 'role'),
          name: _opt(json, 'name')),
      'TEXT_MESSAGE_CONTENT' => TextMessageContentEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          delta: _str(json, 'delta')),
      'TEXT_MESSAGE_END' => TextMessageEndEvent._(
          type: type, timestamp: ts, messageId: _str(json, 'messageId')),
      // Text messages — combined chunk (convenience event)
      'TEXT_MESSAGE_CHUNK' => TextMessageChunkEvent._(
          type: type,
          timestamp: ts,
          messageId: _opt(json, 'messageId'),
          role: _opt(json, 'role'),
          delta: _opt(json, 'delta'),
          name: _opt(json, 'name')),
      // Tool calls — streaming
      'TOOL_CALL_START' => ToolCallStartEvent._(
          type: type,
          timestamp: ts,
          toolCallId: _str(json, 'toolCallId'),
          // spec: toolCallName; tolerate legacy toolName
          toolCallName: _str(json, 'toolCallName').isNotEmpty
              ? _str(json, 'toolCallName')
              : _str(json, 'toolName'),
          parentMessageId: _opt(json, 'parentMessageId')),
      // TOOL_CALL_ARGS is the spec name; tolerate legacy TOOL_CALL_ARGS_DELTA
      'TOOL_CALL_ARGS' || 'TOOL_CALL_ARGS_DELTA' => ToolCallArgsDeltaEvent._(
          type: type,
          timestamp: ts,
          toolCallId: _str(json, 'toolCallId'),
          delta: _str(json, 'delta')),
      'TOOL_CALL_END' => ToolCallEndEvent._(
          type: type, timestamp: ts, toolCallId: _str(json, 'toolCallId')),
      'TOOL_CALL_CHUNK' => ToolCallChunkEvent._(
          type: type,
          timestamp: ts,
          toolCallId: _opt(json, 'toolCallId'),
          toolCallName: _opt(json, 'toolCallName'),
          parentMessageId: _opt(json, 'parentMessageId'),
          delta: _opt(json, 'delta')),
      // Tool call result — content is a String in the spec
      'TOOL_CALL_RESULT' => ToolCallResultEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          toolCallId: _str(json, 'toolCallId'),
          // spec: content (String); tolerate legacy result
          content: _str(json, 'content').isNotEmpty
              ? _str(json, 'content')
              : (json['result']?.toString() ?? ''),
          role: _opt(json, 'role')),
      // Reasoning / thinking
      'REASONING_START' => ReasoningStartEvent._(
          type: type, timestamp: ts, messageId: _str(json, 'messageId')),
      'REASONING_MESSAGE_START' => ReasoningMessageStartEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          role: _str(json, 'role').isEmpty ? 'reasoning' : _str(json, 'role')),
      'REASONING_MESSAGE_CONTENT' => ReasoningMessageContentEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          delta: _str(json, 'delta')),
      'REASONING_MESSAGE_END' => ReasoningMessageEndEvent._(
          type: type, timestamp: ts, messageId: _str(json, 'messageId')),
      'REASONING_END' => ReasoningEndEvent._(
          type: type, timestamp: ts, messageId: _str(json, 'messageId')),
      // State
      'STATE_SNAPSHOT' => StateSnapshotEvent._(
          type: type, timestamp: ts, snapshot: json['snapshot']),
      'STATE_DELTA' => StateDeltaEvent._(
          type: type,
          timestamp: ts,
          delta: json['delta'] is List ? json['delta'] as List<dynamic> : const []),
      // Messages / activity
      'MESSAGES_SNAPSHOT' => MessagesSnapshotEvent._(
          type: type,
          timestamp: ts,
          messages: (json['messages'] as List<dynamic>?)
                  ?.whereType<Map<String, dynamic>>()
                  .toList() ??
              const []),
      'ACTIVITY_SNAPSHOT' => ActivitySnapshotEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          activityType: _str(json, 'activityType'),
          content: json['content'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(json['content'] as Map)
              : const {},
          replace: json['replace'] != false),
      'ACTIVITY_DELTA' => ActivityDeltaEvent._(
          type: type,
          timestamp: ts,
          messageId: _str(json, 'messageId'),
          activityType: _str(json, 'activityType'),
          patch: json['patch'] is List ? json['patch'] as List<dynamic> : const []),
      // Reasoning — chunk convenience + encrypted value
      'REASONING_MESSAGE_CHUNK' => ReasoningMessageChunkEvent._(
          type: type,
          timestamp: ts,
          messageId: _opt(json, 'messageId'),
          delta: _opt(json, 'delta')),
      'REASONING_ENCRYPTED_VALUE' => ReasoningEncryptedValueEvent._(
          type: type,
          timestamp: ts,
          subtype: _str(json, 'subtype'),
          entityId: _str(json, 'entityId'),
          encryptedValue: _str(json, 'encryptedValue')),
      // Raw / custom
      'RAW' => RawEvent._(
          type: type,
          timestamp: ts,
          event: json['event'],
          source: _opt(json, 'source')),
      'CUSTOM' => CustomEvent._(
          type: type,
          timestamp: ts,
          name: _str(json, 'name'),
          value: json['value']),
      _ => UnknownEvent._(type: type, timestamp: ts, raw: json),
    };
  }
}

// ── Run lifecycle ─────────────────────────────────────────────────────────────

final class RunStartedEvent extends AgUiEvent {
  const RunStartedEvent._(
      {required super.type,
      super.timestamp,
      this.threadId,
      required this.runId,
      this.parentRunId,
      this.input});
  final String? threadId;
  final String runId;
  final String? parentRunId;
  final Map<String, dynamic>? input;
}

/// A run completed. Check [outcome] for success vs interrupt.
final class RunFinishedEvent extends AgUiEvent {
  const RunFinishedEvent._(
      {required super.type,
      super.timestamp,
      this.threadId,
      required this.runId,
      this.outcome,
      this.result});
  final String? threadId;
  final String runId;

  /// `null` = legacy success (no outcome field in payload).
  final AgUiRunOutcome? outcome;
  final dynamic result;

  bool get isInterrupted => outcome is AgUiInterruptOutcome;
}

final class RunErrorEvent extends AgUiEvent {
  const RunErrorEvent._(
      {required super.type,
      super.timestamp,
      required this.message,
      this.code});
  final String message;
  final String? code;
}

// ── Run outcome / interrupts ──────────────────────────────────────────────────

/// Outcome carried by [RunFinishedEvent] when the agent uses the interrupt protocol.
sealed class AgUiRunOutcome {
  const AgUiRunOutcome();
}

class AgUiSuccessOutcome extends AgUiRunOutcome {
  const AgUiSuccessOutcome();
}

class AgUiInterruptOutcome extends AgUiRunOutcome {
  const AgUiInterruptOutcome({required this.interrupts});
  final List<AgUiInterrupt> interrupts;
}

/// An agent interrupt — the agent paused and needs human input before resuming.
///
/// Send a `resume` entry in the next `RunAgentInput` to unblock the agent.
class AgUiInterrupt {
  const AgUiInterrupt({
    required this.id,
    required this.reason,
    this.message,
    this.toolCallId,
    this.responseSchema,
    this.expiresAt,
    this.metadata,
  });

  final String id;
  final String reason;
  final String? message;
  final String? toolCallId;

  /// JSON Schema describing the shape of the expected resume payload.
  final Map<String, dynamic>? responseSchema;
  final String? expiresAt;
  final Map<String, dynamic>? metadata;

  factory AgUiInterrupt.fromJson(Map<String, dynamic> json) {
    return AgUiInterrupt(
      id: json['id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      message: json['message']?.toString(),
      toolCallId: json['toolCallId']?.toString(),
      responseSchema: json['responseSchema'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['responseSchema'] as Map)
          : null,
      expiresAt: json['expiresAt']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}

// ── Step lifecycle ────────────────────────────────────────────────────────────

final class StepStartedEvent extends AgUiEvent {
  const StepStartedEvent._({required super.type, super.timestamp, required this.stepName});
  final String stepName;
}

final class StepFinishedEvent extends AgUiEvent {
  const StepFinishedEvent._({required super.type, super.timestamp, required this.stepName});
  final String stepName;
}

// ── Text messages — streaming ─────────────────────────────────────────────────

final class TextMessageStartEvent extends AgUiEvent {
  const TextMessageStartEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      required this.role,
      this.name});
  final String messageId;
  final String role;
  final String? name;
}

final class TextMessageContentEvent extends AgUiEvent {
  const TextMessageContentEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      required this.delta});
  final String messageId;
  final String delta;
}

final class TextMessageEndEvent extends AgUiEvent {
  const TextMessageEndEvent._(
      {required super.type, super.timestamp, required this.messageId});
  final String messageId;
}

/// Convenience single-event alternative to START + CONTENT + END.
final class TextMessageChunkEvent extends AgUiEvent {
  const TextMessageChunkEvent._(
      {required super.type,
      super.timestamp,
      this.messageId,
      this.role,
      this.delta,
      this.name});
  final String? messageId;
  final String? role;
  final String? delta;
  final String? name;
}

// ── Tool calls — streaming ────────────────────────────────────────────────────

final class ToolCallStartEvent extends AgUiEvent {
  const ToolCallStartEvent._(
      {required super.type,
      super.timestamp,
      required this.toolCallId,
      required this.toolCallName,
      this.parentMessageId});
  final String toolCallId;
  final String toolCallName;
  final String? parentMessageId;
}

/// Args delta — event type is `TOOL_CALL_ARGS` in the spec (legacy: `TOOL_CALL_ARGS_DELTA`).
final class ToolCallArgsDeltaEvent extends AgUiEvent {
  const ToolCallArgsDeltaEvent._(
      {required super.type,
      super.timestamp,
      required this.toolCallId,
      required this.delta});
  final String toolCallId;
  final String delta;
}

final class ToolCallEndEvent extends AgUiEvent {
  const ToolCallEndEvent._(
      {required super.type, super.timestamp, required this.toolCallId});
  final String toolCallId;
}

/// Convenience combined chunk (start + args + end in one event).
final class ToolCallChunkEvent extends AgUiEvent {
  const ToolCallChunkEvent._(
      {required super.type,
      super.timestamp,
      this.toolCallId,
      this.toolCallName,
      this.parentMessageId,
      this.delta});
  final String? toolCallId;
  final String? toolCallName;
  final String? parentMessageId;
  final String? delta;
}

/// Result of a tool call. [content] is always a string (JSON-encoded for complex results).
final class ToolCallResultEvent extends AgUiEvent {
  const ToolCallResultEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      required this.toolCallId,
      required this.content,
      this.role});
  final String messageId;
  final String toolCallId;
  final String content;
  final String? role;
}

// ── Reasoning / chain-of-thought ──────────────────────────────────────────────

final class ReasoningStartEvent extends AgUiEvent {
  const ReasoningStartEvent._({required super.type, super.timestamp, required this.messageId});
  final String messageId;
}

final class ReasoningMessageStartEvent extends AgUiEvent {
  const ReasoningMessageStartEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      this.role = 'reasoning'});
  final String messageId;
  final String role;
}

final class ReasoningMessageContentEvent extends AgUiEvent {
  const ReasoningMessageContentEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      required this.delta});
  final String messageId;
  final String delta;
}

final class ReasoningMessageEndEvent extends AgUiEvent {
  const ReasoningMessageEndEvent._(
      {required super.type, super.timestamp, required this.messageId});
  final String messageId;
}

final class ReasoningEndEvent extends AgUiEvent {
  const ReasoningEndEvent._({required super.type, super.timestamp, required this.messageId});
  final String messageId;
}

/// Convenience combined chunk (alternative to REASONING_MESSAGE_START + CONTENT + END).
final class ReasoningMessageChunkEvent extends AgUiEvent {
  const ReasoningMessageChunkEvent._(
      {required super.type, super.timestamp, this.messageId, this.delta});
  final String? messageId;
  final String? delta;
}

/// Encrypted reasoning value for safety filtering of extended-thinking content.
final class ReasoningEncryptedValueEvent extends AgUiEvent {
  const ReasoningEncryptedValueEvent._(
      {required super.type,
      super.timestamp,
      required this.subtype,
      required this.entityId,
      required this.encryptedValue});

  /// `"tool-call"` or `"message"`.
  final String subtype;
  final String entityId;
  final String encryptedValue;
}

// ── State ─────────────────────────────────────────────────────────────────────

final class StateSnapshotEvent extends AgUiEvent {
  const StateSnapshotEvent._({required super.type, super.timestamp, required this.snapshot});
  final dynamic snapshot;
}

/// [delta] is a list of RFC 6902 JSON Patch operations.
final class StateDeltaEvent extends AgUiEvent {
  const StateDeltaEvent._({required super.type, super.timestamp, required this.delta});
  final List<dynamic> delta;
}

// ── Messages / activity ───────────────────────────────────────────────────────

final class MessagesSnapshotEvent extends AgUiEvent {
  const MessagesSnapshotEvent._(
      {required super.type, super.timestamp, required this.messages});
  final List<Map<String, dynamic>> messages;
}

final class ActivitySnapshotEvent extends AgUiEvent {
  const ActivitySnapshotEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      required this.activityType,
      required this.content,
      required this.replace});
  final String messageId;
  final String activityType;
  final Map<String, dynamic> content;
  final bool replace;
}

final class ActivityDeltaEvent extends AgUiEvent {
  const ActivityDeltaEvent._(
      {required super.type,
      super.timestamp,
      required this.messageId,
      required this.activityType,
      required this.patch});
  final String messageId;
  final String activityType;

  /// RFC 6902 JSON Patch operations applied to the activity content.
  final List<dynamic> patch;
}

// ── Raw / custom / unknown ────────────────────────────────────────────────────

final class RawEvent extends AgUiEvent {
  const RawEvent._(
      {required super.type, super.timestamp, required this.event, this.source});
  final dynamic event;
  final String? source;
}

final class CustomEvent extends AgUiEvent {
  const CustomEvent._(
      {required super.type, super.timestamp, required this.name, this.value});
  final String name;
  final dynamic value;
}

final class UnknownEvent extends AgUiEvent {
  const UnknownEvent._({required super.type, super.timestamp, required this.raw});
  final Map<String, dynamic> raw;
}

// ── Ready-made SSE parser ─────────────────────────────────────────────────────

/// Drop-in parser for `AgUiSseChannel<AgUiEvent>`:
///
/// ```dart
/// AgUiSseChannel<AgUiEvent>(
///   opener: myOpener,
///   path: '/agent/stream',
///   parser: agUiEventParser,
/// )
/// ```
AgUiEvent? agUiEventParser(String event, String? id, String? data) {
  if (data == null || data.isEmpty || data == '[DONE]') return null;
  try {
    final decoded = jsonDecode(data);
    if (decoded is! Map) return null;
    final json = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded);
    if (!json.containsKey('type') && event.isNotEmpty) {
      json['type'] = event;
    }
    return AgUiEvent.fromJson(json);
  } catch (_) {
    return null;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

AgUiRunOutcome? _parseOutcome(dynamic raw) {
  if (raw == null) return null;
  if (raw is! Map) return const AgUiSuccessOutcome();
  final type = raw['type']?.toString();
  if (type == 'interrupt') {
    final rawInterrupts = raw['interrupts'];
    final interrupts = <AgUiInterrupt>[];
    if (rawInterrupts is List) {
      for (final i in rawInterrupts) {
        if (i is Map<String, dynamic>) {
          interrupts.add(AgUiInterrupt.fromJson(i));
        } else if (i is Map) {
          interrupts.add(AgUiInterrupt.fromJson(Map<String, dynamic>.from(i)));
        }
      }
    }
    return AgUiInterruptOutcome(interrupts: interrupts);
  }
  return const AgUiSuccessOutcome();
}

String _str(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) return v;
  if (v != null) return v.toString();
  return '';
}

String? _opt(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}
