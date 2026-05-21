/// Step 2 — Streaming Text
///
/// Feed events into [AgUiGenerativeController] and render live text bubbles
/// with [AgUiGenerativeView]. Watch user and assistant messages appear word
/// by word, with a streaming indicator dot.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step02StreamingText extends StatefulWidget {
  const Step02StreamingText({super.key});

  @override
  State<Step02StreamingText> createState() => _State();
}

class _State extends State<Step02StreamingText> {
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
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() => _running = false);
  }

  Stream<AgUiEvent> _buildEvents() async* {
    // User message
    yield AgUiEvent.fromJson(
        {'type': 'TEXT_MESSAGE_START', 'messageId': 'u1', 'role': 'user'});
    for (final chunk in ['What is ', 'the capital ', 'of France?']) {
      await Future.delayed(const Duration(milliseconds: 120));
      yield AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'u1', 'delta': chunk});
    }
    yield AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'u1'});

    await Future.delayed(const Duration(milliseconds: 400));

    // Assistant reply (markdown rendered when done streaming)
    yield AgUiEvent.fromJson(
        {'type': 'TEXT_MESSAGE_START', 'messageId': 'a1', 'role': 'assistant'});
    const reply =
        'The capital of France is **Paris**. It is located in the north-central '
        'part of the country on the Seine river.';
    for (var i = 0; i < reply.length; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));
      final end = (i + 5).clamp(0, reply.length);
      yield AgUiEvent.fromJson({
        'type': 'TEXT_MESSAGE_CONTENT',
        'messageId': 'a1',
        'delta': reply.substring(i, end),
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
      appBar: AppBar(title: const Text('Step 2 — Streaming Text')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.chat_bubble_outline,
            title: 'AgUiGenerativeController + AgUiGenerativeView',
            body: 'Each TEXT_MESSAGE_START/CONTENT/END triplet builds an '
                'AgUiTextItem. While isStreaming=true the bubble shows a '
                'pulsing dot. Finished assistant messages render Markdown.',
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
                    child: Text('Press Run to start.',
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
