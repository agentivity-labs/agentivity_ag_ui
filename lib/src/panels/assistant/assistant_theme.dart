import 'package:flutter/material.dart';

class AgUiAssistantTheme extends ThemeExtension<AgUiAssistantTheme> {
  const AgUiAssistantTheme({
    this.userBubbleColor,
    this.assistantBubbleColor,
    this.systemBubbleColor,
    this.userTextStyle,
    this.assistantTextStyle,
    this.bubbleRadius,
    this.inputDecoration,
    this.sendIconColor,
    this.typingIndicatorColor,
    this.onlineColor,
    this.offlineColor,
  });

  final Color? userBubbleColor;
  final Color? assistantBubbleColor;
  final Color? systemBubbleColor;
  final TextStyle? userTextStyle;
  final TextStyle? assistantTextStyle;
  final BorderRadius? bubbleRadius;
  final InputDecoration? inputDecoration;
  final Color? sendIconColor;
  final Color? typingIndicatorColor;
  final Color? onlineColor;
  final Color? offlineColor;

  static AgUiAssistantTheme of(BuildContext context) {
    return Theme.of(context).extension<AgUiAssistantTheme>() ??
        const AgUiAssistantTheme();
  }

  @override
  AgUiAssistantTheme copyWith({
    Color? userBubbleColor,
    Color? assistantBubbleColor,
    Color? systemBubbleColor,
    TextStyle? userTextStyle,
    TextStyle? assistantTextStyle,
    BorderRadius? bubbleRadius,
    InputDecoration? inputDecoration,
    Color? sendIconColor,
    Color? typingIndicatorColor,
    Color? onlineColor,
    Color? offlineColor,
  }) {
    return AgUiAssistantTheme(
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      assistantBubbleColor: assistantBubbleColor ?? this.assistantBubbleColor,
      systemBubbleColor: systemBubbleColor ?? this.systemBubbleColor,
      userTextStyle: userTextStyle ?? this.userTextStyle,
      assistantTextStyle: assistantTextStyle ?? this.assistantTextStyle,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
      inputDecoration: inputDecoration ?? this.inputDecoration,
      sendIconColor: sendIconColor ?? this.sendIconColor,
      typingIndicatorColor: typingIndicatorColor ?? this.typingIndicatorColor,
      onlineColor: onlineColor ?? this.onlineColor,
      offlineColor: offlineColor ?? this.offlineColor,
    );
  }

  @override
  AgUiAssistantTheme lerp(AgUiAssistantTheme? other, double t) {
    if (other == null) return this;
    return AgUiAssistantTheme(
      userBubbleColor: Color.lerp(userBubbleColor, other.userBubbleColor, t),
      assistantBubbleColor:
          Color.lerp(assistantBubbleColor, other.assistantBubbleColor, t),
      systemBubbleColor:
          Color.lerp(systemBubbleColor, other.systemBubbleColor, t),
      userTextStyle: TextStyle.lerp(userTextStyle, other.userTextStyle, t),
      assistantTextStyle:
          TextStyle.lerp(assistantTextStyle, other.assistantTextStyle, t),
      bubbleRadius: BorderRadius.lerp(bubbleRadius, other.bubbleRadius, t),
      inputDecoration: t < 0.5 ? inputDecoration : other.inputDecoration,
      sendIconColor: Color.lerp(sendIconColor, other.sendIconColor, t),
      typingIndicatorColor:
          Color.lerp(typingIndicatorColor, other.typingIndicatorColor, t),
      onlineColor: Color.lerp(onlineColor, other.onlineColor, t),
      offlineColor: Color.lerp(offlineColor, other.offlineColor, t),
    );
  }
}
