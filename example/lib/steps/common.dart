/// Shared widgets for the step-by-step example screens.
library;

import 'package:flutter/material.dart';

/// A compact info card shown at the top of each step screen explaining
/// what concept is being demonstrated.
class StepInfoCard extends StatelessWidget {
  const StepInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Run / Reset button row used by most step screens.
class StepRunBar extends StatelessWidget {
  const StepRunBar({
    super.key,
    required this.running,
    required this.onRun,
    this.runLabel = 'Run',
    this.runningLabel = 'Running…',
    this.onReset,
  });

  final bool running;
  final VoidCallback onRun;
  final String runLabel;
  final String runningLabel;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: running ? null : onRun,
            icon: const Icon(Icons.play_arrow),
            label: Text(running ? runningLabel : runLabel),
          ),
          if (onReset != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: running ? null : onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ],
      ),
    );
  }
}
