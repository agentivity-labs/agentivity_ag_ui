import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Unified design-token ThemeExtension for the entire Agentivity widget stack.
///
/// A single [AgThemeData] instance covers chat bubbles, streaming, runnable
/// widgets, HIL forms, assistant presence, sidebar shell, and all typography /
/// spacing / icon-size multipliers — replacing the former per-package split
/// (`AgUiChatTheme`, `AgUiAssistantTheme`, `AgUiFormTheme`, `AgKitThemeData`).
///
/// **Injection** — place it in your [ThemeData.extensions]:
/// ```dart
/// MaterialApp(theme: AgKitThemes.themeDataFor('Agentivity Light'))
/// // or, with preferences:
/// MaterialApp(theme: prefs.themeData)
/// ```
///
/// **Reading** — in any widget:
/// ```dart
/// final theme = AgThemeData.of(context);
/// // or
/// final theme = context.agTheme;
/// ```
///
/// ## Scale multipliers
///
/// | Field          | Default | Effect                                    |
/// |----------------|---------|-------------------------------------------|
/// | [fontScale]    | 1.0     | Multiplies every font-size helper.        |
/// | [spacingScale] | 1.0     | Multiplies every gap helper.              |
///
/// Use the named helpers ([textBase], [gap8], etc.) instead of raw numbers so
/// every widget automatically respects the user's density preference.
@immutable
class AgThemeData extends ThemeExtension<AgThemeData> {
  const AgThemeData({
    // ── Chat bubbles ──────────────────────────────────────────────────────────
    this.bubbleUserColor,
    this.bubbleUserTextColor,
    this.bubbleAgentColor,
    this.bubbleAgentTextColor,
    this.bubbleSystemColor,
    this.bubbleSystemTextColor,
    this.bubbleRadius = 16.0,
    this.bubblePaddingH = 14.0,
    this.bubblePaddingV = 10.0,
    /// Optional full TextStyle for user message text (fontScale applied via
    /// [effectiveBubbleUserTextStyle]).
    this.bubbleUserTextStyle,
    /// Optional full TextStyle for agent message text.
    this.bubbleAgentTextStyle,

    // ── Chat input ────────────────────────────────────────────────────────────
    this.inputDecoration,
    this.sendIconColor,

    // ── Streaming ─────────────────────────────────────────────────────────────
    this.streamingColor,

    // ── Runnable ──────────────────────────────────────────────────────────────
    this.runnableAccentColor,
    this.runnableAvatarRadius = 10.0,

    // ── HIL ───────────────────────────────────────────────────────────────────
    this.hilColor,
    this.hilBorderWidth = 2.0,

    // ── HIL / Form panel ─────────────────────────────────────────────────────
    this.formCardColor,
    this.formApproveColor,
    this.formRejectColor,
    this.formSubmitColor,
    this.formTitleStyle,
    this.formDescriptionStyle,
    this.formFieldLabelStyle,
    this.formBorderRadius,

    // ── Assistant presence ────────────────────────────────────────────────────
    this.typingIndicatorColor,
    this.onlineColor,
    this.offlineColor,

    // ── Shell / Sidebar ───────────────────────────────────────────────────────
    this.sidebarWidth = 240.0,
    this.sidebarColor,

    // ── Shared shape ──────────────────────────────────────────────────────────
    this.cardRadius = 12.0,
    this.fontFamily,

    // ── Typography scale ──────────────────────────────────────────────────────
    this.fontScale = 1.0,
    this.bodyLineHeight = 1.5,

    // ── Spacing scale ─────────────────────────────────────────────────────────
    this.spacingScale = 1.0,

    // ── Icon sizes ────────────────────────────────────────────────────────────
    this.iconSizeSm = 12.0,
    this.iconSizeMd = 15.0,
  });

  // ── Bubble ──────────────────────────────────────────────────────────────────
  final Color? bubbleUserColor;
  final Color? bubbleUserTextColor;
  final Color? bubbleAgentColor;
  final Color? bubbleAgentTextColor;
  final Color? bubbleSystemColor;
  final Color? bubbleSystemTextColor;
  final double bubbleRadius;
  final double bubblePaddingH;
  final double bubblePaddingV;
  final TextStyle? bubbleUserTextStyle;
  final TextStyle? bubbleAgentTextStyle;

  // ── Chat input ───────────────────────────────────────────────────────────────
  final InputDecoration? inputDecoration;
  final Color? sendIconColor;

  // ── Streaming ────────────────────────────────────────────────────────────────
  final Color? streamingColor;

  // ── Runnable ─────────────────────────────────────────────────────────────────
  final Color? runnableAccentColor;
  final double runnableAvatarRadius;

  // ── HIL ──────────────────────────────────────────────────────────────────────
  final Color? hilColor;
  final double hilBorderWidth;

  // ── Form panel ───────────────────────────────────────────────────────────────
  final Color? formCardColor;
  final Color? formApproveColor;
  final Color? formRejectColor;
  final Color? formSubmitColor;
  final TextStyle? formTitleStyle;
  final TextStyle? formDescriptionStyle;
  final TextStyle? formFieldLabelStyle;
  final BorderRadius? formBorderRadius;

  // ── Assistant presence ───────────────────────────────────────────────────────
  final Color? typingIndicatorColor;
  final Color? onlineColor;
  final Color? offlineColor;

  // ── Shell ────────────────────────────────────────────────────────────────────
  final double sidebarWidth;
  final Color? sidebarColor;

  // ── Shape / typography / spacing ─────────────────────────────────────────────
  final double cardRadius;
  final String? fontFamily;

  /// Font-size multiplier (1.0 = default sizes).
  final double fontScale;

  /// Line-height for body text and markdown paragraphs.
  final double bodyLineHeight;

  /// Spacing multiplier (1.0 = default gaps).
  final double spacingScale;

  /// Small inline icon size (clips, badges, timestamps).
  final double iconSizeSm;

  /// Medium card-level icon size (tool-call status, reasoning header).
  final double iconSizeMd;

  // ── Computed text-style helpers ──────────────────────────────────────────────

  static const double _defaultBodySize = 14.0;

  /// User bubble text style with [fontScale] applied.
  TextStyle get effectiveBubbleUserTextStyle {
    final base = bubbleUserTextStyle;
    final size = (base?.fontSize ?? _defaultBodySize) * fontScale;
    return (base ?? const TextStyle()).copyWith(fontSize: size);
  }

  /// Agent bubble text style with [fontScale] applied.
  TextStyle get effectiveBubbleAgentTextStyle {
    final base = bubbleAgentTextStyle;
    final size = (base?.fontSize ?? _defaultBodySize) * fontScale;
    return (base ?? const TextStyle()).copyWith(fontSize: size);
  }

  /// Form title style with [fontScale] applied (default 16 sp w600).
  TextStyle get effectiveFormTitleStyle {
    const defaultSize = 16.0;
    final base = formTitleStyle;
    final size = (base?.fontSize ?? defaultSize) * fontScale;
    return (base ?? const TextStyle(fontSize: defaultSize, fontWeight: FontWeight.w600))
        .copyWith(fontSize: size);
  }

  /// Form description/body style with [fontScale] applied (default 14 sp).
  TextStyle get effectiveFormDescriptionStyle {
    const defaultSize = 14.0;
    final base = formDescriptionStyle;
    final size = (base?.fontSize ?? defaultSize) * fontScale;
    return (base ?? const TextStyle(fontSize: defaultSize)).copyWith(fontSize: size);
  }

  /// Form field-label style with [fontScale] applied (default 12 sp w600).
  TextStyle get effectiveFormFieldLabelStyle {
    const defaultSize = 12.0;
    final base = formFieldLabelStyle;
    final size = (base?.fontSize ?? defaultSize) * fontScale;
    return (base ?? const TextStyle(fontSize: defaultSize, fontWeight: FontWeight.w600))
        .copyWith(fontSize: size);
  }

  // ── Font-size helpers ────────────────────────────────────────────────────────

  /// Scales an arbitrary [base] font size by [fontScale].
  double fontSize(double base) => base * fontScale;

  /// 10 px — micro labels, timestamps.
  double get textXs => 10 * fontScale;

  /// 11 px — secondary labels, captions.
  double get textXxs => 11 * fontScale;

  /// 12 px — secondary text, hints.
  double get textSm => 12 * fontScale;

  /// 13 px — slightly larger secondary text, agent name row.
  double get textSmPlus => 13 * fontScale;

  /// 14 px — body / default text.
  double get textBase => 14 * fontScale;

  /// 16 px — subtitles, card titles.
  double get textLg => 16 * fontScale;

  /// 20 px — section headings.
  double get textXl => 20 * fontScale;

  /// 24 px — page headings.
  double get text2xl => 24 * fontScale;

  // ── Spacing helpers ──────────────────────────────────────────────────────────

  /// Scales an arbitrary [base] spacing value by [spacingScale].
  double spacing(double base) => base * spacingScale;

  double get gap2  =>  2 * spacingScale;
  double get gap4  =>  4 * spacingScale;
  double get gap6  =>  6 * spacingScale;
  double get gap8  =>  8 * spacingScale;
  double get gap10 => 10 * spacingScale;
  double get gap12 => 12 * spacingScale;
  double get gap14 => 14 * spacingScale;
  double get gap16 => 16 * spacingScale;
  double get gap20 => 20 * spacingScale;
  double get gap24 => 24 * spacingScale;
  double get gap32 => 32 * spacingScale;
  double get gap48 => 48 * spacingScale;

  // ── Static accessor ──────────────────────────────────────────────────────────

  /// Reads the nearest [AgThemeData] from [context].
  /// Returns a default instance if none is registered.
  static AgThemeData of(BuildContext context) =>
      Theme.of(context).extension<AgThemeData>() ?? const AgThemeData();

  // ── ThemeExtension ───────────────────────────────────────────────────────────

  @override
  AgThemeData copyWith({
    Color? bubbleUserColor,
    Color? bubbleUserTextColor,
    Color? bubbleAgentColor,
    Color? bubbleAgentTextColor,
    Color? bubbleSystemColor,
    Color? bubbleSystemTextColor,
    double? bubbleRadius,
    double? bubblePaddingH,
    double? bubblePaddingV,
    TextStyle? bubbleUserTextStyle,
    TextStyle? bubbleAgentTextStyle,
    InputDecoration? inputDecoration,
    Color? sendIconColor,
    Color? streamingColor,
    Color? runnableAccentColor,
    double? runnableAvatarRadius,
    Color? hilColor,
    double? hilBorderWidth,
    Color? formCardColor,
    Color? formApproveColor,
    Color? formRejectColor,
    Color? formSubmitColor,
    TextStyle? formTitleStyle,
    TextStyle? formDescriptionStyle,
    TextStyle? formFieldLabelStyle,
    BorderRadius? formBorderRadius,
    Color? typingIndicatorColor,
    Color? onlineColor,
    Color? offlineColor,
    double? sidebarWidth,
    Color? sidebarColor,
    double? cardRadius,
    String? fontFamily,
    double? fontScale,
    double? bodyLineHeight,
    double? spacingScale,
    double? iconSizeSm,
    double? iconSizeMd,
  }) {
    return AgThemeData(
      bubbleUserColor:       bubbleUserColor       ?? this.bubbleUserColor,
      bubbleUserTextColor:   bubbleUserTextColor   ?? this.bubbleUserTextColor,
      bubbleAgentColor:      bubbleAgentColor      ?? this.bubbleAgentColor,
      bubbleAgentTextColor:  bubbleAgentTextColor  ?? this.bubbleAgentTextColor,
      bubbleSystemColor:     bubbleSystemColor     ?? this.bubbleSystemColor,
      bubbleSystemTextColor: bubbleSystemTextColor ?? this.bubbleSystemTextColor,
      bubbleRadius:          bubbleRadius          ?? this.bubbleRadius,
      bubblePaddingH:        bubblePaddingH        ?? this.bubblePaddingH,
      bubblePaddingV:        bubblePaddingV        ?? this.bubblePaddingV,
      bubbleUserTextStyle:   bubbleUserTextStyle   ?? this.bubbleUserTextStyle,
      bubbleAgentTextStyle:  bubbleAgentTextStyle  ?? this.bubbleAgentTextStyle,
      inputDecoration:       inputDecoration       ?? this.inputDecoration,
      sendIconColor:         sendIconColor         ?? this.sendIconColor,
      streamingColor:        streamingColor        ?? this.streamingColor,
      runnableAccentColor:   runnableAccentColor   ?? this.runnableAccentColor,
      runnableAvatarRadius:  runnableAvatarRadius  ?? this.runnableAvatarRadius,
      hilColor:              hilColor              ?? this.hilColor,
      hilBorderWidth:        hilBorderWidth        ?? this.hilBorderWidth,
      formCardColor:         formCardColor         ?? this.formCardColor,
      formApproveColor:      formApproveColor      ?? this.formApproveColor,
      formRejectColor:       formRejectColor       ?? this.formRejectColor,
      formSubmitColor:       formSubmitColor       ?? this.formSubmitColor,
      formTitleStyle:        formTitleStyle        ?? this.formTitleStyle,
      formDescriptionStyle:  formDescriptionStyle  ?? this.formDescriptionStyle,
      formFieldLabelStyle:   formFieldLabelStyle   ?? this.formFieldLabelStyle,
      formBorderRadius:      formBorderRadius      ?? this.formBorderRadius,
      typingIndicatorColor:  typingIndicatorColor  ?? this.typingIndicatorColor,
      onlineColor:           onlineColor           ?? this.onlineColor,
      offlineColor:          offlineColor          ?? this.offlineColor,
      sidebarWidth:          sidebarWidth          ?? this.sidebarWidth,
      sidebarColor:          sidebarColor          ?? this.sidebarColor,
      cardRadius:            cardRadius            ?? this.cardRadius,
      fontFamily:            fontFamily            ?? this.fontFamily,
      fontScale:             fontScale             ?? this.fontScale,
      bodyLineHeight:        bodyLineHeight        ?? this.bodyLineHeight,
      spacingScale:          spacingScale          ?? this.spacingScale,
      iconSizeSm:            iconSizeSm            ?? this.iconSizeSm,
      iconSizeMd:            iconSizeMd            ?? this.iconSizeMd,
    );
  }

  @override
  AgThemeData lerp(AgThemeData? other, double t) {
    if (other == null) return this;
    return AgThemeData(
      bubbleUserColor:       Color.lerp(bubbleUserColor, other.bubbleUserColor, t),
      bubbleUserTextColor:   Color.lerp(bubbleUserTextColor, other.bubbleUserTextColor, t),
      bubbleAgentColor:      Color.lerp(bubbleAgentColor, other.bubbleAgentColor, t),
      bubbleAgentTextColor:  Color.lerp(bubbleAgentTextColor, other.bubbleAgentTextColor, t),
      bubbleSystemColor:     Color.lerp(bubbleSystemColor, other.bubbleSystemColor, t),
      bubbleSystemTextColor: Color.lerp(bubbleSystemTextColor, other.bubbleSystemTextColor, t),
      bubbleRadius:          lerpDouble(bubbleRadius, other.bubbleRadius, t)!,
      bubblePaddingH:        lerpDouble(bubblePaddingH, other.bubblePaddingH, t)!,
      bubblePaddingV:        lerpDouble(bubblePaddingV, other.bubblePaddingV, t)!,
      bubbleUserTextStyle:   TextStyle.lerp(bubbleUserTextStyle, other.bubbleUserTextStyle, t),
      bubbleAgentTextStyle:  TextStyle.lerp(bubbleAgentTextStyle, other.bubbleAgentTextStyle, t),
      inputDecoration:       t < 0.5 ? inputDecoration : other.inputDecoration,
      sendIconColor:         Color.lerp(sendIconColor, other.sendIconColor, t),
      streamingColor:        Color.lerp(streamingColor, other.streamingColor, t),
      runnableAccentColor:   Color.lerp(runnableAccentColor, other.runnableAccentColor, t),
      runnableAvatarRadius:  lerpDouble(runnableAvatarRadius, other.runnableAvatarRadius, t)!,
      hilColor:              Color.lerp(hilColor, other.hilColor, t),
      hilBorderWidth:        lerpDouble(hilBorderWidth, other.hilBorderWidth, t)!,
      formCardColor:         Color.lerp(formCardColor, other.formCardColor, t),
      formApproveColor:      Color.lerp(formApproveColor, other.formApproveColor, t),
      formRejectColor:       Color.lerp(formRejectColor, other.formRejectColor, t),
      formSubmitColor:       Color.lerp(formSubmitColor, other.formSubmitColor, t),
      formTitleStyle:        TextStyle.lerp(formTitleStyle, other.formTitleStyle, t),
      formDescriptionStyle:  TextStyle.lerp(formDescriptionStyle, other.formDescriptionStyle, t),
      formFieldLabelStyle:   TextStyle.lerp(formFieldLabelStyle, other.formFieldLabelStyle, t),
      formBorderRadius:      BorderRadius.lerp(formBorderRadius, other.formBorderRadius, t),
      typingIndicatorColor:  Color.lerp(typingIndicatorColor, other.typingIndicatorColor, t),
      onlineColor:           Color.lerp(onlineColor, other.onlineColor, t),
      offlineColor:          Color.lerp(offlineColor, other.offlineColor, t),
      sidebarWidth:          lerpDouble(sidebarWidth, other.sidebarWidth, t)!,
      sidebarColor:          Color.lerp(sidebarColor, other.sidebarColor, t),
      cardRadius:            lerpDouble(cardRadius, other.cardRadius, t)!,
      fontFamily:            t < 0.5 ? fontFamily : other.fontFamily,
      fontScale:             lerpDouble(fontScale, other.fontScale, t)!,
      bodyLineHeight:        lerpDouble(bodyLineHeight, other.bodyLineHeight, t)!,
      spacingScale:          lerpDouble(spacingScale, other.spacingScale, t)!,
      iconSizeSm:            lerpDouble(iconSizeSm, other.iconSizeSm, t)!,
      iconSizeMd:            lerpDouble(iconSizeMd, other.iconSizeMd, t)!,
    );
  }
}

/// Convenience accessor — `context.agTheme`.
extension AgThemeDataContext on BuildContext {
  AgThemeData get agTheme =>
      Theme.of(this).extension<AgThemeData>() ?? const AgThemeData();
}
