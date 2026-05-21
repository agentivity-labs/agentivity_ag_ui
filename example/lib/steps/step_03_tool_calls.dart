/// Step 3 — Tool Calls
///
/// Watch TOOL_CALL_START / TOOL_CALL_END events become status cards:
/// pending → running → completed. TOOL_CALL_RESULT fills the result text.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step03ToolCalls extends StatefulWidget {
  const Step03ToolCalls({super.key});

  @override
  State<Step03ToolCalls> createState() => _State();
}

class _State extends State<Step03ToolCalls> {
  AgUiGenerativeController? _ctrl;
  bool _running = false;

  Future<void> _run() async {
    _ctrl?.dispose();
    final ctrl = AgUiGenerativeController(
      events: _buildEvents(),
      widgetRegistry: AgUiWidgetRegistry({}),
    );
    setState(() {
      _ctrl = ctrl;
      _running = true;
    });
    ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    await Future.delayed(const Duration(seconds: 7));
    if (mounted) setState(() => _running = false);
  }

  Stream<AgUiEvent> _buildEvents() async* {
    // Intro text
    yield AgUiEvent.fromJson(
        {'type': 'TEXT_MESSAGE_START', 'messageId': 'm1', 'role': 'assistant'});
    for (final c in ["I'll look up ", "the weather ", "and stock price."]) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': c});
    }
    yield AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});

    await Future.delayed(const Duration(milliseconds: 300));

    // Tool call 1 — success with backend result
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_START',
      'toolCallId': 'tc1',
      'toolCallName': 'getWeather',
    });
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_ARGS',
      'toolCallId': 'tc1',
      'delta': '{"city":"Paris"}',
    });
    await Future.delayed(const Duration(milliseconds: 900));
    yield AgUiEvent.fromJson({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'});
    await Future.delayed(const Duration(milliseconds: 200));
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_RESULT',
      'toolCallId': 'tc1',
      'content': '22 °C, partly cloudy',
    });

    await Future.delayed(const Duration(milliseconds: 400));

    // Tool call 2 — result via TOOL_CALL_RESULT
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_START',
      'toolCallId': 'tc2',
      'toolCallName': 'getStockPrice',
    });
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_ARGS',
      'toolCallId': 'tc2',
      'delta': '{"ticker":"ACME"}',
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    yield AgUiEvent.fromJson({'type': 'TOOL_CALL_END', 'toolCallId': 'tc2'});
    await Future.delayed(const Duration(milliseconds: 200));
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_RESULT',
      'toolCallId': 'tc2',
      'content': 'ACME: \$142.80 (+1.3 %)',
    });

    await Future.delayed(const Duration(milliseconds: 400));

    // Summary
    yield AgUiEvent.fromJson(
        {'type': 'TEXT_MESSAGE_START', 'messageId': 'm2', 'role': 'assistant'});
    const summary =
        'Paris is 22 °C and partly cloudy. ACME stock is at \$142.80, up 1.3%.';
    for (var i = 0; i < summary.length; i += 6) {
      await Future.delayed(const Duration(milliseconds: 60));
      final end = (i + 6).clamp(0, summary.length);
      yield AgUiEvent.fromJson({
        'type': 'TEXT_MESSAGE_CONTENT',
        'messageId': 'm2',
        'delta': summary.substring(i, end),
      });
    }
    yield AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 3 — Tool Calls')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.build_circle_outlined,
            title: 'TOOL_CALL_START / END / RESULT',
            body: 'Each tool transitions: pending → running → completed. '
                'A TOOL_CALL_RESULT event injects the backend response. '
                'Register a frontend tool in AgUiFrontendToolRegistry to '
                'execute it locally without a backend round-trip.',
          ),
          StepRunBar(
            running: _running,
            onRun: _run,
            onReset: _ctrl == null
                ? null
                : () {
                    _ctrl!.clear();
                    setState(() => _running = false);
                  },
          ),
          Expanded(
            child: _ctrl == null
                ? Center(
                    child: Text('Press Run to see tool call cards.',
                        style: TextStyle(color: cs.outline)))
                : AgUiGenerativeView(
                    controller: _ctrl!,
                    registry: AgUiWidgetRegistry({}),
                  ),
          ),
        ],
      ),
    );
  }
}
