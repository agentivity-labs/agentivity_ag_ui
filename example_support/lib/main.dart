import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const SupportDemoApp());
}

class SupportDemoApp extends StatelessWidget {
  const SupportDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Customer Support',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF1565C0); // professional blue
    const background = Color(0xFFF5F7FA);
    const surface = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFF0288D1),
        surface: surface,
        surfaceContainerHighest: Color(0xFFE8F4FF),
        onPrimary: Colors.white,
        onSurface: Color(0xFF1A1A2E),
        outline: Color(0xFFCCD8E8),
        outlineVariant: Color(0xFFDDE6F0),
        primaryContainer: Color(0xFFE3F2FD),
        onPrimaryContainer: Color(0xFF1565C0),
        secondaryContainer: Color(0xFFE1F5FE),
        onSecondaryContainer: Color(0xFF0277BD),
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1A1A2E)),
        bodyMedium: TextStyle(color: Color(0xFF444466)),
        bodySmall: TextStyle(color: Color(0xFF666688)),
        titleLarge:
            TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Color(0xFF444466)),
        labelSmall: TextStyle(color: Color(0xFF888899)),
      ),
    );
  }
}
