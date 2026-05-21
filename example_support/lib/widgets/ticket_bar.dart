/// Ticket status bar shown at the bottom of the support screen.
library;

import 'package:flutter/material.dart';

/// Shows the current state of the support ticket, driven by [AgUiStateController].
class TicketBar extends StatefulWidget {
  const TicketBar({super.key, required this.state});

  final Map<String, dynamic> state;

  @override
  State<TicketBar> createState() => _TicketBarState();
}

class _TicketBarState extends State<TicketBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  String? _prevStatus;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(TicketBar old) {
    super.didUpdateWidget(old);
    final newStatus = widget.state['status'] as String?;
    if (newStatus != _prevStatus && newStatus == 'escalated') {
      _pulse
        ..reset()
        ..forward();
    }
    _prevStatus = newStatus;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final caseId = state['caseId'] as String?;
    final status = state['status'] as String?;
    final priority = state['priority'] as String?;
    final eta = state['eta'] as String?;
    final isEscalated = status == 'escalated';
    final isOpen = status == 'open';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      height: caseId != null ? 68 : 56,
      decoration: BoxDecoration(
        color: isEscalated ? const Color(0xFFFFF3E0) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isEscalated
                ? const Color(0xFFFFA726)
                : const Color(0xFFDDE6F0),
            width: isEscalated ? 1.5 : 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Status icon ──────────────────────────────────────────────────
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.elasticOut),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEscalated
                      ? const Color(0xFFFFA726).withValues(alpha: 0.15)
                      : isOpen
                          ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEscalated
                      ? Icons.priority_high_rounded
                      : Icons.support_agent_rounded,
                  size: 18,
                  color: isEscalated
                      ? const Color(0xFFF57C00)
                      : isOpen
                          ? const Color(0xFF1565C0)
                          : Colors.grey,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // ── Ticket info ──────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: caseId == null
                    ? const Text(
                        'No active ticket',
                        key: ValueKey('empty'),
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13),
                      )
                    : Column(
                        key: ValueKey(status),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                caseId,
                                style: const TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (priority != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA726),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    priority,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isEscalated
                                ? 'Escalated${eta != null ? ' · ETA $eta' : ''}'
                                : 'Open · Order Delay',
                            style: TextStyle(
                                color: isEscalated
                                    ? const Color(0xFFF57C00)
                                    : Colors.grey,
                                fontSize: 11),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Status badge ─────────────────────────────────────────────────
            if (status != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isEscalated
                      ? const Color(0xFFF57C00)
                      : const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEscalated ? 'Escalated' : 'Open',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
