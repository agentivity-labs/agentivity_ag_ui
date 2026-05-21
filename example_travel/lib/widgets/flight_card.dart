import 'package:flutter/material.dart';

import '../data/travel_models.dart';

/// Renders a single flight option — rendered by the agent via AgUiWidgetRegistry.
class TravelFlightCard extends StatelessWidget {
  const TravelFlightCard({super.key, required this.flight});

  final TravelFlight flight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: flight.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: flight.gradient.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const Text('✈️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.airline,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      flight.flightNumber,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                if (flight.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      flight.badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Route ────────────────────────────────────────────────────────
            Row(
              children: [
                _TimeStop(
                  code: flight.originCode,
                  city: flight.origin,
                  time: flight.departure,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const _DashedLine(),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          flight.duration,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                _TimeStop(
                  code: flight.destinationCode,
                  city: flight.destination,
                  time: flight.arrival,
                  alignRight: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Footer ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flight.cabin,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ),
                const Spacer(),
                Text(
                  '€${flight.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  ' /person',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeStop extends StatelessWidget {
  const _TimeStop({
    required this.code,
    required this.city,
    required this.time,
    this.alignRight = false,
  });

  final String code;
  final String city;
  final String time;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          code,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        Text(
          city,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        12,
        (_) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: Colors.white30,
          ),
        ),
      ),
    );
  }
}
