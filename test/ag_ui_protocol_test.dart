import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgUiEvent.fromJson', () {
    // ── Run lifecycle ───────────────────────────────────────────────────────
    test('RUN_STARTED with threadId', () {
      final e = AgUiEvent.fromJson({
        'type': 'RUN_STARTED',
        'runId': 'r1',
        'threadId': 't1',
        'timestamp': 1000,
      });
      expect(e, isA<RunStartedEvent>());
      final ev = e as RunStartedEvent;
      expect(ev.runId, 'r1');
      expect(ev.threadId, 't1');
      expect(ev.timestamp, 1000);
    });

    test('RUN_STARTED without threadId', () {
      final e = AgUiEvent.fromJson({'type': 'RUN_STARTED', 'runId': 'r1'});
      expect((e as RunStartedEvent).threadId, isNull);
    });

    test('RUN_FINISHED success outcome', () {
      final e = AgUiEvent.fromJson({
        'type': 'RUN_FINISHED',
        'runId': 'r1',
        'threadId': 't1',
        'outcome': {'type': 'success'},
      });
      final ev = e as RunFinishedEvent;
      expect(ev.runId, 'r1');
      expect(ev.outcome, isA<AgUiSuccessOutcome>());
      expect(ev.isInterrupted, isFalse);
    });

    test('RUN_FINISHED interrupt outcome', () {
      final e = AgUiEvent.fromJson({
        'type': 'RUN_FINISHED',
        'runId': 'r1',
        'outcome': {
          'type': 'interrupt',
          'interrupts': [
            {'id': 'i1', 'reason': 'approval needed', 'message': 'Please approve'},
          ],
        },
      });
      final ev = e as RunFinishedEvent;
      expect(ev.isInterrupted, isTrue);
      final outcome = ev.outcome as AgUiInterruptOutcome;
      expect(outcome.interrupts, hasLength(1));
      expect(outcome.interrupts.first.id, 'i1');
      expect(outcome.interrupts.first.reason, 'approval needed');
      expect(outcome.interrupts.first.message, 'Please approve');
    });

    test('RUN_FINISHED without outcome (legacy)', () {
      final e = AgUiEvent.fromJson({'type': 'RUN_FINISHED', 'runId': 'r1'});
      expect((e as RunFinishedEvent).outcome, isNull);
      expect((e).isInterrupted, isFalse);
    });

    test('RUN_ERROR has message and code', () {
      final e = AgUiEvent.fromJson({
        'type': 'RUN_ERROR',
        'message': 'something went wrong',
        'code': 'E42',
      });
      expect(e, isA<RunErrorEvent>());
      final ev = e as RunErrorEvent;
      expect(ev.message, 'something went wrong');
      expect(ev.code, 'E42');
    });

    test('RUN_ERROR without optional code', () {
      final e = AgUiEvent.fromJson({'type': 'RUN_ERROR', 'message': 'oops'});
      expect((e as RunErrorEvent).code, isNull);
    });

    // ── Steps ───────────────────────────────────────────────────────────────
    test('STEP_STARTED', () {
      final e = AgUiEvent.fromJson({'type': 'STEP_STARTED', 'stepName': 'fetch'});
      expect(e, isA<StepStartedEvent>());
      expect((e as StepStartedEvent).stepName, 'fetch');
    });

    test('STEP_FINISHED', () {
      final e = AgUiEvent.fromJson({'type': 'STEP_FINISHED', 'stepName': 'fetch'});
      expect(e, isA<StepFinishedEvent>());
    });

    // ── Text messages ────────────────────────────────────────────────────────
    test('TEXT_MESSAGE_START defaults role to assistant', () {
      final e = AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1'});
      expect((e as TextMessageStartEvent).role, 'assistant');
    });

    test('TEXT_MESSAGE_START with explicit role', () {
      final e = AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_START', 'messageId': 'm1', 'role': 'user'});
      expect((e as TextMessageStartEvent).role, 'user');
    });

    test('TEXT_MESSAGE_CONTENT', () {
      final e = AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'Hello'});
      expect((e as TextMessageContentEvent).delta, 'Hello');
    });

    test('TEXT_MESSAGE_END', () {
      final e = AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});
      expect((e as TextMessageEndEvent).messageId, 'm1');
    });

    test('TEXT_MESSAGE_CHUNK', () {
      final e = AgUiEvent.fromJson({
        'type': 'TEXT_MESSAGE_CHUNK',
        'messageId': 'm1',
        'role': 'assistant',
        'delta': 'Hi',
      });
      expect(e, isA<TextMessageChunkEvent>());
      final ev = e as TextMessageChunkEvent;
      expect(ev.messageId, 'm1');
      expect(ev.delta, 'Hi');
    });

    // ── Tool calls ────────────────────────────────────────────────────────────
    test('TOOL_CALL_START uses toolCallName (spec field)', () {
      final e = AgUiEvent.fromJson({
        'type': 'TOOL_CALL_START',
        'toolCallId': 'tc1',
        'toolCallName': 'search',
        'parentMessageId': 'm1',
      });
      expect(e, isA<ToolCallStartEvent>());
      final ev = e as ToolCallStartEvent;
      expect(ev.toolCallName, 'search');
      expect(ev.parentMessageId, 'm1');
    });

    test('TOOL_CALL_START falls back to legacy toolName field', () {
      final e = AgUiEvent.fromJson({
        'type': 'TOOL_CALL_START',
        'toolCallId': 'tc1',
        'toolName': 'search_legacy',
      });
      expect((e as ToolCallStartEvent).toolCallName, 'search_legacy');
    });

    test('TOOL_CALL_ARGS (spec event name)', () {
      final e = AgUiEvent.fromJson(
          {'type': 'TOOL_CALL_ARGS', 'toolCallId': 'tc1', 'delta': '{"q":'});
      expect(e, isA<ToolCallArgsDeltaEvent>());
      expect((e as ToolCallArgsDeltaEvent).delta, '{"q":');
    });

    test('TOOL_CALL_ARGS_DELTA (legacy event name still works)', () {
      final e = AgUiEvent.fromJson(
          {'type': 'TOOL_CALL_ARGS_DELTA', 'toolCallId': 'tc1', 'delta': 'x'});
      expect(e, isA<ToolCallArgsDeltaEvent>());
    });

    test('TOOL_CALL_END', () {
      final e = AgUiEvent.fromJson({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'});
      expect(e, isA<ToolCallEndEvent>());
    });

    test('TOOL_CALL_CHUNK', () {
      final e = AgUiEvent.fromJson({
        'type': 'TOOL_CALL_CHUNK',
        'toolCallId': 'tc1',
        'toolCallName': 'search',
        'delta': '{"q":',
      });
      expect(e, isA<ToolCallChunkEvent>());
      expect((e as ToolCallChunkEvent).toolCallName, 'search');
    });

    test('TOOL_CALL_RESULT has content (spec field)', () {
      final e = AgUiEvent.fromJson({
        'type': 'TOOL_CALL_RESULT',
        'messageId': 'msg1',
        'toolCallId': 'tc1',
        'content': 'search result text',
      });
      expect(e, isA<ToolCallResultEvent>());
      final ev = e as ToolCallResultEvent;
      expect(ev.messageId, 'msg1');
      expect(ev.content, 'search result text');
    });

    test('TOOL_CALL_RESULT falls back to legacy result field', () {
      final e = AgUiEvent.fromJson({
        'type': 'TOOL_CALL_RESULT',
        'messageId': '',
        'toolCallId': 'tc1',
        'result': 'legacy value',
      });
      expect((e as ToolCallResultEvent).content, 'legacy value');
    });

    // ── Reasoning ─────────────────────────────────────────────────────────────
    test('REASONING_MESSAGE_START', () {
      final e = AgUiEvent.fromJson(
          {'type': 'REASONING_MESSAGE_START', 'messageId': 'r1'});
      expect(e, isA<ReasoningMessageStartEvent>());
    });

    test('REASONING_MESSAGE_CONTENT', () {
      final e = AgUiEvent.fromJson({
        'type': 'REASONING_MESSAGE_CONTENT',
        'messageId': 'r1',
        'delta': 'Let me think…',
      });
      expect(e, isA<ReasoningMessageContentEvent>());
      expect((e as ReasoningMessageContentEvent).delta, 'Let me think…');
    });

    test('REASONING_MESSAGE_END', () {
      final e = AgUiEvent.fromJson({'type': 'REASONING_MESSAGE_END', 'messageId': 'r1'});
      expect(e, isA<ReasoningMessageEndEvent>());
    });

    // ── State ─────────────────────────────────────────────────────────────────
    test('STATE_SNAPSHOT', () {
      final e = AgUiEvent.fromJson({'type': 'STATE_SNAPSHOT', 'snapshot': {'key': 'value'}});
      expect(e, isA<StateSnapshotEvent>());
      expect((e as StateSnapshotEvent).snapshot, {'key': 'value'});
    });

    test('STATE_DELTA', () {
      final e = AgUiEvent.fromJson({
        'type': 'STATE_DELTA',
        'delta': [
          {'op': 'add', 'path': '/x', 'value': 1}
        ],
      });
      expect(e, isA<StateDeltaEvent>());
      expect((e as StateDeltaEvent).delta, hasLength(1));
    });

    test('STATE_DELTA with missing delta defaults to empty list', () {
      final e = AgUiEvent.fromJson({'type': 'STATE_DELTA'});
      expect((e as StateDeltaEvent).delta, isEmpty);
    });

    // ── Other ─────────────────────────────────────────────────────────────────
    test('MESSAGES_SNAPSHOT', () {
      final e = AgUiEvent.fromJson({
        'type': 'MESSAGES_SNAPSHOT',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
      });
      expect((e as MessagesSnapshotEvent).messages, hasLength(1));
    });

    test('ACTIVITY_SNAPSHOT', () {
      final e = AgUiEvent.fromJson({
        'type': 'ACTIVITY_SNAPSHOT',
        'messageId': 'm1',
        'activityType': 'code',
        'content': {'lang': 'dart'},
      });
      expect(e, isA<ActivitySnapshotEvent>());
      final ev = e as ActivitySnapshotEvent;
      expect(ev.activityType, 'code');
      expect(ev.replace, isTrue);
    });

    test('RAW', () {
      final e = AgUiEvent.fromJson({
        'type': 'RAW',
        'event': {'foo': 'bar'},
        'source': 'backend',
      });
      expect(e, isA<RawEvent>());
      expect((e as RawEvent).source, 'backend');
    });

    test('CUSTOM', () {
      final e = AgUiEvent.fromJson({'type': 'CUSTOM', 'name': 'my_event', 'value': 42});
      expect(e, isA<CustomEvent>());
      expect((e as CustomEvent).name, 'my_event');
    });

    test('unknown type produces UnknownEvent', () {
      final e = AgUiEvent.fromJson({'type': 'WHATEVER', 'foo': 'bar'});
      expect(e, isA<UnknownEvent>());
      expect((e as UnknownEvent).raw, containsPair('foo', 'bar'));
    });

    test('timestamp parsed from string', () {
      final e = AgUiEvent.fromJson({'type': 'UNKNOWN_X', 'timestamp': '12345'});
      expect(e.timestamp, 12345);
    });
  });

  // ── agUiEventParser ──────────────────────────────────────────────────────────
  group('agUiEventParser', () {
    test('parses valid JSON with type field', () {
      final e = agUiEventParser('', null, '{"type":"RUN_STARTED","runId":"r1"}');
      expect(e, isA<RunStartedEvent>());
    });

    test('uses SSE event name as type when type field absent', () {
      final e = agUiEventParser('RUN_FINISHED', null, '{"runId":"r2"}');
      expect(e, isA<RunFinishedEvent>());
    });

    test('[DONE] returns null', () {
      expect(agUiEventParser('', null, '[DONE]'), isNull);
    });

    test('empty data returns null', () {
      expect(agUiEventParser('', null, ''), isNull);
    });

    test('null data returns null', () {
      expect(agUiEventParser('', null, null), isNull);
    });

    test('invalid JSON does not throw', () {
      expect(() => agUiEventParser('', null, 'not json'), returnsNormally);
      expect(agUiEventParser('', null, 'not json'), isNull);
    });

    test('non-object JSON returns null', () {
      expect(agUiEventParser('', null, '[1,2,3]'), isNull);
    });
  });

  // ── AgUiInterrupt ────────────────────────────────────────────────────────────
  group('AgUiInterrupt.fromJson', () {
    test('parses all fields', () {
      final i = AgUiInterrupt.fromJson({
        'id': 'i1',
        'reason': 'approval',
        'message': 'Please approve',
        'toolCallId': 'tc1',
        'expiresAt': '2024-01-01T00:05:00Z',
        'responseSchema': {'type': 'object'},
        'metadata': {'key': 'value'},
      });
      expect(i.id, 'i1');
      expect(i.reason, 'approval');
      expect(i.toolCallId, 'tc1');
      expect(i.responseSchema, {'type': 'object'});
    });

    test('optional fields are null when absent', () {
      final i = AgUiInterrupt.fromJson({'id': 'i1', 'reason': 'reason'});
      expect(i.message, isNull);
      expect(i.toolCallId, isNull);
    });
  });
}
