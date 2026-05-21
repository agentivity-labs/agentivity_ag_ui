/// Persistent animated itinerary bar shown at the bottom of the travel screen.
library;

import 'package:flutter/material.dart';

/// Reads confirmed booking data from [AgUiStateController.state] and renders
/// a summary bar at the bottom of the screen.
///
/// [state] — the raw state map from AgUiStateController.
class ItineraryBar extends StatefulWidget {
  const ItineraryBar({super.key, required this.state});

  final Map<String, dynamic> state;

  @override
  State<ItineraryBar> createState() => _ItineraryBarState();
}

class _ItineraryBarState extends State<ItineraryBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;
  bool _wasConfirmed = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.96), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ItineraryBar old) {
    super.didUpdateWidget(old);
    final isNowConfirmed = widget.state['status'] == 'confirmed';
    if (isNowConfirmed && !_wasConfirmed) {
      _bounce
        ..reset()
        ..forward();
    }
    _wasConfirmed = isNowConfirmed;
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isConfirmed = state['status'] == 'confirmed';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      height: isConfirmed ? 74 : 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2438), Color(0xFF081828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF1E4060), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Icon ─────────────────────────────────────────────────────────
            ScaleTransition(
              scale: _scale,
              child: Icon(
                isConfirmed
                    ? Icons.confirmation_num_outlined
                    : Icons.flight_outlined,
                color: isConfirmed
                    ? const Color(0xFF00B4D8)
                    : Colors.white30,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: isConfirmed
                    ? _ConfirmedContent(state: state)
                    : const _IdleContent(),
              ),
            ),

            // ── Total ─────────────────────────────────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: isConfirmed ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                offset: isConfirmed ? Offset.zero : const Offset(1, 0),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '€${_total(state)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _total(Map<String, dynamic> state) {
    final t = state['total'];
    if (t is num) return t.toInt().toString();
    return '—';
  }
}

class _IdleContent extends StatelessWidget {
  const _IdleContent();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No booking yet — choose your trip above',
      key: ValueKey('idle'),
      style: TextStyle(color: Colors.white30, fontSize: 13),
    );
  }
}

class _ConfirmedContent extends StatelessWidget {
  const _ConfirmedContent({required this.state});
  final Map<String, dynamic> state;

  @override
  Widget build(BuildContext context) {
    final flight = state['flight'] as Map?;
    final hotel = state['hotel'] as Map?;
    final pnr = state['pnr'] as String?;

    return Column(
      key: const ValueKey('confirmed'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (flight != null)
          Text(
            '${flight['originCode']} → ${flight['destinationCode']}  '
            '${flight['departure']} › ${flight['arrival']}',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        if (hotel != null)
          Text(
            '${hotel['name']}  ·  ${hotel['nights']}n'
            '${pnr != null ? '  ·  PNR: $pnr' : ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
      ],
    );
  }
}
