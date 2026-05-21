/// Step 8 — Interrupts & Resume
///
/// AgUiRunLifecycleController detects when a run finishes with an interrupt
/// outcome. The UI shows a prompt, and on approval builds a ResumePayload
/// to restart the run.
library;

import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step08InterruptsResume extends StatefulWidget {
  const Step08InterruptsResume({super.key});

  @override
  State<Step08InterruptsResume> createState() => _State();
}

class _State extends State<Step08InterruptsResume> {
  AgUiRunLifecycleController? _lifecycle;
  AgUiGenerativeController? _genCtrl;
  String _phase = 'idle'; // idle | running | interrupted | resumed | done

  Future<void> _start() async {
    _cleanup();
    final eventsCtrl = _PhaseStreamController();
    final gen = AgUiGenerativeController(
      events: eventsCtrl.stream,
      widgetRegistry: AgUiWidgetRegistry({}),
    );
    final lc = AgUiRunLifecycleController(events: eventsCtrl.lifecycleStream);
    lc.addListener(() => _onLifecycle(lc));
    gen.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() {
      _lifecycle = lc;
      _genCtrl = gen;
      _phase = 'running';
    });
    eventsCtrl.emitPhase1();
  }

  void _onLifecycle(AgUiRunLifecycleController lc) {
    if (!mounted) return;
    if (lc.isInterrupted) {
      setState(() => _phase = 'interrupted');
    } else if (lc.isFinished) {
      setState(() => _phase = 'done');
    } else {
      setState(() {});
    }
  }

  Future<void> _resume(bool approved) async {
    setState(() => _phase = 'resumed');

    // Build ResumePayload — in production, send this inside RunAgentInput
    final payload = ResumePayload(
      interruptId: 'interrupt-1',
      status: approved ? ResumeStatus.resolved : ResumeStatus.cancelled,
      response: approved ? {'decision': 'approved'} : null,
    );
    debugPrint('ResumePayload.toJson() = ${payload.toJson()}');

    await Future.delayed(const Duration(milliseconds: 300));
    _genCtrl?.clear();

    final eventsCtrl2 = _PhaseStreamController();
    final gen2 = AgUiGenerativeController(
      events: eventsCtrl2.stream,
      widgetRegistry: AgUiWidgetRegistry({}),
    );
    final lc2 = AgUiRunLifecycleController(events: eventsCtrl2.lifecycleStream);
    lc2.addListener(() {
      if (!mounted) return;
      if (lc2.isFinished) setState(() => _phase = 'done');
    });
    gen2.addListener(() {
      if (mounted) setState(() {});
    });
    _lifecycle?.dispose();
    _genCtrl?.dispose();
    setState(() {
      _lifecycle = lc2;
      _genCtrl = gen2;
    });
    eventsCtrl2.emitPhase2(approved: approved);
  }

  void _cleanup() {
    _lifecycle?.dispose();
    _genCtrl?.dispose();
    _lifecycle = null;
    _genCtrl = null;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 8 — Interrupts & Resume')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.pause_circle_outline,
            title: 'AgUiRunLifecycleController + ResumePayload',
            body: 'When a run ends with an interrupt outcome, isInterrupted '
                'becomes true. Build a ResumePayload (resolved or cancelled) '
                'and include it in a new RunAgentInput to continue the run.',
          ),

          // Controls (idle / done only)
          if (_phase == 'idle' || _phase == 'done')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow),
                label: Text(_phase == 'done' ? 'Replay' : 'Start run'),
              ),
            ),

          // Status chip
          if (_phase != 'idle')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(
                    _phase == 'running'
                        ? Icons.hourglass_top
                        : _phase == 'interrupted'
                            ? Icons.pause_circle
                            : _phase == 'done'
                                ? Icons.check_circle
                                : Icons.play_circle,
                    size: 18,
                    color: _phase == 'interrupted'
                        ? cs.error
                        : _phase == 'done'
                            ? Colors.green
                            : cs.primary,
                  ),
                  label: Text(_phase.toUpperCase()),
                  backgroundColor: _phase == 'interrupted'
                      ? cs.errorContainer
                      : _phase == 'done'
                          ? Colors.green.shade50
                          : cs.primaryContainer,
                ),
              ),
            ),

          // Interrupt prompt
          if (_phase == 'interrupted')
            _InterruptPrompt(
              message: 'The agent needs your approval to send the email to '
                  '12,000 subscribers. This action cannot be undone.',
              onApprove: () => _resume(true),
              onReject: () => _resume(false),
            ),

          // Generative view
          Expanded(
            child: _genCtrl == null
                ? Center(
                    child: Text('Press Start run to begin.',
                        style: TextStyle(color: cs.outline)))
                : AgUiGenerativeView(
                    controller: _genCtrl!,
                    registry: AgUiWidgetRegistry({}),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Interrupt prompt ──────────────────────────────────────────────────────────

class _InterruptPrompt extends StatelessWidget {
  const _InterruptPrompt({
    required this.message,
    required this.onApprove,
    required this.onReject,
  });

  final String message;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.3),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
              const SizedBox(width: 8),
              Text('Human approval required',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onReject,
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Simulated phased event stream ─────────────────────────────────────────────

class _PhaseStreamController {
  final _ctrl = StreamController<AgUiEvent>.broadcast();

  Stream<AgUiEvent> get stream => _ctrl.stream;
  Stream<AgUiEvent> get lifecycleStream => _ctrl.stream;

  void emitPhase1() async {
    await _emit({'type': 'RUN_STARTED', 'threadId': 'th1', 'runId': 'r1'},
        delay: 50);

    await _emit({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'm1',
      'role': 'assistant',
    });
    for (final c in ['Preparing to ', 'send the newsletter ', 'campaign…']) {
      await _emit(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': c},
          delay: 120);
    }
    await _emit({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});

    await Future.delayed(const Duration(milliseconds: 300));

    // RUN_FINISHED with interrupt outcome
    await _emit({
      'type': 'RUN_FINISHED',
      'threadId': 'th1',
      'runId': 'r1',
      'outcome': {
        'type': 'interrupt',
        'interrupts': [
          {
            'id': 'interrupt-1',
            'reason': 'approval',
            'message': 'Send newsletter to 12,000 subscribers?',
          },
        ],
      },
    });
    _ctrl.close();
  }

  void emitPhase2({required bool approved}) async {
    await _emit({'type': 'RUN_STARTED', 'threadId': 'th1', 'runId': 'r2'},
        delay: 50);

    final msg = approved
        ? 'Newsletter sent! 12,000 emails delivered successfully.'
        : 'Campaign cancelled as requested. No emails were sent.';

    await _emit({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'm2',
      'role': 'assistant',
    });
    for (var i = 0; i < msg.length; i += 6) {
      final end = (i + 6).clamp(0, msg.length);
      await _emit({
        'type': 'TEXT_MESSAGE_CONTENT',
        'messageId': 'm2',
        'delta': msg.substring(i, end),
      }, delay: 55);
    }
    await _emit({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});

    await Future.delayed(const Duration(milliseconds: 300));
    await _emit({'type': 'RUN_FINISHED', 'threadId': 'th1', 'runId': 'r2'});
    _ctrl.close();
  }

  Future<void> _emit(Map<String, dynamic> json, {int delay = 400}) async {
    await Future.delayed(Duration(milliseconds: delay));
    if (!_ctrl.isClosed) _ctrl.add(AgUiEvent.fromJson(json));
  }
}
