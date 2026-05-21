import 'package:flutter/material.dart';

class AgUiFormTheme extends ThemeExtension<AgUiFormTheme> {
  const AgUiFormTheme({
    this.cardColor,
    this.titleStyle,
    this.descriptionStyle,
    this.approveColor,
    this.rejectColor,
    this.submitColor,
    this.fieldLabelStyle,
    this.borderRadius,
  });

  final Color? cardColor;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final Color? approveColor;
  final Color? rejectColor;
  final Color? submitColor;
  final TextStyle? fieldLabelStyle;
  final BorderRadius? borderRadius;

  static AgUiFormTheme of(BuildContext context) {
    return Theme.of(context).extension<AgUiFormTheme>() ?? const AgUiFormTheme();
  }

  @override
  AgUiFormTheme copyWith({
    Color? cardColor,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    Color? approveColor,
    Color? rejectColor,
    Color? submitColor,
    TextStyle? fieldLabelStyle,
    BorderRadius? borderRadius,
  }) {
    return AgUiFormTheme(
      cardColor: cardColor ?? this.cardColor,
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      approveColor: approveColor ?? this.approveColor,
      rejectColor: rejectColor ?? this.rejectColor,
      submitColor: submitColor ?? this.submitColor,
      fieldLabelStyle: fieldLabelStyle ?? this.fieldLabelStyle,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  AgUiFormTheme lerp(AgUiFormTheme? other, double t) {
    if (other == null) return this;
    return AgUiFormTheme(
      cardColor: Color.lerp(cardColor, other.cardColor, t),
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      descriptionStyle:
          TextStyle.lerp(descriptionStyle, other.descriptionStyle, t),
      approveColor: Color.lerp(approveColor, other.approveColor, t),
      rejectColor: Color.lerp(rejectColor, other.rejectColor, t),
      submitColor: Color.lerp(submitColor, other.submitColor, t),
      fieldLabelStyle:
          TextStyle.lerp(fieldLabelStyle, other.fieldLabelStyle, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t),
    );
  }
}
