import 'package:flutter/material.dart';

import '../widgets/ag_ui_markdown_body.dart';
import '../tools/ag_ui_widget_registry.dart';
import 'ag_ui_generative_controller.dart';

/// Renders a live conversation driven by [AgUiGenerativeController].
///
/// Items appear in stream order: text bubbles, reasoning blocks, inline
/// components (from [AgUiWidgetRegistry]), tool-call status cards, and
/// agent-generated HTML blocks ([AgUiHtmlItem]).
///
/// Customize rendering at four levels:
/// - **[registry]**: resolves component names → Flutter widgets (generative UI)
/// - **[itemBuilder]**: replace the rendering of any [AgUiGenerativeItem]
/// - **[toolCallBuilder] / [fallbackBuilder]**: override specific item types
/// - **[htmlBuilder]**: render agent-generated HTML (provide a WebView widget)
class AgUiGenerativeView extends StatelessWidget {
  const AgUiGenerativeView({
    super.key,
    required this.controller,
    required this.registry,
    this.itemBuilder,
    this.toolCallBuilder,
    this.fallbackBuilder,
    this.htmlBuilder,
    this.emptyBuilder,
    this.padding,
    this.reverse = false,
  });

  final AgUiGenerativeController controller;
  final AgUiWidgetRegistry registry;

  /// Full override — replaces rendering of any item type.
  final Widget Function(AgUiGenerativeItem item)? itemBuilder;

  /// Override only tool-call items.
  final Widget Function(AgUiToolCallItem item)? toolCallBuilder;

  /// Called when a component name is not in [registry].
  final Widget Function(
    BuildContext context,
    String component,
    Map<String, dynamic> props,
  )? fallbackBuilder;

  /// Renders agent-generated HTML ([AgUiHtmlItem]).
  ///
  /// Provide a WebView-based implementation to display the HTML:
  /// ```dart
  /// htmlBuilder: (item) => SizedBox(
  ///   height: item.height ?? 300,
  ///   child: WebViewWidget(controller: _buildWebView(item.html)),
  /// )
  /// ```
  /// When `null`, a labelled placeholder is shown instead.
  final Widget Function(AgUiHtmlItem item)? htmlBuilder;

  final WidgetBuilder? emptyBuilder;
  final EdgeInsetsGeometry? padding;

  /// If `true`, newest items appear at the bottom (ListView reversed).
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        if (items.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }
        return ListView.builder(
          padding: padding ?? const EdgeInsets.all(12),
          reverse: reverse,
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            if (itemBuilder != null) return itemBuilder!(item);
            return _buildItem(context, item);
          },
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, AgUiGenerativeItem item) {
    return switch (item) {
      AgUiTextItem e => _TextBubble(item: e),
      AgUiReasoningItem e => _ReasoningBlock(item: e),
      AgUiComponentItem e => _buildComponent(context, e),
      AgUiToolCallItem e => toolCallBuilder?.call(e) ?? _ToolCallCard(item: e),
      AgUiHtmlItem e => htmlBuilder?.call(e) ?? _HtmlPlaceholder(item: e),
    };
  }

  Widget _buildComponent(BuildContext context, AgUiComponentItem item) {
    final widget = registry.build(context, item.component, item.props);
    if (widget != null) return widget;
    return fallbackBuilder?.call(context, item.component, item.props) ??
        _UnknownComponent(name: item.component);
  }
}

// ── Text bubble ───────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.item});
  final AgUiTextItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = item.role == 'user';

    final Color bg = isUser
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;

    // Render markdown only for assistant messages that have finished streaming.
    // Partial markdown (mid-stream) causes broken layouts — keep plain Text
    // while streaming, exactly as the studio does with enableMarkdownStreaming:false.
    final useMarkdown = !isUser && !item.isStreaming && item.text.isNotEmpty;

    final textColor = isUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: useMarkdown
            ? AgUiMarkdownBody(
                data: item.text,
                textColor: textColor,
                linkColor: colorScheme.primary,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: Text(item.text, style: TextStyle(color: textColor))),
                  if (item.isStreaming) ...[
                    const SizedBox(width: 6),
                    _StreamingDot(),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Reasoning block ───────────────────────────────────────────────────────────

class _ReasoningBlock extends StatefulWidget {
  const _ReasoningBlock({required this.item});
  final AgUiReasoningItem item;

  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.psychology_outlined,
                        size: 16, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Text('Thinking',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colorScheme.outline)),
                    if (widget.item.isStreaming) ...[
                      const SizedBox(width: 8),
                      _StreamingDot(),
                    ],
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  widget.item.text,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tool call card ────────────────────────────────────────────────────────────

class _ToolCallCard extends StatelessWidget {
  const _ToolCallCard({required this.item});
  final AgUiToolCallItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color, label) = switch (item.status) {
      AgUiToolCallStatus.pending => (
          Icons.more_horiz,
          colorScheme.outline,
          'Calling ${item.toolCallName}…'
        ),
      AgUiToolCallStatus.running => (
          Icons.sync,
          colorScheme.primary,
          'Running ${item.toolCallName}…'
        ),
      AgUiToolCallStatus.completed => (
          Icons.check_circle_outline,
          Colors.green,
          item.toolCallName
        ),
      AgUiToolCallStatus.failed => (
          Icons.error_outline,
          colorScheme.error,
          item.toolCallName
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                item.status == AgUiToolCallStatus.running
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: color),
                      )
                    : Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: color)),
                ),
              ],
            ),
            if (item.error != null) ...[
              const SizedBox(height: 4),
              Text(item.error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.error)),
            ],
            if (item.result != null &&
                item.status == AgUiToolCallStatus.completed) ...[
              const SizedBox(height: 4),
              Text(
                item.result.toString().length > 120
                    ? '${item.result.toString().substring(0, 120)}…'
                    : item.result.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Unknown component placeholder ─────────────────────────────────────────────

class _UnknownComponent extends StatelessWidget {
  const _UnknownComponent({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.widgets_outlined,
              size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text('Unregistered component: $name',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}

// ── HTML placeholder ──────────────────────────────────────────────────────────

class _HtmlPlaceholder extends StatelessWidget {
  const _HtmlPlaceholder({required this.item});
  final AgUiHtmlItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      height: item.height,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          Icon(Icons.html, size: 16, color: colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'HTML content — provide htmlBuilder to render.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streaming dot ─────────────────────────────────────────────────────────────

class _StreamingDot extends StatefulWidget {
  @override
  State<_StreamingDot> createState() => _StreamingDotState();
}

class _StreamingDotState extends State<_StreamingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 1.0).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
