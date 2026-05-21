/// Numeric slider — minimal edition.
library;

import 'package:flutter/material.dart';

import '_widget_card.dart';

class AgSliderWidget extends StatefulWidget {
  const AgSliderWidget({
    super.key,
    required this.props,
    required this.onSubmit,
  });

  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  @override
  State<AgSliderWidget> createState() => _AgSliderWidgetState();
}

class _AgSliderWidgetState extends State<AgSliderWidget> {
  late double _value;
  late RangeValues _range;
  bool _submitted = false;

  double  get _min     => (widget.props['min']     as num?)?.toDouble() ?? 0;
  double  get _max     => (widget.props['max']     as num?)?.toDouble() ?? 100;
  double? get _step    => (widget.props['step']    as num?)?.toDouble();
  String  get _unit    =>  widget.props['unit']    as String? ?? '';
  bool    get _isRange =>  widget.props['range']   == true;

  int get _divisions {
    final step = _step;
    if (step == null || step <= 0) return 100;
    final count = ((_max - _min) / step).round();
    return count < 1 ? 1 : count;
  }

  @override
  void initState() {
    super.initState();
    final initial = (widget.props['initial'] as num?)?.toDouble();
    _value = (initial ?? (_min + (_max - _min) / 2)).clamp(_min, _max);
    _range = RangeValues(_min, _min + (_max - _min) * 0.5);
  }

  String _fmt(double v) {
    final s = v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
    return _unit.isEmpty ? s : '$s$_unit';
  }

  String get _submittedLabel =>
      _isRange ? '${_fmt(_range.start)} – ${_fmt(_range.end)}' : _fmt(_value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AgWidgetCard(
      icon: Icons.tune_rounded,
      title:    widget.props['title']    as String? ?? 'Select a value',
      subtitle: widget.props['subtitle'] as String?,
      submitted: _submitted,
      submittedLabel: _submittedLabel,
      onSubmit: _submitted ? null : _submit,
      child: Column(
        children: [
          // Value display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRange
                      ? '${_fmt(_range.start)} – ${_fmt(_range.end)}'
                      : _fmt(_value),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Slider
          if (_isRange)
            RangeSlider(
              values: _range,
              min: _min,
              max: _max,
              divisions: _divisions,
              labels: RangeLabels(_fmt(_range.start), _fmt(_range.end)),
              onChanged: _submitted
                  ? null
                  : (v) => setState(() => _range = v),
              activeColor: cs.primary,
              inactiveColor: cs.outlineVariant,
            )
          else
            Slider(
              value: _value,
              min: _min,
              max: _max,
              divisions: _divisions,
              label: _fmt(_value),
              onChanged: _submitted
                  ? null
                  : (v) => setState(() => _value = v),
              activeColor: cs.primary,
              inactiveColor: cs.outlineVariant,
            ),

          // Min / Max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(_min),
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.4))),
              Text(_fmt(_max),
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_isRange) {
      widget.onSubmit({'min': _snap(_range.start), 'max': _snap(_range.end)});
    } else {
      widget.onSubmit({'value': _snap(_value)});
    }
  }

  dynamic _snap(double v) =>
      v == v.truncateToDouble() ? v.toInt() : v;
}
