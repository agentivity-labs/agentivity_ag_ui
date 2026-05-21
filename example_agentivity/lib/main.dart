import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/config_screen.dart';
import 'theme_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const AgentivityClientApp());
}

class AgentivityClientApp extends StatelessWidget {
  const AgentivityClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'Agentivity',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const ConfigScreen(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = Color(0xFF5B4CF5);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: const Color(0xFF00BCD4),
        surface: isDark ? const Color(0xFF111111) : const Color(0xFFFAFAFA),
        surfaceContainerLow:
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
        surfaceContainerHighest:
            isDark ? const Color(0xFF242424) : const Color(0xFFF0F0F0),
        outlineVariant:
            isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE3E3E3),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFE3E3E3),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFE3E3E3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFE3E3E3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide:
              const BorderSide(color: primary, width: 1.5),
        ),
        filled: true,
        fillColor:
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
        hintStyle: TextStyle(
          fontSize: 12,
          color: isDark
              ? const Color(0xFF555555)
              : const Color(0xFFAAAAAA),
        ),
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(fontSize: 11),
        bodyMedium: TextStyle(fontSize: 12),
        bodyLarge: TextStyle(fontSize: 13),
        labelSmall: TextStyle(fontSize: 10),
        labelMedium: TextStyle(fontSize: 11),
        labelLarge: TextStyle(fontSize: 12),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, 32),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: isDark
            ? const Color(0xFF2E2E2E)
            : const Color(0xFFE8E8E8),
        space: 0,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF111111),
        ),
        backgroundColor:
            isDark ? const Color(0xFF111111) : const Color(0xFFFAFAFA),
        foregroundColor:
            isDark ? Colors.white : const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFE8E8E8),
          ),
        ),
      ),
    );
  }
}
