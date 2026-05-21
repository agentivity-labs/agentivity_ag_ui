import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

// Helpers ─────────────────────────────────────────────────────────────────────

AgUiEvent _e(Map<String, dynamic> json) => AgUiEvent.fromJson(json);

AgUiGenerativeController _ctrl(
  List<AgUiEvent> events, {
  AgUiFrontendToolRegistry? toolRegistry,
  AgUiWidgetRegistry? widgetRegistry,
}) {
  return AgUiGenerativeController(
    events: Stream.fromIterable(events),
    toolRegistry: toolRegistry,
    widgetRegistry: widgetRegistry,
  );
}

// Waits for the event loop to process all pending stream events.
// Stream.fromIterable delivers each event as a microtask; a timer-based
// yield drains the entire microtask queue before resuming.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  // ── Text messages ─────────────────────────────────────────────────────────

  group('text messages', () {
    test('TEXT_MESSAGE_START creates a streaming AgUiTextItem', () async {
      final ctrl = _ctrl([
        _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1', 'role': 'assistant'}),
      ]);
      await _pump();
      expect(ctrl.items, hasLength(1));
      final item = ctrl.items.first as AgUiTextItem;
      expect(item.messageId, 'm1');
      expect(item.role, 'assistant');
      expect(item.text, '');
      expect(item.isStreaming, isTrue);
      ctrl.dispose();
    });

    test('TEXT_MESSAGE_CONTENT appends delta to item', () async {
      final ctrl = _ctrl([
        _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1'}),
        _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'Hello'}),
        _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': ' world'}),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiTextItem;
      expect(item.text, 'Hello world');
      expect(item.isStreaming, isTrue);
      ctrl.dispose();
    });

    test('TEXT_MESSAGE_END finalises item (isStreaming = false)', () async {
      final ctrl = _ctrl([
        _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1'}),
        _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'Hi'}),
        _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'}),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiTextItem;
      expect(item.text, 'Hi');
      expect(item.isStreaming, isFalse);
      ctrl.dispose();
    });

    test('TEXT_MESSAGE_CHUNK auto-creates item on first chunk', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'TEXT_MESSAGE_CHUNK',
          'messageId': 'm1',
          'role': 'user',
          'delta': 'chunk',
        }),
      ]);
      await _pump();
      expect(ctrl.items, hasLength(1));
      final item = ctrl.items.first as AgUiTextItem;
      expect(item.role, 'user');
      expect(item.text, 'chunk');
      ctrl.dispose();
    });

    test('TEXT_MESSAGE_CHUNK appends to existing item', () async {
      final ctrl = _ctrl([
        _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1'}),
        _e({'type': 'TEXT_MESSAGE_CHUNK', 'messageId': 'm1', 'delta': 'A'}),
        _e({'type': 'TEXT_MESSAGE_CHUNK', 'messageId': 'm1', 'delta': 'B'}),
      ]);
      await _pump();
      // Still one item (no duplicate created)
      expect(ctrl.items, hasLength(1));
      final item = ctrl.items.first as AgUiTextItem;
      expect(item.text, 'AB');
      ctrl.dispose();
    });

    test('multiple messages kept in order', () async {
      final ctrl = _ctrl([
        _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'u1', 'role': 'user'}),
        _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'u1', 'delta': 'Hi'}),
        _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'u1'}),
        _e({
          'type': 'TEXT_MESSAGE_START',
          'messageId': 'a1',
          'role': 'assistant'
        }),
        _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'a1', 'delta': 'Hello'}),
        _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'a1'}),
      ]);
      await _pump();
      expect(ctrl.items, hasLength(2));
      expect((ctrl.items[0] as AgUiTextItem).role, 'user');
      expect((ctrl.items[1] as AgUiTextItem).role, 'assistant');
      ctrl.dispose();
    });
  });

  // ── Reasoning ─────────────────────────────────────────────────────────────

  group('reasoning messages', () {
    test('REASONING_MESSAGE_START creates streaming AgUiReasoningItem', () async {
      final ctrl = _ctrl([
        _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'r1'}),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiReasoningItem;
      expect(item.text, '');
      expect(item.isStreaming, isTrue);
      ctrl.dispose();
    });

    test('REASONING_MESSAGE_CONTENT appends delta', () async {
      final ctrl = _ctrl([
        _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'r1'}),
        _e({
          'type': 'REASONING_MESSAGE_CONTENT',
          'messageId': 'r1',
          'delta': 'Think…'
        }),
      ]);
      await _pump();
      expect((ctrl.items.first as AgUiReasoningItem).text, 'Think…');
      ctrl.dispose();
    });

    test('REASONING_MESSAGE_END finalises item', () async {
      final ctrl = _ctrl([
        _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'r1'}),
        _e({'type': 'REASONING_MESSAGE_END', 'messageId': 'r1'}),
      ]);
      await _pump();
      expect((ctrl.items.first as AgUiReasoningItem).isStreaming, isFalse);
      ctrl.dispose();
    });
  });

  // ── Tool calls — backend ──────────────────────────────────────────────────

  group('tool calls (backend)', () {
    test('TOOL_CALL_START creates pending AgUiToolCallItem', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'TOOL_CALL_START',
          'toolCallId': 'tc1',
          'toolCallName': 'search'
        }),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiToolCallItem;
      expect(item.toolCallId, 'tc1');
      expect(item.toolCallName, 'search');
      expect(item.status, AgUiToolCallStatus.pending);
      ctrl.dispose();
    });

    test('TOOL_CALL_END transitions to running (waiting for result)', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'TOOL_CALL_START',
          'toolCallId': 'tc1',
          'toolCallName': 'search'
        }),
        _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiToolCallItem;
      expect(item.status, AgUiToolCallStatus.running);
      ctrl.dispose();
    });

    test('TOOL_CALL_RESULT marks tool completed with content', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'TOOL_CALL_START',
          'toolCallId': 'tc1',
          'toolCallName': 'search'
        }),
        _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
        _e({
          'type': 'TOOL_CALL_RESULT',
          'messageId': 'msg1',
          'toolCallId': 'tc1',
          'content': 'search results here'
        }),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiToolCallItem;
      expect(item.status, AgUiToolCallStatus.completed);
      expect(item.result, 'search results here');
      ctrl.dispose();
    });

    test('args delta is accumulated before end', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'TOOL_CALL_START',
          'toolCallId': 'tc1',
          'toolCallName': 'search'
        }),
        _e({'type': 'TOOL_CALL_ARGS', 'toolCallId': 'tc1', 'delta': '{"q":'}),
        _e({'type': 'TOOL_CALL_ARGS', 'toolCallId': 'tc1', 'delta': '"dart"}'}),
        _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
        _e({
          'type': 'TOOL_CALL_RESULT',
          'messageId': '',
          'toolCallId': 'tc1',
          'content': 'ok'
        }),
      ]);
      await _pump();
      // The test verifies no crash and correct final state
      final item = ctrl.items.first as AgUiToolCallItem;
      expect(item.status, AgUiToolCallStatus.completed);
      ctrl.dispose();
    });
  });

  // ── Tool calls — widget registry ──────────────────────────────────────────

  group('tool calls (widget registry)', () {
    test('tool matching registry replaces placeholder with AgUiComponentItem',
        () async {
      final registry = AgUiWidgetRegistry({
        'WeatherCard': (_) => const SizedBox(),
      });
      final ctrl = _ctrl(
        [
          _e({
            'type': 'TOOL_CALL_START',
            'toolCallId': 'tc1',
            'toolCallName': 'WeatherCard'
          }),
          _e({
            'type': 'TOOL_CALL_ARGS',
            'toolCallId': 'tc1',
            'delta': '{"city":"Paris"}'
          }),
          _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
        ],
        widgetRegistry: registry,
      );
      await _pump();
      expect(ctrl.items, hasLength(1));
      final item = ctrl.items.first as AgUiComponentItem;
      expect(item.component, 'WeatherCard');
      expect(item.props, {'city': 'Paris'});
      ctrl.dispose();
    });

    test('unknown tool name stays as AgUiToolCallItem', () async {
      final registry = AgUiWidgetRegistry({'Known': (_) => const SizedBox()});
      final ctrl = _ctrl(
        [
          _e({
            'type': 'TOOL_CALL_START',
            'toolCallId': 'tc1',
            'toolCallName': 'Unknown'
          }),
          _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
        ],
        widgetRegistry: registry,
      );
      await _pump();
      expect(ctrl.items.first, isA<AgUiToolCallItem>());
      ctrl.dispose();
    });
  });

  // ── Tool calls — frontend tool registry ───────────────────────────────────

  group('tool calls (frontend tool registry)', () {
    test('frontend tool is executed locally and result shown', () async {
      final tool = AgUiFrontendTool(
        name: 'getTime',
        description: 'Returns current time',
        handler: (_) async => '12:00',
      );
      final registry = AgUiFrontendToolRegistry([tool]);

      final ctrl = _ctrl(
        [
          _e({
            'type': 'TOOL_CALL_START',
            'toolCallId': 'tc1',
            'toolCallName': 'getTime'
          }),
          _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
        ],
        toolRegistry: registry,
      );

      // One pump drains stream events + the async handler (no awaits inside it)
      await _pump();
      await _pump(); // second pump in case handler resolves in a separate tick
      final item = ctrl.items.first as AgUiToolCallItem;
      expect(item.status, AgUiToolCallStatus.completed);
      expect(item.result, '12:00');
      ctrl.dispose();
    });

    test('frontend tool failure sets status to failed', () async {
      final tool = AgUiFrontendTool(
        name: 'broken',
        description: 'Always throws',
        handler: (_) async => throw Exception('oops'),
      );
      final registry = AgUiFrontendToolRegistry([tool]);

      final ctrl = _ctrl(
        [
          _e({
            'type': 'TOOL_CALL_START',
            'toolCallId': 'tc1',
            'toolCallName': 'broken'
          }),
          _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'}),
        ],
        toolRegistry: registry,
      );

      await _pump();
      await _pump();
      final item = ctrl.items.first as AgUiToolCallItem;
      expect(item.status, AgUiToolCallStatus.failed);
      expect(item.error, isNotNull);
      ctrl.dispose();
    });
  });

  // ── CUSTOM render events ──────────────────────────────────────────────────

  group('CUSTOM render event', () {
    test('CUSTOM name=render adds AgUiComponentItem', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'CUSTOM',
          'name': 'render',
          'value': {'component': 'StockChart', 'props': {'symbol': 'AAPL'}}
        }),
      ]);
      await _pump();
      expect(ctrl.items, hasLength(1));
      final item = ctrl.items.first as AgUiComponentItem;
      expect(item.component, 'StockChart');
      expect(item.props, {'symbol': 'AAPL'});
      ctrl.dispose();
    });

    test('CUSTOM name=ag-ui:render also adds AgUiComponentItem', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'CUSTOM',
          'name': 'ag-ui:render',
          'value': {'component': 'Card', 'props': {}}
        }),
      ]);
      await _pump();
      expect(ctrl.items.first, isA<AgUiComponentItem>());
      ctrl.dispose();
    });

    test('CUSTOM with empty component name is ignored', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'CUSTOM',
          'name': 'render',
          'value': {'component': '', 'props': {}}
        }),
      ]);
      await _pump();
      expect(ctrl.items, isEmpty);
      ctrl.dispose();
    });

    test('CUSTOM with missing props defaults to empty map', () async {
      final ctrl = _ctrl([
        _e({
          'type': 'CUSTOM',
          'name': 'render',
          'value': {'component': 'Card'}
        }),
      ]);
      await _pump();
      final item = ctrl.items.first as AgUiComponentItem;
      expect(item.props, isEmpty);
      ctrl.dispose();
    });
  });

  // ── clear() ───────────────────────────────────────────────────────────────

  group('clear()', () {
    test('removes all items and notifies', () async {
      final ctrl = _ctrl([
        _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1'}),
        _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'hi'}),
        _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'}),
      ]);
      await _pump();
      expect(ctrl.items, isNotEmpty);

      var notified = 0;
      ctrl.addListener(() => notified++);
      ctrl.clear();
      expect(ctrl.items, isEmpty);
      expect(notified, 1);
      ctrl.dispose();
    });
  });

  // ── listener notifications ────────────────────────────────────────────────

  group('listener notifications', () {
    test('notifies on each text event', () async {
      var count = 0;
      final stream = StreamController<AgUiEvent>();
      final ctrl = AgUiGenerativeController(events: stream.stream);
      ctrl.addListener(() => count++);

      stream.add(_e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1'}));
      await _pump();
      final afterStart = count;

      stream.add(
          _e({'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'x'}));
      await _pump();
      final afterContent = count;

      stream.add(_e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'}));
      await _pump();

      expect(afterStart, greaterThan(0));
      expect(afterContent, greaterThan(afterStart));
      expect(count, greaterThan(afterContent));

      await stream.close();
      ctrl.dispose();
    });
  });
}
