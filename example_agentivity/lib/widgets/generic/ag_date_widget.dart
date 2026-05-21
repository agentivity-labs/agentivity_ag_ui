/// Date / datetime / range picker — minimal edition.
library;

import 'package:flutter/material.dart';

import '_widget_card.dart';

class AgDateWidget extends StatefulWidget {
  const AgDateWidget({
    super.key,
    required this.props,
    required this.onSubmit,
  });

  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  @override
  State<AgDateWidget> createState() => _AgDateWidgetState();
}

class _AgDateWidgetState extends State<AgDateWidget> {
  DateTime? _date;
  DateTime? _rangeEnd;
  TimeOfDay? _time;
  bool _submitted = false;

  String get _mode => widget.props['mode'] as String? ?? 'date';

  DateTime get _minDate => _parseDate(widget.props['minDate']) ??
      DateTime.now().subtract(const Duration(days: 365));
  DateTime get _maxDate => _parseDate(widget.props['maxDate']) ??
      DateTime.now().add(const Duration(days: 365 * 2));
  DateTime get _initialDate =>
      _parseDate(widget.props['initialDate']) ?? DateTime.now();

  DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} '
      '${_monthName(d.month)} ${d.year}';

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  bool get _canSubmit {
    if (_mode == 'range') return _date != null && _rangeEnd != null;
    return _date != null;
  }

  String get _submittedLabel {
    if (_date == null) return '';
    if (_mode == 'range' && _rangeEnd != null) {
      return '${_fmt(_date!)} → ${_fmt(_rangeEnd!)}';
    }
    if (_mode == 'datetime' && _time != null) {
      return '${_fmt(_date!)} ${_time!.format(context)}';
    }
    return _fmt(_date!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AgWidgetCard(
      icon: Icons.calendar_today_outlined,
      title:    widget.props['title']    as String? ?? 'Select a date',
      subtitle: widget.props['subtitle'] as String?,
      submitted: _submitted,
      submittedLabel: _submittedLabel,
      onSubmit: _canSubmit ? _submit : null,
      child: Column(
        children: [
          _PickerRow(
            icon: Icons.event_outlined,
            label: _date != null
                ? _fmt(_date!)
                : (_mode == 'range' ? 'Start date' : 'Pick a date'),
            hasValue: _date != null,
            disabled: _submitted,
            onTap: () => _pickDate(isStart: true),
            cs: cs,
          ),
          if (_mode == 'range') ...[
            const SizedBox(height: 4),
            _PickerRow(
              icon: Icons.event_outlined,
              label: _rangeEnd != null ? _fmt(_rangeEnd!) : 'End date',
              hasValue: _rangeEnd != null,
              disabled: _submitted || _date == null,
              onTap: () => _pickDate(isStart: false),
              cs: cs,
            ),
          ],
          if (_mode == 'datetime') ...[
            const SizedBox(height: 4),
            _PickerRow(
              icon: Icons.access_time_outlined,
              label: _time != null ? _time!.format(context) : 'Pick a time',
              hasValue: _time != null,
              disabled: _submitted || _date == null,
              onTap: _pickTime,
              cs: cs,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_date ?? _initialDate)
        : (_rangeEnd ?? _date?.add(const Duration(days: 1)) ?? _initialDate);
    final min = isStart ? _minDate : (_date ?? _minDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.clamp(_minDate, _maxDate),
      firstDate: min,
      lastDate: _maxDate,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _date = picked;
        if (_rangeEnd != null && _rangeEnd!.isBefore(picked)) _rangeEnd = null;
      } else {
        _rangeEnd = picked;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    setState(() => _submitted = true);
    final d = _date!;
    if (_mode == 'range') {
      widget.onSubmit({
        'start': d.toIso8601String().substring(0, 10),
        'end':   _rangeEnd!.toIso8601String().substring(0, 10),
      });
    } else if (_mode == 'datetime' && _time != null) {
      widget.onSubmit({
        'datetime':
            '${d.toIso8601String().substring(0, 10)}'
            'T${_time!.hour.toString().padLeft(2, '0')}'
            ':${_time!.minute.toString().padLeft(2, '0')}',
      });
    } else {
      widget.onSubmit({'date': d.toIso8601String().substring(0, 10)});
    }
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.disabled,
    required this.onTap,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final bool hasValue;
  final bool disabled;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasValue && !disabled ? cs.primary : cs.outlineVariant,
            width: hasValue && !disabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color: hasValue
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.35)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.4),
                  fontWeight:
                      hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (!disabled)
              Icon(Icons.chevron_right_rounded,
                  size: 14,
                  color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

extension on DateTime {
  DateTime clamp(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}
