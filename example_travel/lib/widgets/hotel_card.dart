import 'package:flutter/material.dart';

import '../data/travel_models.dart';

/// Renders a single hotel option — rendered by the agent via AgUiWidgetRegistry.
class TravelHotelCard extends StatelessWidget {
  const TravelHotelCard({super.key, required this.hotel});

  final TravelHotel hotel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hotel.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hotel.gradient.first.withValues(alpha: 0.3),
            blurRadius: 16,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Text(
                        hotel.neighborhood,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      _StarRow(stars: hotel.stars),
                    ],
                  ),
                ),
                if (hotel.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hotel.badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Rating ───────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  hotel.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Text(
                  '  (${_formatReviews(hotel.reviews)} reviews)',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Amenities ────────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hotel.amenities
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 14),

            // ── Price ────────────────────────────────────────────────────────
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '€${hotel.pricePerNight.toStringAsFixed(0)} / night',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      '${hotel.nights} nights',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '€${hotel.hotelTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  ' total',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatReviews(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 13,
        ),
      ),
    );
  }
}
