/// Step 5 — Reasoning Blocks
///
/// REASONING_MESSAGE_START/CONTENT/END events produce a collapsible
/// "Thinking…" block with a streaming indicator. Tap to expand/collapse.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step05Reasoning extends StatefulWidget {
  const Step05Reasoning({super.key});

  @override
  State<Step05Reasoning> createState() => _State();
}

class _State extends State<Step05Reasoning> {
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
    // Reasoning block — streams in while thinking
    yield AgUiEvent.fromJson(
        {'type': 'REASONING_MESSAGE_START', 'messageId': 'r1'});

    const thought =
        'The user is asking about photosynthesis. '
        'I should explain the light-dependent and light-independent reactions. '
        'Calvin cycle is key. I will keep it brief and clear.';

    for (var i = 0; i < thought.length; i += 7) {
      await Future.delayed(const Duration(milliseconds: 70));
      final end = (i + 7).clamp(0, thought.length);
      yield AgUiEvent.fromJson({
        'type': 'REASONING_MESSAGE_CONTENT',
        'messageId': 'r1',
        'delta': thought.substring(i, end),
      });
    }

    await Future.delayed(const Duration(milliseconds: 200));
    yield AgUiEvent.fromJson(
        {'type': 'REASONING_MESSAGE_END', 'messageId': 'r1'});

    await Future.delayed(const Duration(milliseconds: 300));

    // Follow-up answer (markdown rendered when done)
    yield AgUiEvent.fromJson({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'a1',
      'role': 'assistant',
    });

    const answer =
        'Photosynthesis converts light energy into chemical energy stored in '
        'glucose. It happens in two stages:\n\n'
        '1. **Light-dependent reactions** — in the thylakoid membrane, '
        'capturing sunlight to produce ATP and NADPH.\n'
        '2. **Calvin cycle** — in the stroma, using ATP and NADPH to fix CO₂ '
        'into sugar.';

    for (var i = 0; i < answer.length; i += 6) {
      await Future.delayed(const Duration(milliseconds: 55));
      final end = (i + 6).clamp(0, answer.length);
      yield AgUiEvent.fromJson({
        'type': 'TEXT_MESSAGE_CONTENT',
        'messageId': 'a1',
        'delta': answer.substring(i, end),
      });
    }
    yield AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'a1'});
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
      appBar: AppBar(title: const Text('Step 5 — Reasoning Blocks')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.psychology_outlined,
            title: 'REASONING_MESSAGE_START / CONTENT / END',
            body: 'Creates an AgUiReasoningItem. The view renders it as a '
                'collapsible "Thinking…" chip with a live pulsing dot while '
                'isStreaming=true. Tap the chip to expand / collapse the '
                'full chain-of-thought text.',
          ),
          StepRunBar(
            running: _running,
            runningLabel: 'Thinking…',
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
                    child: Text('Press Run to see the reasoning block.',
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
