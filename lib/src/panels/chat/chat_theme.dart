import 'package:flutter/material.dart';

class AgUiChatTheme extends ThemeExtension<AgUiChatTheme> {
  const AgUiChatTheme({
    this.userBubbleColor,
    this.assistantBubbleColor,
    this.systemBubbleColor,
    this.userTextStyle,
    this.assistantTextStyle,
    this.bubbleRadius,
    this.inputDecoration,
    this.sendIconColor,
  });

  final Color? userBubbleColor;
  final Color? assistantBubbleColor;
  final Color? systemBubbleColor;
  final TextStyle? userTextStyle;
  final TextStyle? assistantTextStyle;
  final BorderRadius? bubbleRadius;
  final InputDecoration? inputDecoration;
  final Color? sendIconColor;

  static AgUiChatTheme of(BuildContext context) {
    return Theme.of(context).extension<AgUiChatTheme>() ??
        const AgUiChatTheme();
  }

  @override
  AgUiChatTheme copyWith({
    Color? userBubbleColor,
    Color? assistantBubbleColor,
    Color? systemBubbleColor,
    TextStyle? userTextStyle,
    TextStyle? assistantTextStyle,
    BorderRadius? bubbleRadius,
    InputDecoration? inputDecoration,
    Color? sendIconColor,
  }) {
    return AgUiChatTheme(
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      assistantBubbleColor: assistantBubbleColor ?? this.assistantBubbleColor,
      systemBubbleColor: systemBubbleColor ?? this.systemBubbleColor,
      userTextStyle: userTextStyle ?? this.userTextStyle,
      assistantTextStyle: assistantTextStyle ?? this.assistantTextStyle,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
      inputDecoration: inputDecoration ?? this.inputDecoration,
      sendIconColor: sendIconColor ?? this.sendIconColor,
    );
  }

  @override
  AgUiChatTheme lerp(AgUiChatTheme? other, double t) {
    if (other == null) return this;
    return AgUiChatTheme(
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
    );
  }
}
