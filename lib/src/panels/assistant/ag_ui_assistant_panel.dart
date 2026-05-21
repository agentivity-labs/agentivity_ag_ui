import 'package:flutter/material.dart';

import '../../widgets/ag_ui_markdown_body.dart';
import 'assistant_controller.dart';
import 'assistant_models.dart';
import 'assistant_theme.dart';

/// A self-contained AI assistant chat panel backed by [AssistantController].
///
/// Styling: add [AgUiAssistantTheme] to [ThemeData.extensions], or pass
/// [style] for a per-widget override. Override individual parts with builders.
class AgUiAssistantPanel extends StatefulWidget {
  const AgUiAssistantPanel({
    super.key,
    required this.controller,
    this.style,
    this.messageBuilder,
    this.inputBuilder,
    this.emptyBuilder,
    this.inputHint = 'Ask the assistant…',
    this.autoCheckHealth = true,
    this.showStatusBar = true,
    this.context,
  });

  final AssistantController controller;

  /// Visual overrides on top of [AgUiAssistantTheme].
  final AgUiAssistantTheme? style;

  /// Replace the default message bubble entirely.
  final Widget Function(AssistantMessage message)? messageBuilder;

  /// Replace the default text input row.
  final Widget Function(void Function(String text) onSend)? inputBuilder;

  final WidgetBuilder? emptyBuilder;
  final String inputHint;

  /// Call [AssistantController.checkHealth] on first build.
  final bool autoCheckHealth;

  /// Show the online/offline status bar at the top.
  final bool showStatusBar;

  /// Optional context forwarded verbatim to the backend on each message.
  final Map<String, dynamic>? context;

  @override
  State<AgUiAssistantPanel> createState() => _AgUiAssistantPanelState();
}

class _AgUiAssistantPanelState extends State<AgUiAssistantPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
    if (widget.autoCheckHealth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.checkHealth();
      });
    }
  }

  @override
  void didUpdateWidget(AgUiAssistantPanel old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _inputController.clear();
    await widget.controller.sendMessage(
      content: trimmed,
      context: widget.context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AgUiAssistantTheme.of(context).copyWith(
      userBubbleColor: widget.style?.userBubbleColor,
      assistantBubbleColor: widget.style?.assistantBubbleColor,
      systemBubbleColor: widget.style?.systemBubbleColor,
      userTextStyle: widget.style?.userTextStyle,
      assistantTextStyle: widget.style?.assistantTextStyle,
      bubbleRadius: widget.style?.bubbleRadius,
      inputDecoration: widget.style?.inputDecoration,
      sendIconColor: widget.style?.sendIconColor,
      typingIndicatorColor: widget.style?.typingIndicatorColor,
      onlineColor: widget.style?.onlineColor,
      offlineColor: widget.style?.offlineColor,
    );

    final ctrl = widget.controller;

    return Column(
      children: [
        if (widget.showStatusBar) _StatusBar(controller: ctrl, theme: theme),
        Expanded(
          child: ctrl.messages.isEmpty
              ? widget.emptyBuilder?.call(context) ??
                  const Center(child: Text('No messages yet.'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount:
                      ctrl.messages.length + (ctrl.isSending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == ctrl.messages.length) {
                      return _TypingIndicator(
                          color: theme.typingIndicatorColor);
                    }
                    final msg = ctrl.messages[i];
                    if (widget.messageBuilder != null) {
                      return widget.messageBuilder!(msg);
                    }
                    return _AssistantBubble(message: msg, theme: theme);
                  },
                ),
        ),
        const Divider(height: 1),
        widget.inputBuilder?.call(_send) ??
            _AssistantInput(
              controller: _inputController,
              hint: widget.inputHint,
              decoration: theme.inputDecoration,
              sendIconColor: theme.sendIconColor,
              enabled: !ctrl.isSending,
              onSend: _send,
            ),
      ],
    );
  }
}

// ── Status bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller, required this.theme});

  final AssistantController controller;
  final AgUiAssistantTheme theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = controller.isOnline;
    final isChecking = controller.isCheckingHealth;

    final Color dot = isChecking
        ? colorScheme.tertiary
        : isOnline
            ? (theme.onlineColor ?? Colors.green)
            : (theme.offlineColor ?? colorScheme.error);

    final String label = isChecking
        ? 'Checking…'
        : isOnline
            ? controller.statusLabel
            : 'Offline';

    return Container(
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          if (controller.lastResponseTokens != null) ...[
            const Spacer(),
            Text('${controller.lastResponseTokens} tokens',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colorScheme.outline)),
          ],
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message, required this.theme});

  final AssistantMessage message;
  final AgUiAssistantTheme theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == AssistantRole.user;
    final isSystem = message.role == AssistantRole.system;

    final Color bg = isUser
        ? (theme.userBubbleColor ?? colorScheme.primaryContainer)
        : isSystem
            ? (theme.systemBubbleColor ?? colorScheme.surfaceContainerHighest)
            : (theme.assistantBubbleColor ?? colorScheme.secondaryContainer);

    final TextStyle? textStyle =
        isUser ? theme.userTextStyle : theme.assistantTextStyle;

    final radius = theme.bubbleRadius ?? BorderRadius.circular(12);

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            child: Text(message.content,
                style: textStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        )),
          ),
        ),
      );
    }

    final useMarkdown = !isUser && message.content.isNotEmpty;
    final textColor = textStyle?.color ??
        (isUser ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: useMarkdown
            ? AgUiMarkdownBody(
                data: message.content,
                textColor: textColor,
                textStyle: textStyle,
                linkColor: colorScheme.primary,
              )
            : Text(message.content, style: textStyle?.copyWith(color: textColor)),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({this.color});
  final Color? color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.outline;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final phase = (_anim.value - delay).clamp(0.0, 1.0);
                final opacity = (0.3 + 0.7 * (phase < 0.5
                        ? phase * 2
                        : (1.0 - phase) * 2))
                    .clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ── Input row ─────────────────────────────────────────────────────────────────

class _AssistantInput extends StatelessWidget {
  const _AssistantInput({
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.enabled,
    this.decoration,
    this.sendIconColor,
  });

  final TextEditingController controller;
  final String hint;
  final void Function(String) onSend;
  final bool enabled;
  final InputDecoration? decoration;
  final Color? sendIconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: decoration ??
                  InputDecoration(
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
              onSubmitted: enabled ? onSend : null,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send,
                color: enabled
                    ? (sendIconColor ??
                        Theme.of(context).colorScheme.primary)
                    : Theme.of(context).colorScheme.outline),
            onPressed: enabled ? () => onSend(controller.text) : null,
          ),
        ],
      ),
    );
  }
}
