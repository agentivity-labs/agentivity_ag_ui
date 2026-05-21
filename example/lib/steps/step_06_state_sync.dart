/// Step 6 — State Sync
///
/// AgUiStateController applies RFC 6902 JSON Patch operations from
/// STATE_SNAPSHOT and STATE_DELTA events. Watch keys change in real time.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step06StateSync extends StatefulWidget {
  const Step06StateSync({super.key});

  @override
  State<Step06StateSync> createState() => _State();
}

class _State extends State<Step06StateSync> {
  AgUiStateController? _stateCtrl;
  bool _running = false;

  Future<void> _run() async {
    _stateCtrl?.dispose();
    final ctrl = AgUiStateController(events: _buildEvents());
    ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() {
      _stateCtrl = ctrl;
      _running = true;
    });
    await Future.delayed(const Duration(seconds: 6));
    if (mounted) setState(() => _running = false);
  }

  Stream<AgUiEvent> _buildEvents() async* {
    // Full snapshot — replaces entire state
    yield AgUiEvent.fromJson({
      'type': 'STATE_SNAPSHOT',
      'snapshot': {
        'user': 'Alice',
        'plan': 'free',
        'credits': 100,
        'session': 'abc-123',
      },
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // Patch: replace credits
    yield AgUiEvent.fromJson({
      'type': 'STATE_DELTA',
      'delta': [
        {'op': 'replace', 'path': '/credits', 'value': 75},
      ],
    });

    await Future.delayed(const Duration(milliseconds: 700));

    // Patch: upgrade plan + add key
    yield AgUiEvent.fromJson({
      'type': 'STATE_DELTA',
      'delta': [
        {'op': 'replace', 'path': '/plan', 'value': 'pro'},
        {'op': 'add', 'path': '/upgradeAt', 'value': '2025-06-01'},
      ],
    });

    await Future.delayed(const Duration(milliseconds: 700));

    // Patch: spend more credits + add another key
    yield AgUiEvent.fromJson({
      'type': 'STATE_DELTA',
      'delta': [
        {'op': 'replace', 'path': '/credits', 'value': 50},
        {'op': 'add', 'path': '/lastAction', 'value': 'generate_report'},
      ],
    });

    await Future.delayed(const Duration(milliseconds: 700));

    // Patch: remove a key
    yield AgUiEvent.fromJson({
      'type': 'STATE_DELTA',
      'delta': [
        {'op': 'remove', 'path': '/session'},
      ],
    });
  }

  @override
  void dispose() {
    _stateCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _stateCtrl?.state ?? {};
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 6 — State Sync')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.sync_alt,
            title: 'AgUiStateController — JSON Patch',
            body: 'STATE_SNAPSHOT replaces the entire state map. '
                'STATE_DELTA applies RFC 6902 JSON Patch operations '
                '(add / replace / remove / move / copy / test) incrementally. '
                'Both trigger a ChangeNotifier notification.',
          ),
          StepRunBar(
            running: _running,
            runningLabel: 'Syncing…',
            onRun: _run,
            onReset: _stateCtrl == null
                ? null
                : () {
                    _stateCtrl!.dispose();
                    setState(() {
                      _stateCtrl = null;
                      _running = false;
                    });
                  },
          ),
          Expanded(
            child: state.isEmpty
                ? Center(
                    child: Text('Press Run to start state sync.',
                        style: TextStyle(color: cs.outline)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Live State',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ...state.entries.map((e) => _StateRow(
                                    key: ValueKey(e.key),
                                    label: e.key,
                                    value: e.value.toString(),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StateRow extends StatefulWidget {
  const _StateRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  State<_StateRow> createState() => _StateRowState();
}

class _StateRowState extends State<_StateRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Color?> _bg;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    final cs = Theme.of(context).colorScheme;
    _bg = ColorTween(
      begin: cs.primaryContainer,
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void didUpdateWidget(_StateRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        color: _bg.value,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(widget.label,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: cs.outline,
                      fontSize: 13)),
            ),
            Expanded(
              flex: 3,
              child: Text(widget.value,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
