/// Tag / keyword input — minimal edition.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '_widget_card.dart';

class AgTagWidget extends StatefulWidget {
  const AgTagWidget({
    super.key,
    required this.props,
    required this.onSubmit,
  });

  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  @override
  State<AgTagWidget> createState() => _AgTagWidgetState();
}

class _AgTagWidgetState extends State<AgTagWidget> {
  final List<String> _tags = [];
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  bool _submitted = false;

  String get _placeholder =>
      widget.props['placeholder'] as String? ?? 'Add a keyword…';
  int?   get _maxTags     => (widget.props['maxTags'] as num?)?.toInt();
  int    get _minTags     => (widget.props['minTags'] as num?)?.toInt() ?? 1;
  List<String> get _suggestions =>
      (widget.props['suggestions'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];

  bool get _canAdd {
    final text = _ctrl.text.trim();
    return text.isNotEmpty &&
        !_tags.contains(text) &&
        (_maxTags == null || _tags.length < _maxTags!);
  }

  bool get _canSubmit  => _tags.length >= _minTags;
  bool get _atMax      => _maxTags != null && _tags.length >= _maxTags!;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t) || _atMax) return;
    setState(() {
      _tags.add(t);
      _ctrl.clear();
    });
    _focus.requestFocus();
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unused = _suggestions.where((s) => !_tags.contains(s)).toList();

    return AgWidgetCard(
      icon: Icons.label_outline_rounded,
      title:    widget.props['title']    as String? ?? 'Add tags',
      subtitle: widget.props['subtitle'] as String?,
      submitted: _submitted,
      submittedLabel: _tags.join(', '),
      onSubmit: _canSubmit && !_submitted ? _submit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current tags
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _tags
                  .map((t) => _Tag(
                        label: t,
                        color: cs.primary,
                        onRemove: _submitted ? null : () => _removeTag(t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
          ],

          // Input
          if (!_submitted && !_atMax)
            Row(
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (e) {
                      if (e is KeyDownEvent &&
                          e.logicalKey == LogicalKeyboardKey.enter &&
                          _canAdd) _addTag(_ctrl.text);
                    },
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: const TextStyle(fontSize: 12),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _addTag,
                      decoration: InputDecoration(hintText: _placeholder),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: _canAdd ? () => _addTag(_ctrl.text) : null,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _canAdd
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 16,
                        color: _canAdd
                            ? cs.onPrimary
                            : cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ),
              ],
            ),

          if (_atMax && !_submitted) ...[
            const SizedBox(height: 4),
            Text(
              'Max $_maxTags tags',
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],

          // Suggestions
          if (!_submitted && unused.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Suggestions',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: unused
                  .map((s) => _SuggestionChip(
                        label: s,
                        disabled: _atMax,
                        onTap: () => _addTag(s),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    widget.onSubmit({'tags': List<String>.from(_tags)});
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.onRemove});
  final String label;
  final Color color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(7, 3, onRemove != null ? 3 : 7, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  size: 12, color: color.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip(
      {required this.label, required this.disabled, required this.onTap});
  final String label;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded,
                size: 10,
                color: cs.onSurface
                    .withValues(alpha: disabled ? 0.25 : 0.5)),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface
                        .withValues(alpha: disabled ? 0.25 : 0.65))),
          ],
        ),
      ),
    );
  }
}
