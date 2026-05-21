import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Renders Markdown text consistently across all AG-UI widgets.
///
/// **Only use for completed messages.** While a message is still streaming,
/// render plain [Text] instead — partial markdown causes unstable layouts
/// (unclosed code fences, broken list items, orphaned bold markers).
///
/// The style sheet inherits from the ambient [ThemeData] and blends with the
/// optional [textColor] / [linkColor] overrides, so bubbles with any
/// background color stay legible without extra configuration.
class AgUiMarkdownBody extends StatelessWidget {
  const AgUiMarkdownBody({
    super.key,
    required this.data,
    this.textColor,
    this.textStyle,
    this.linkColor,
  });

  final String data;

  /// Override the default text colour (e.g. to contrast with a dark bubble).
  final Color? textColor;

  /// Base text style. Falls back to [TextTheme.bodyMedium].
  final TextStyle? textStyle;

  /// Colour for hyperlinks and blockquote accents. Defaults to [ColorScheme.primary].
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = (textStyle ?? theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: textColor);
    final resolvedLink = linkColor ?? cs.primary;
    final codeBg = cs.surfaceContainerHigh.withValues(alpha: isDark ? 0.85 : 0.6);
    final codeBase = theme.textTheme.bodySmall ?? const TextStyle();

    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: base.copyWith(height: 1.35),
      strong: base.copyWith(fontWeight: FontWeight.w600),
      em: base.copyWith(fontStyle: FontStyle.italic),
      del: base.copyWith(decoration: TextDecoration.lineThrough),
      a: base.copyWith(color: resolvedLink),
      code: codeBase.copyWith(
        fontFamily: 'monospace',
        color: textColor,
        backgroundColor: codeBg,
        height: 1.2,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: resolvedLink.withValues(alpha: 0.5), width: 3),
        ),
      ),
      listBulletPadding: const EdgeInsets.only(left: 8),
      h1: base.copyWith(fontSize: (base.fontSize ?? 14) + 8, fontWeight: FontWeight.bold),
      h2: base.copyWith(fontSize: (base.fontSize ?? 14) + 5, fontWeight: FontWeight.bold),
      h3: base.copyWith(fontSize: (base.fontSize ?? 14) + 2, fontWeight: FontWeight.w600),
    );

    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
      shrinkWrap: true,
      styleSheet: sheet,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
    );
  }
}
