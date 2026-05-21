/// Single or multi-choice selector — minimal edition.
library;

import 'package:flutter/material.dart';

import '_widget_card.dart';

class AgChoiceWidget extends StatefulWidget {
  const AgChoiceWidget({
    super.key,
    required this.props,
    required this.onSubmit,
  });

  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  @override
  State<AgChoiceWidget> createState() => _AgChoiceWidgetState();
}

class _AgChoiceWidgetState extends State<AgChoiceWidget> {
  String? _single;
  final Set<String> _multi = {};
  bool _submitted = false;

  bool get _isMulti => widget.props['multiSelect'] == true;
  List<String> get _options =>
      (widget.props['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
  int  get _minSelect => (widget.props['minSelect'] as num?)?.toInt() ?? 1;
  int? get _maxSelect => (widget.props['maxSelect'] as num?)?.toInt();

  bool get _canSubmit =>
      _isMulti ? _multi.length >= _minSelect : _single != null;

  String get _submittedLabel =>
      _isMulti ? '${_multi.length} selected' : (_single ?? '');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AgWidgetCard(
      icon: _isMulti
          ? Icons.checklist_rounded
          : Icons.radio_button_checked_rounded,
      title:   widget.props['title']    as String? ?? 'Choose an option',
      subtitle: widget.props['subtitle'] as String?,
      submitted: _submitted,
      submittedLabel: _submittedLabel,
      onSubmit: _canSubmit ? _submit : null,
      child: Column(
        children: _options.map((opt) {
          final selected = _isMulti ? _multi.contains(opt) : _single == opt;
          final disabled = _submitted ||
              (_isMulti &&
                  !selected &&
                  _maxSelect != null &&
                  _multi.length >= _maxSelect!);

          return GestureDetector(
            onTap: disabled ? null : () => setState(() {
              if (_isMulti) {
                _multi.contains(opt)
                    ? _multi.remove(opt)
                    : _multi.add(opt);
              } else {
                _single = opt;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isMulti
                        ? (selected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded)
                        : (selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded),
                    size: 14,
                    color: selected
                        ? cs.primary
                        : cs.onSurface.withValues(
                            alpha: disabled ? 0.25 : 0.4),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: cs.onSurface.withValues(
                            alpha: disabled ? 0.35 : 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    widget.onSubmit(
      _isMulti
          ? {'selected': _multi.toList()}
          : {'selected': _single},
    );
  }
}
