import 'package:flutter/material.dart';

import '../../theme/ag_theme_data.dart';
import '../../widgets/ag_ui_markdown_body.dart';
import 'chat_controller.dart';
import 'chat_models.dart';

/// A self-contained chat panel backed by a [ChatController].
///
/// Styling: add [AgThemeData] to your [ThemeData.extensions], or pass
/// [style] for a one-off override. Override individual parts with builders.
class AgUiChatPanel extends StatefulWidget {
  const AgUiChatPanel({
    super.key,
    required this.controller,
    required this.threadId,
    this.style,
    this.messageBuilder,
    this.inputBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.inputHint = 'Type a message…',
    this.autoLoad = true,
    this.onAttach,
  });

  final ChatController controller;

  /// The thread to display. Pass `null` to show the thread list instead.
  final String? threadId;

  /// Visual overrides on top of [AgThemeData].
  final AgThemeData? style;

  /// Replace the default message bubble entirely.
  final Widget Function(ChatMessage message)? messageBuilder;

  /// Replace the default text input row.
  final Widget Function(void Function(String text) onSend)? inputBuilder;

  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final String inputHint;

  /// Call [ChatController.loadThreads] on first build.
  final bool autoLoad;

  /// Called when the user taps the attachment button. Should return a list of
  /// attachments chosen by the user, or `null` if the picker was cancelled.
  ///
  /// When non-null, an attachment icon button appears in the input bar.
  /// Use any file/image picker package in the callback:
  /// ```dart
  /// onAttach: (context) async {
  ///   final result = await ImagePicker().pickImage(source: ImageSource.gallery);
  ///   if (result == null) return null;
  ///   return [ImageBytesAttachment(bytes: await result.readAsBytes(), name: result.name)];
  /// }
  /// ```
  final Future<List<ChatAttachment>?> Function(BuildContext context)? onAttach;

  @override
  State<AgUiChatPanel> createState() => _AgUiChatPanelState();
}

class _AgUiChatPanelState extends State<AgUiChatPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = const [];
  List<ChatAttachment> _pendingAttachments = const [];
  bool _loadingMessages = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMessages();
      });
    }
  }

  @override
  void didUpdateWidget(AgUiChatPanel old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
    if (old.threadId != widget.threadId) _loadMessages();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChange() => setState(() {});

  Future<void> _loadMessages() async {
    final threadId = widget.threadId;
    if (threadId == null) return;
    setState(() => _loadingMessages = true);
    try {
      final detail = await widget.controller.openThread(threadId: threadId);
      if (mounted) setState(() => _messages = detail.messages);
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
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
    final attachments = List<ChatAttachment>.from(_pendingAttachments);
    if (trimmed.isEmpty && attachments.isEmpty) return;
    _inputController.clear();
    if (mounted) setState(() => _pendingAttachments = const []);
    await widget.controller.sendMessage(
      threadId: widget.threadId,
      text: trimmed,
      attachments: attachments.isEmpty ? null : attachments,
    );
    await _loadMessages();
  }

  Future<void> _pickAttachments() async {
    final picked = await widget.onAttach?.call(context);
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _pendingAttachments = [..._pendingAttachments, ...picked]);
    }
  }

  void _removeAttachment(int index) {
    final updated = List<ChatAttachment>.from(_pendingAttachments)..removeAt(index);
    setState(() => _pendingAttachments = updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final theme = AgThemeData.of(context).copyWith(
      bubbleUserColor:      s?.bubbleUserColor,
      bubbleAgentColor:     s?.bubbleAgentColor,
      bubbleSystemColor:    s?.bubbleSystemColor,
      bubbleUserTextStyle:  s?.bubbleUserTextStyle,
      bubbleAgentTextStyle: s?.bubbleAgentTextStyle,
      bubbleRadius:         s?.bubbleRadius,
      inputDecoration:      s?.inputDecoration,
      sendIconColor:        s?.sendIconColor,
    );

    if (_loadingMessages) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('No messages yet.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final msg = _messages[i];
              if (widget.messageBuilder != null) {
                return widget.messageBuilder!(msg);
              }
              return _MessageBubble(message: msg, theme: theme);
            },
          ),
        ),
        const Divider(height: 1),
        if (_pendingAttachments.isNotEmpty)
          _AttachmentChips(
            attachments: _pendingAttachments,
            onRemove: _removeAttachment,
          ),
        widget.inputBuilder?.call(_send) ??
            _DefaultInput(
              controller: _inputController,
              hint: widget.inputHint,
              decoration: theme.inputDecoration,
              sendIconColor: theme.sendIconColor,
              onSend: _send,
              onAttach: widget.onAttach != null ? _pickAttachments : null,
            ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.theme});

  final ChatMessage message;
  final AgThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == ChatMessageRole.user;
    final isSystem = message.role == ChatMessageRole.system;

    final Color bg = isUser
        ? (theme.bubbleUserColor ?? colorScheme.primaryContainer)
        : isSystem
            ? (theme.bubbleSystemColor ?? colorScheme.surfaceContainerHighest)
            : (theme.bubbleAgentColor ?? colorScheme.secondaryContainer);

    final TextStyle? textStyle =
        isUser ? theme.bubbleUserTextStyle : theme.bubbleAgentTextStyle;

    final radius = BorderRadius.circular(theme.bubbleRadius);

    final useMarkdown = !isUser && !isSystem && message.text.isNotEmpty;
    final textColor = textStyle?.color ?? Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: theme.gap4),
        padding: EdgeInsets.symmetric(
            horizontal: theme.bubblePaddingH, vertical: theme.bubblePaddingV),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: useMarkdown
            ? AgUiMarkdownBody(
                data: message.text,
                textColor: textColor,
                textStyle: textStyle,
              )
            : Text(message.text, style: textStyle),
      ),
    );
  }
}

class _DefaultInput extends StatelessWidget {
  const _DefaultInput({
    required this.controller,
    required this.hint,
    required this.onSend,
    this.decoration,
    this.sendIconColor,
    this.onAttach,
  });

  final TextEditingController controller;
  final String hint;
  final void Function(String) onSend;
  final InputDecoration? decoration;
  final Color? sendIconColor;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (onAttach != null)
            IconButton(
              icon: const Icon(Icons.attach_file),
              tooltip: 'Add attachment',
              onPressed: onAttach,
            ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: decoration ??
                  InputDecoration(
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
              onSubmitted: onSend,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send,
                color: sendIconColor ?? Theme.of(context).colorScheme.primary),
            onPressed: () => onSend(controller.text),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChips extends StatelessWidget {
  const _AttachmentChips({required this.attachments, required this.onRemove});

  final List<ChatAttachment> attachments;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (var i = 0; i < attachments.length; i++)
            Chip(
              avatar: Icon(_icon(attachments[i]), size: 16),
              label: Text(
                _label(attachments[i]),
                style: Theme.of(context).textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => onRemove(i),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  String _label(ChatAttachment a) => switch (a) {
        ImageUrlAttachment e => e.name ?? 'Image',
        ImageBytesAttachment e => e.name ?? 'Image',
        FileAttachment e => e.name ?? 'File',
      };

  IconData _icon(ChatAttachment a) => switch (a) {
        ImageUrlAttachment _ || ImageBytesAttachment _ => Icons.image_outlined,
        FileAttachment _ => Icons.attach_file,
      };
}
