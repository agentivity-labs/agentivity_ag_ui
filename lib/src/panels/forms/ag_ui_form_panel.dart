import 'package:flutter/material.dart';

import 'form_controller.dart';
import 'form_models.dart';
import 'form_theme.dart';

/// Renders a single [FormRequest] as an interactive form.
///
/// Styling: add [AgUiFormTheme] to your [ThemeData.extensions].
/// Override buttons or individual fields with builder callbacks.
class AgUiFormPanel extends StatefulWidget {
  const AgUiFormPanel({
    super.key,
    required this.request,
    required this.controller,
    this.style,
    this.fieldBuilder,
    this.actionsBuilder,
    this.onSubmitted,
  });

  final FormRequest request;
  final FormController controller;
  final AgUiFormTheme? style;

  /// Override rendering of a single field.
  final Widget Function(AgFormField field, ValueChanged<dynamic> onChange)?
      fieldBuilder;

  /// Override the entire actions row (approve/reject/submit buttons).
  final Widget Function(
      FormRequest request, void Function(FormOutcome outcome) onAct)? actionsBuilder;

  /// Called after successful submission.
  final VoidCallback? onSubmitted;

  @override
  State<AgUiFormPanel> createState() => _AgUiFormPanelState();
}

class _AgUiFormPanelState extends State<AgUiFormPanel> {
  final Map<String, dynamic> _values = {};
  bool _submitting = false;
  String? _error;

  FormRequest get _request => widget.request;

  @override
  void initState() {
    super.initState();
    for (final field in _request.fields) {
      _values[field.name] = field.defaultValue;
    }
  }

  Future<void> _act(FormOutcome outcome) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = FormResponse(
        outcome: outcome,
        data: Map<String, dynamic>.from(_values),
      );
      await widget.controller.submitResponse(
          request: _request, response: response);
      widget.onSubmitted?.call();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AgUiFormTheme.of(context).copyWith(
      cardColor: widget.style?.cardColor,
      titleStyle: widget.style?.titleStyle,
      descriptionStyle: widget.style?.descriptionStyle,
      approveColor: widget.style?.approveColor,
      rejectColor: widget.style?.rejectColor,
      submitColor: widget.style?.submitColor,
      fieldLabelStyle: widget.style?.fieldLabelStyle,
      borderRadius: widget.style?.borderRadius,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final radius = theme.borderRadius ?? BorderRadius.circular(12);

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_request.title,
                style: theme.titleStyle ??
                    Theme.of(context).textTheme.titleMedium),
            if (_request.description != null) ...[
              const SizedBox(height: 6),
              Text(_request.description!,
                  style: theme.descriptionStyle ??
                      Theme.of(context).textTheme.bodyMedium),
            ],
            if (_request.fields.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._request.fields.map((field) {
                if (widget.fieldBuilder != null) {
                  return widget.fieldBuilder!(
                      field, (v) => setState(() => _values[field.name] = v));
                }
                return _FieldWidget(
                  field: field,
                  value: _values[field.name],
                  labelStyle: theme.fieldLabelStyle,
                  onChanged: (v) => setState(() => _values[field.name] = v),
                );
              }),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            widget.actionsBuilder?.call(_request, _act) ??
                _DefaultActions(
                  request: _request,
                  submitting: _submitting,
                  theme: theme,
                  onAct: _act,
                ),
          ],
        ),
      ),
    );
  }
}

// ── Field renderers ───────────────────────────────────────────────────────────

class _FieldWidget extends StatelessWidget {
  const _FieldWidget({
    required this.field,
    required this.value,
    required this.onChanged,
    this.labelStyle,
  });

  final AgFormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.isRequired ? '${field.label} *' : field.label,
            style: labelStyle ?? Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          _fieldInput(context),
          if (field.hint != null)
            Text(field.hint!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  Widget _fieldInput(BuildContext context) {
    switch (field.type) {
      case FormFieldType.boolean:
        return Switch(
          value: value == true,
          onChanged: onChanged,
        );

      case FormFieldType.choice:
        final options = field.options ?? const [];
        return DropdownButtonFormField<String>(
          initialValue: value is String ? value : null,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
        );

      case FormFieldType.multilineText:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          maxLines: 4,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
          onChanged: onChanged,
        );

      case FormFieldType.number:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
          onChanged: (s) => onChanged(num.tryParse(s)),
        );

      case FormFieldType.date:
        final date = value is DateTime
            ? value as DateTime
            : DateTime.tryParse(value?.toString() ?? '');
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked.toIso8601String());
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            child: Text(date != null
                ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                : 'Select date'),
          ),
        );

      case FormFieldType.file:
      case FormFieldType.text:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
          onChanged: onChanged,
        );
    }
  }
}

// ── Default action buttons ────────────────────────────────────────────────────

class _DefaultActions extends StatelessWidget {
  const _DefaultActions({
    required this.request,
    required this.submitting,
    required this.theme,
    required this.onAct,
  });

  final FormRequest request;
  final bool submitting;
  final AgUiFormTheme theme;
  final void Function(FormOutcome) onAct;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (submitting) return const Center(child: CircularProgressIndicator());

    return switch (request.kind) {
      FormRequestKind.approval => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor:
                      theme.rejectColor ?? colorScheme.error),
              onPressed: () => onAct(FormOutcome.rejected),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor:
                      theme.approveColor ?? colorScheme.primary),
              onPressed: () => onAct(FormOutcome.approved),
              child: const Text('Approve'),
            ),
          ],
        ),
      FormRequestKind.notification => Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => onAct(FormOutcome.submitted),
            child: const Text('Acknowledge'),
          ),
        ),
      _ => Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: theme.submitColor ?? colorScheme.primary),
            onPressed: () => onAct(FormOutcome.submitted),
            child: const Text('Submit'),
          ),
        ),
    };
  }
}
