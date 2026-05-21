/// Display-only info card — minimal edition.
library;

import 'package:flutter/material.dart';

class AgInfoCard extends StatelessWidget {
  const AgInfoCard({super.key, required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final title   = props['title']   as String? ?? '';
    final message = props['message'] as String? ?? '';
    final variant = props['variant'] as String? ?? 'info';

    final (icon, fg) = switch (variant) {
      'success' => (Icons.check_circle_outline_rounded, const Color(0xFF2E7D32)),
      'warning' => (Icons.warning_amber_rounded,         const Color(0xFFF57F17)),
      'error'   => (Icons.error_outline_rounded,         const Color(0xFFC62828)),
      _         => (Icons.info_outline_rounded,           const Color(0xFF1565C0)),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? fg.withValues(alpha: 0.12)
        : fg.withValues(alpha: 0.06);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                if (title.isNotEmpty && message.isNotEmpty)
                  const SizedBox(height: 2),
                if (message.isNotEmpty)
                  Text(message,
                      style: TextStyle(
                          color: fg.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
