/// Shared card shell for all interactive agent widgets — minimal edition.
library;

import 'package:flutter/material.dart';

class AgWidgetCard extends StatelessWidget {
  const AgWidgetCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.submitted,
    this.submittedLabel,
    required this.onSubmit,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool submitted;
  final String? submittedLabel;
  final VoidCallback? onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: submitted
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Row(
              children: [
                Icon(icon, size: 13, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (submitted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 10, color: cs.primary),
                        const SizedBox(width: 3),
                        Text(
                          submittedLabel != null &&
                                  submittedLabel!.isNotEmpty
                              ? submittedLabel!
                              : 'Done',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),

          // ── Divider ──────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Divider(),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: child,
          ),

          // ── Submit / Done ─────────────────────────────────────────────────
          if (!submitted)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                height: 30,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: const Text('Confirm'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
