/// Free-text input — minimal edition.
library;

import 'package:flutter/material.dart';

import '_widget_card.dart';

class AgTextInputWidget extends StatefulWidget {
  const AgTextInputWidget({
    super.key,
    required this.props,
    required this.onSubmit,
  });

  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  @override
  State<AgTextInputWidget> createState() => _AgTextInputWidgetState();
}

class _AgTextInputWidgetState extends State<AgTextInputWidget> {
  late final TextEditingController _ctrl;
  bool _submitted = false;
  String? _error;

  bool   get _multiline    => widget.props['multiline'] == true;
  int?   get _maxLength    => (widget.props['maxLength'] as num?)?.toInt();
  String get _validate     => widget.props['validate'] as String? ?? 'none';
  String get _placeholder  =>
      widget.props['placeholder'] as String? ?? 'Type here…';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _ctrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AgWidgetCard(
      icon: Icons.edit_outlined,
      title:    widget.props['title']    as String? ?? 'Enter text',
      subtitle: widget.props['subtitle'] as String?,
      submitted: _submitted,
      submittedLabel: _ctrl.text.length > 32
          ? '${_ctrl.text.substring(0, 32)}…'
          : _ctrl.text,
      onSubmit: _ctrl.text.trim().isNotEmpty ? _submit : null,
      child: TextField(
        controller: _ctrl,
        enabled: !_submitted,
        maxLines: _multiline ? 3 : 1,
        maxLength: _maxLength,
        style: const TextStyle(fontSize: 12),
        keyboardType: _validate == 'email'
            ? TextInputType.emailAddress
            : _validate == 'phone'
                ? TextInputType.phone
                : _multiline
                    ? TextInputType.multiline
                    : TextInputType.text,
        decoration: InputDecoration(
          hintText: _placeholder,
          errorText: _error,
          errorStyle: const TextStyle(fontSize: 10),
        ),
        onSubmitted: _multiline ? null : (_) => _submit(),
      ),
    );
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_validate == 'email' &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text)) {
      setState(() => _error = 'Invalid email address');
      return;
    }
    if (_validate == 'phone' &&
        !RegExp(r'^[\d\s\+\-\(\)]{7,}').hasMatch(text)) {
      setState(() => _error = 'Invalid phone number');
      return;
    }
    setState(() => _submitted = true);
    widget.onSubmit({'text': text});
  }
}
