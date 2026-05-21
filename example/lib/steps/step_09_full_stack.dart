/// Step 9 — Full Stack
///
/// Everything at once: lifecycle tracking, activity indicator, state sync,
/// generative UI, reasoning block, tool calls.
/// This is the starting template for a real production integration.
library;

import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step09FullStack extends StatefulWidget {
  const Step09FullStack({super.key});

  @override
  State<Step09FullStack> createState() => _State();
}

class _State extends State<Step09FullStack> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  AgUiRunLifecycleController? _lifecycle;
  AgUiActivityController? _activity;
  AgUiStateController? _stateCtrl;
  AgUiGenerativeController? _genCtrl;

  bool _running = false;

  final _registry = AgUiWidgetRegistry({
    'ProductCard': (props) => _ProductCard(
          name: jsonStr(props, 'name'),
          price: jsonStr(props, 'price'),
          emoji: jsonStr(props, 'emoji'),
        ),
  });

  Future<void> _run() async {
    _disposeAll();
    // One broadcast stream feeds all four controllers simultaneously.
    final broadcast = _buildEventStream().asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: broadcast);
    final activity = AgUiActivityController(events: broadcast);
    final stateCtrl = AgUiStateController(events: broadcast);
    final genCtrl = AgUiGenerativeController(
        events: broadcast, widgetRegistry: _registry);

    lifecycle.addListener(_onLifecycle);
    for (final ln in [activity, stateCtrl, genCtrl]) {
      ln.addListener(() {
        if (mounted) setState(() {});
      });
    }

    setState(() {
      _lifecycle = lifecycle;
      _activity = activity;
      _stateCtrl = stateCtrl;
      _genCtrl = genCtrl;
      _running = true;
    });
  }

  void _onLifecycle() {
    if (!mounted) return;
    final lc = _lifecycle;
    if (lc != null && (lc.isFinished || lc.hasError)) {
      setState(() => _running = false);
    } else {
      setState(() {});
    }
  }

  void _disposeAll() {
    _lifecycle?.dispose();
    _activity?.dispose();
    _stateCtrl?.dispose();
    _genCtrl?.dispose();
    _lifecycle = null;
    _activity = null;
    _stateCtrl = null;
    _genCtrl = null;
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  Stream<AgUiEvent> _buildEventStream() async* {
    yield _e({'type': 'RUN_STARTED', 'threadId': 'th1', 'runId': 'r1'});

    yield _e({
      'type': 'STATE_SNAPSHOT',
      'snapshot': {'cart': <dynamic>[], 'totalItems': 0, 'step': 'search'},
    });

    await _delay(200);
    yield _e({
      'type': 'ACTIVITY_SNAPSHOT',
      'activities': [
        {
          'messageId': 'act1',
          'activityType': 'search',
          'content': {'label': 'Searching product catalog…', 'progress': 0.2},
        },
      ],
    });

    // Reasoning
    await _delay(200);
    yield _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'r1'});
    const thought =
        'The user wants wireless headphones under €100. '
        'I see three strong candidates in the catalog.';
    for (var i = 0; i < thought.length; i += 8) {
      await _delay(60);
      final end = (i + 8).clamp(0, thought.length);
      yield _e({
        'type': 'REASONING_MESSAGE_CONTENT',
        'messageId': 'r1',
        'delta': thought.substring(i, end),
      });
    }
    await _delay(200);
    yield _e({'type': 'REASONING_MESSAGE_END', 'messageId': 'r1'});

    // Step + tool call
    await _delay(100);
    yield _e({'type': 'STEP_STARTED', 'stepName': 'search_catalog'});

    await _delay(200);
    yield _e({
      'type': 'TOOL_CALL_START',
      'toolCallId': 'tc1',
      'toolCallName': 'searchProducts',
    });
    yield _e({
      'type': 'TOOL_CALL_ARGS',
      'toolCallId': 'tc1',
      'delta': '{"query":"wireless headphones","maxPrice":100}',
    });
    await _delay(800);
    yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'});
    await _delay(150);
    yield _e({
      'type': 'TOOL_CALL_RESULT',
      'toolCallId': 'tc1',
      'content': '3 products found',
    });
    yield _e({'type': 'STEP_FINISHED', 'stepName': 'search_catalog'});

    // Activity update
    await _delay(200);
    yield _e({
      'type': 'ACTIVITY_DELTA',
      'messageId': 'act1',
      'delta': [
        {'op': 'replace', 'path': '/content/progress', 'value': 0.9},
        {
          'op': 'replace',
          'path': '/content/label',
          'value': 'Preparing recommendations…',
        },
      ],
    });

    // State update
    await _delay(200);
    yield _e({
      'type': 'STATE_DELTA',
      'delta': [
        {'op': 'replace', 'path': '/step', 'value': 'recommend'},
      ],
    });

    // Intro text
    yield _e({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'm1',
      'role': 'assistant',
    });
    const intro = 'I found **3 great options** for wireless headphones under €100:';
    for (var i = 0; i < intro.length; i += 5) {
      await _delay(50);
      final end = (i + 5).clamp(0, intro.length);
      yield _e({
        'type': 'TEXT_MESSAGE_CONTENT',
        'messageId': 'm1',
        'delta': intro.substring(i, end),
      });
    }
    yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});

    // Generative product cards via CUSTOM render
    for (final product in [
      {'name': 'SoundWave Pro', 'price': '€79.99', 'emoji': '🎧'},
      {'name': 'BassMax Elite', 'price': '€89.99', 'emoji': '🎵'},
      {'name': 'ClearTune 50', 'price': '€59.99', 'emoji': '🎶'},
    ]) {
      await _delay(250);
      yield _e({
        'type': 'CUSTOM',
        'name': 'ag-ui:render',
        'value': {'component': 'ProductCard', 'props': product},
      });
    }

    // Closing
    await _delay(300);
    yield _e({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'm2',
      'role': 'assistant',
    });
    const close = 'All three are highly rated. Which one would you like?';
    for (var i = 0; i < close.length; i += 5) {
      await _delay(60);
      final end = (i + 5).clamp(0, close.length);
      yield _e({
        'type': 'TEXT_MESSAGE_CONTENT',
        'messageId': 'm2',
        'delta': close.substring(i, end),
      });
    }
    yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});

    await _delay(300);
    yield _e({'type': 'RUN_FINISHED', 'threadId': 'th1', 'runId': 'r1'});
  }

  AgUiEvent _e(Map<String, dynamic> json) => AgUiEvent.fromJson(json);
  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lc = _lifecycle;
    final activity = _activity;
    final state = _stateCtrl?.state ?? {};
    final genCtrl = _genCtrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 9 — Full Stack')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.layers_outlined,
            title: 'All controllers from a single broadcast stream',
            body: 'One Stream<AgUiEvent>.asBroadcastStream() feeds '
                'AgUiRunLifecycleController, AgUiActivityController, '
                'AgUiStateController, and AgUiGenerativeController '
                'simultaneously — each handles its own event subset.',
          ),

          // Controls + status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_running ? 'Running…' : 'Run demo'),
                ),
                const SizedBox(width: 8),
                if (genCtrl != null)
                  TextButton.icon(
                    onPressed: _running
                        ? null
                        : () {
                            _disposeAll();
                            setState(() {});
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                const Spacer(),
                if (lc != null)
                  _StateChip(
                    label: lc.isRunning
                        ? 'RUNNING'
                        : lc.isFinished
                            ? 'DONE'
                            : 'IDLE',
                    color: lc.isRunning
                        ? cs.primary
                        : lc.isFinished
                            ? Colors.green.shade700
                            : cs.outline,
                  ),
              ],
            ),
          ),

          // Activity bar
          if (activity != null)
            ListenableBuilder(
              listenable: activity,
              builder: (context, _) {
                final act = activity.current;
                if (act == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: act.progress,
                          color: cs.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(act.label,
                              style: Theme.of(context).textTheme.labelSmall)),
                    ],
                  ),
                );
              },
            ),

          // State chips
          if (state.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Wrap(
                spacing: 6,
                children: state.entries
                    .where((e) => e.key != 'cart')
                    .map((e) => Chip(
                          label: Text('${e.key}: ${e.value}',
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),

          // Generative view
          Expanded(
            child: genCtrl == null
                ? Center(
                    child: Text('Press Run demo to start.',
                        style: TextStyle(color: cs.outline)))
                : AgUiGenerativeView(
                    controller: genCtrl,
                    registry: _registry,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.price,
    required this.emoji,
  });

  final String name;
  final String price;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(price,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
