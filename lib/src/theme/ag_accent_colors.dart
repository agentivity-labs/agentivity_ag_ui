import 'package:flutter/material.dart';

/// Theme extension carrying the user-selectable accent palette.
///
/// Mirrors Agentivity Studio's `AppAccentColors` so that kit widgets and
/// studio widgets share the same accent vocabulary.
///
/// For **Agentivity Light / Dark** themes the accent drives:
/// - User chat bubble background
/// - Streaming cursor
/// - Runnable accent glow
/// - Interactive element highlights (links, focus rings, check marks)
///
/// For other presets the accent is auto-derived from the preset's
/// `bubbleUserColor` so that `context.agAccent` always returns something
/// sensible, even without an explicit palette injection.
///
/// ## Access
/// ```dart
/// final accent = context.agAccent;
/// // or
/// final accent = AgAccentColors.of(context);
/// ```
@immutable
class AgAccentColors extends ThemeExtension<AgAccentColors> {
  const AgAccentColors({
    required this.primary,
    required this.onPrimary,
    required this.shadow,
  });

  /// The accent hue — used for fills, borders, and interactive states.
  final Color primary;

  /// Text / icon colour that reads well on [primary].
  final Color onPrimary;

  /// Semi-transparent [primary] for glow and shadow effects.
  final Color shadow;

  // ── Predefined palettes (same values as studio kAppAccentPalettes) ─────────

  static const AgAccentColors iris = AgAccentColors(
    primary: Color(0xFF8B61FF),
    onPrimary: Color(0xFFFFFFFF),
    shadow: Color(0x668B61FF),
  );

  static const AgAccentColors coral = AgAccentColors(
    primary: Color(0xFFFF6B5F),
    onPrimary: Color(0xFF2F0B06),
    shadow: Color(0x55FF6B5F),
  );

  static const AgAccentColors aurora = AgAccentColors(
    primary: Color(0xFF58D38C),
    onPrimary: Color(0xFF04160C),
    shadow: Color(0x5558D38C),
  );

  static const AgAccentColors glacier = AgAccentColors(
    primary: Color(0xFF4DD0E1),
    onPrimary: Color(0xFF002027),
    shadow: Color(0x554DD0E1),
  );

  static const AgAccentColors amber = AgAccentColors(
    primary: Color(0xFFFFB347),
    onPrimary: Color(0xFF2A1600),
    shadow: Color(0x55FFB347),
  );

  // ── Catalogue ───────────────────────────────────────────────────────────────

  /// All available accent palettes in display order.
  static const List<AgAccentPalette> palettes = [
    AgAccentPalette(id: 'iris',    label: 'Iris',    colors: iris),
    AgAccentPalette(id: 'coral',   label: 'Coral',   colors: coral),
    AgAccentPalette(id: 'aurora',  label: 'Aurora',  colors: aurora),
    AgAccentPalette(id: 'glacier', label: 'Glacier', colors: glacier),
    AgAccentPalette(id: 'amber',   label: 'Amber',   colors: amber),
  ];

  /// Returns the [AgAccentPalette] with the given [id].
  /// Falls back to [iris] if not found.
  static AgAccentPalette paletteById(String id) =>
      palettes.firstWhere((p) => p.id == id, orElse: () => palettes.first);

  // ── Accessor ────────────────────────────────────────────────────────────────

  /// Reads the nearest [AgAccentColors] from [context].
  ///
  /// Falls back to [iris] if no extension is registered in the current theme.
  static AgAccentColors of(BuildContext context) =>
      Theme.of(context).extension<AgAccentColors>() ?? iris;

  // ── ThemeExtension ──────────────────────────────────────────────────────────

  @override
  AgAccentColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? shadow,
  }) {
    return AgAccentColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AgAccentColors lerp(AgAccentColors? other, double t) {
    if (other == null) return this;
    return AgAccentColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

/// A named accent palette entry (id + display label + color triple).
@immutable
class AgAccentPalette {
  const AgAccentPalette({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final AgAccentColors colors;
}

/// Convenience accessor — `context.agAccent`.
///
/// Falls back to [AgAccentColors.iris] if no accent extension is present.
extension AgAccentColorsContext on BuildContext {
  AgAccentColors get agAccent =>
      Theme.of(this).extension<AgAccentColors>() ?? AgAccentColors.iris;
}
