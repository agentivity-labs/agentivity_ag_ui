/// Yes / No confirmation widget — minimal edition.
library;

import 'package:flutter/material.dart';

import '_widget_card.dart';

class AgConfirmWidget extends StatefulWidget {
  const AgConfirmWidget({
    super.key,
    required this.props,
    required this.onSubmit,
  });

  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  @override
  State<AgConfirmWidget> createState() => _AgConfirmWidgetState();
}

class _AgConfirmWidgetState extends State<AgConfirmWidget> {
  bool? _answer;
  bool _submitted = false;

  String  get _confirmLabel => widget.props['confirmLabel'] as String? ?? 'Confirm';
  String  get _cancelLabel  => widget.props['cancelLabel']  as String? ?? 'Cancel';
  String  get _variant      => widget.props['variant']      as String? ?? 'default';
  String? get _message      => widget.props['message']      as String?;

  Color _variantColor(ColorScheme cs) => switch (_variant) {
        'danger'  => const Color(0xFFC62828),
        'success' => const Color(0xFF2E7D32),
        _         => cs.primary,
      };

  String get _submittedLabel =>
      _answer == true ? _confirmLabel : _cancelLabel;

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = _variantColor(cs);

    return AgWidgetCard(
      icon: Icons.help_outline_rounded,
      title:    widget.props['title']    as String? ?? 'Confirm',
      subtitle: widget.props['subtitle'] as String?,
      submitted: _submitted,
      submittedLabel: _submittedLabel,
      onSubmit: _answer != null && !_submitted ? _submit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Optional message
          if (_message != null && _message!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.45),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Buttons
          Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  label: _cancelLabel,
                  selected: _answer == false,
                  disabled: _submitted,
                  filled: false,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  borderColor: cs.outlineVariant,
                  onTap: () {
                    if (!_submitted) setState(() => _answer = false);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AnswerButton(
                  label: _confirmLabel,
                  selected: _answer == true,
                  disabled: _submitted,
                  filled: true,
                  color: color,
                  borderColor: color,
                  onTap: () {
                    if (!_submitted) setState(() => _answer = true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    widget.onSubmit({'confirmed': _answer});
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.filled,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final bool filled;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (filled ? color : color.withValues(alpha: 0.08))
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? borderColor : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? (filled ? Colors.white : color)
                : cs.onSurface.withValues(alpha: disabled ? 0.3 : 0.65),
          ),
        ),
      ),
    );
  }
}
