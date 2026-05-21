/// AI Customer Support home screen.
///
/// Demonstrates the AG-UI protocol in a professional light-themed support UI:
///   • Broadcast stream → 4 controllers in parallel
///   • Customer complaint shown as a static message card
///   • Agent reasoning, tool call cards, streaming response
///   • STATE_SNAPSHOT drives the TicketStatusBar
///   • Human-in-the-loop: supervisor escalation approval bottom sheet
library;

import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import '../data/demo_stream.dart';
import '../widgets/ticket_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  AgUiRunLifecycleController? _lifecycle;
  AgUiActivityController? _activity;
  AgUiStateController? _stateCtrl;
  AgUiGenerativeController? _genCtrl;

  // ── UI state ─────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _waitingForApproval = false;
  bool _done = false;
  Map<String, dynamic> _ticketState = const {};

  // ── Widget registry (no generative components in this demo, but required) ───
  final _registry = const AgUiWidgetRegistry({});

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), _startDemo);
  }

  // ── Demo lifecycle ────────────────────────────────────────────────────────────

  void _startDemo() {
    _disposeAll();
    final broadcast = buildDemoStream().asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: broadcast);
    final activity = AgUiActivityController(events: broadcast);
    final stateCtrl = AgUiStateController(events: broadcast);
    final genCtrl =
        AgUiGenerativeController(events: broadcast, widgetRegistry: _registry);

    lifecycle.addListener(() => _onLifecycle(lifecycle));
    activity.addListener(() {
      if (mounted) setState(() {});
    });
    stateCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _ticketState = stateCtrl.state);
    });
    genCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() {
      _lifecycle = lifecycle;
      _activity = activity;
      _stateCtrl = stateCtrl;
      _genCtrl = genCtrl;
      _running = true;
      _waitingForApproval = false;
      _done = false;
      _ticketState = const {};
    });
  }

  void _onLifecycle(AgUiRunLifecycleController lc) {
    if (!mounted) return;
    if (lc.isInterrupted) {
      setState(() {
        _running = false;
        _waitingForApproval = true;
      });
      Future.delayed(
          const Duration(milliseconds: 600), () => _showApprovalSheet());
    } else if (lc.isFinished) {
      setState(() {
        _running = false;
        _done = true;
      });
    } else {
      setState(() {});
    }
  }

  void _showApprovalSheet() {
    if (!mounted || !_waitingForApproval) return;
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EscalationSheet(
        onApprove: () => Navigator.of(ctx).pop(true),
        onDecline: () => Navigator.of(ctx).pop(false),
      ),
    ).then((approved) {
      if (approved == true) _resumeAfterApproval();
    });
  }

  void _resumeAfterApproval() {
    _disposeAll();
    setState(() {
      _waitingForApproval = false;
      _running = true;
      _done = false;
    });

    final resumeBroadcast = buildResumeStream().asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: resumeBroadcast);
    final stateCtrl = AgUiStateController(events: resumeBroadcast);
    final genCtrl = AgUiGenerativeController(
        events: resumeBroadcast, widgetRegistry: _registry);

    lifecycle.addListener(() {
      if (!mounted) return;
      if (lifecycle.isFinished) setState(() { _running = false; _done = true; });
    });
    stateCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _ticketState = stateCtrl.state);
    });
    genCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() {
      _lifecycle = lifecycle;
      _stateCtrl = stateCtrl;
      _genCtrl = genCtrl;
    });
  }

  void _disposeAll() {
    final lc = _lifecycle;
    final ac = _activity;
    final sc = _stateCtrl;
    final gc = _genCtrl;
    _lifecycle = null;
    _activity = null;
    _stateCtrl = null;
    _genCtrl = null;
    lc?.dispose();
    ac?.dispose();
    sc?.dispose();
    gc?.dispose();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentActivity = _activity?.current;
    final genCtrl = _genCtrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Case header ────────────────────────────────────────────────────
          _CaseHeader(ticketState: _ticketState, running: _running),

          // ── Customer message (static) ──────────────────────────────────────
          const _CustomerMessageCard(),

          // ── Activity bar ───────────────────────────────────────────────────
          if (currentActivity != null)
            _ActivityBar(activity: currentActivity),

          // ── Agent analysis & response ──────────────────────────────────────
          Expanded(
            child: genCtrl == null
                ? _buildSplash()
                : AgUiGenerativeView(
                    controller: genCtrl,
                    registry: _registry,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    emptyBuilder: (_) => _buildWaiting(),
                  ),
          ),

          // ── Escalation prompt ──────────────────────────────────────────────
          if (_waitingForApproval)
            _EscalationPromptBanner(onTap: _showApprovalSheet),

          // ── Ticket status bar ──────────────────────────────────────────────
          TicketBar(state: _ticketState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1565C0),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('AI Customer Support',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _running
                                ? Colors.greenAccent
                                : _waitingForApproval
                                    ? Colors.orangeAccent
                                    : _done
                                        ? Colors.lightBlueAccent
                                        : Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _running
                              ? 'Agent analysing…'
                              : _waitingForApproval
                                  ? 'Awaiting supervisor approval'
                                  : _done
                                      ? 'Resolved'
                                      : 'Ready',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (_done || (!_running && _genCtrl != null))
                  IconButton(
                    onPressed: _startDemo,
                    icon: const Icon(Icons.replay_rounded,
                        color: Colors.white70),
                    tooltip: 'Replay demo',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplash() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.support_agent_rounded,
              size: 56, color: Color(0xFF1565C0)),
          SizedBox(height: 16),
          Text(
            'AI Support Agent',
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Starting demo…',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}

// ── Case header ───────────────────────────────────────────────────────────────

class _CaseHeader extends StatelessWidget {
  const _CaseHeader({required this.ticketState, required this.running});
  final Map<String, dynamic> ticketState;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final caseId = ticketState['caseId'] as String? ?? 'SR-2024-4821';
    final category = ticketState['category'] as String? ?? 'Order Delay';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inbox_rounded,
                color: Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseId,
                  style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  category,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          if (running)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1565C0),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Customer message card ─────────────────────────────────────────────────────

class _CustomerMessageCard extends StatelessWidget {
  const _CustomerMessageCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCDDF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    const Color(0xFF1565C0).withValues(alpha: 0.15),
                child: const Text('M',
                    style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marie Dupont',
                      style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text('Today · 14:18',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Hi, my order #4821 hasn\'t arrived yet and it\'s been almost '
            '3 weeks since I placed it. The tracking hasn\'t updated in '
            '5 days. This is really frustrating — it was a gift. '
            'Can you please help me urgently?',
            style: TextStyle(
                color: Color(0xFF1A1A2E), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Activity bar ──────────────────────────────────────────────────────────────

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.activity});
  final AgUiActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCDDF0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: activity.progress,
              color: const Color(0xFF1565C0),
              backgroundColor: const Color(0xFFCCDDF0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activity.label,
                    style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                if (activity.description != null)
                  Text(activity.description!,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          if (activity.progress != null)
            Text(
              '${(activity.progress! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

// ── Escalation prompt banner ──────────────────────────────────────────────────

class _EscalationPromptBanner extends StatelessWidget {
  const _EscalationPromptBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF57C00), Color(0xFFE65100)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF57C00).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Supervisor approval required — tap to review',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Escalation approval bottom sheet ─────────────────────────────────────────

class _EscalationSheet extends StatelessWidget {
  const _EscalationSheet({required this.onApprove, required this.onDecline});

  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.escalator_warning_rounded,
                    color: Color(0xFFF57C00), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escalation Request',
                      style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Case SR-2024-4821 · Order Delay',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reason card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escalation reason',
                  style: TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                SizedBox(height: 6),
                Text(
                  'Delivery delay: 12 business days (threshold: 10 days). '
                  'Policy mandates Level 2 escalation. Customer eligible for '
                  '€15 compensation voucher.',
                  style: TextStyle(
                      color: Color(0xFF5D4037), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If approved, the agent will:',
                  style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                SizedBox(height: 8),
                _ActionItem(icon: Icons.swap_vert_rounded,
                    text: 'Escalate case to Level 2 Priority Support'),
                _ActionItem(icon: Icons.card_giftcard_rounded,
                    text: 'Issue €15 compensation voucher'),
                _ActionItem(icon: Icons.local_shipping_rounded,
                    text: 'Open carrier investigation with DHL'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF57C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Approve Escalation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF444466), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
