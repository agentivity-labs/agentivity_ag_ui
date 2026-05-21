/// Step 1 — SSE Connection
///
/// Shows how to open an event stream and display raw events as they arrive.
/// In production you connect [AgUiSseChannel] to your backend; here we use a
/// local async generator so the example works fully offline.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step01SseConnection extends StatefulWidget {
  const Step01SseConnection({super.key});

  @override
  State<Step01SseConnection> createState() => _State();
}

class _State extends State<Step01SseConnection> {
  bool _connected = false;
  final List<String> _rawEvents = [];

  void _connect() {
    setState(() {
      _connected = true;
      _rawEvents.clear();
    });
    _fakeEventStream().listen(
      (event) {
        if (!mounted) return;
        setState(() => _rawEvents.add(_eventLabel(event)));
      },
      onDone: () {
        if (mounted) setState(() => _connected = false);
      },
    );
  }

  Stream<AgUiEvent> _fakeEventStream() async* {
    final events = [
      {'type': 'RUN_STARTED', 'threadId': 'th1', 'runId': 'r1'},
      {'type': 'STEP_STARTED', 'stepName': 'think'},
      {'type': 'TEXT_MESSAGE_START', 'messageId': 'm1', 'role': 'assistant'},
      {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'Hello '},
      {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': 'world!'},
      {'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'},
      {'type': 'STEP_FINISHED', 'stepName': 'think'},
      {'type': 'RUN_FINISHED', 'threadId': 'th1', 'runId': 'r1'},
    ];

    for (final raw in events) {
      await Future.delayed(const Duration(milliseconds: 350));
      yield AgUiEvent.fromJson(raw);
    }
  }

  String _eventLabel(AgUiEvent event) {
    return switch (event) {
      RunStartedEvent e => 'RUN_STARTED  runId=${e.runId}',
      RunFinishedEvent e => 'RUN_FINISHED  runId=${e.runId}',
      StepStartedEvent e => 'STEP_STARTED  step=${e.stepName}',
      StepFinishedEvent e => 'STEP_FINISHED  step=${e.stepName}',
      TextMessageStartEvent e => 'TEXT_MESSAGE_START  id=${e.messageId}',
      TextMessageContentEvent e => 'TEXT_MESSAGE_CONTENT  delta="${e.delta}"',
      TextMessageEndEvent e => 'TEXT_MESSAGE_END  id=${e.messageId}',
      _ => event.runtimeType.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 1 — SSE Connection')),
      body: Column(
        children: [
          StepInfoCard(
            icon: Icons.stream,
            title: 'SSE Connection pattern',
            body: 'In production: create AgUiSseChannel with your opener '
                'function (Dio + ResponseType.stream). Here we simulate an '
                'identical Stream<AgUiEvent> locally, then listen and display '
                'each event as it arrives.',
          ),
          StepRunBar(
            running: _connected,
            onRun: _connect,
            runLabel: 'Connect',
            runningLabel: 'Streaming…',
          ),
          Expanded(
            child: _rawEvents.isEmpty
                ? Center(
                    child: Text('Press Connect to start.',
                        style: TextStyle(color: cs.outline)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _rawEvents.length,
                    itemBuilder: (context, i) {
                      final label = _rawEvents[i];
                      final isStart = label.startsWith('RUN_STARTED');
                      final isEnd = label.startsWith('RUN_FINISHED');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              isStart
                                  ? Icons.play_circle_outline
                                  : isEnd
                                      ? Icons.stop_circle_outlined
                                      : Icons.arrow_right,
                              size: 18,
                              color: isStart
                                  ? Colors.green
                                  : isEnd
                                      ? cs.primary
                                      : cs.outline,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: isStart || isEnd
                                      ? cs.primary
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
