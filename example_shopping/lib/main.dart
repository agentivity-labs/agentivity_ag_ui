import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ShoppingDemoApp());
}

class ShoppingDemoApp extends StatelessWidget {
  const ShoppingDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Shopping Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: _buildTheme(),
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF7C4DFF);
    const background = Color(0xFF0D0D1A);
    const surface = Color(0xFF1A1A2E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF00BCD4),
        surface: surface,
        surfaceContainerHighest: Color(0xFF252545),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        outline: Color(0xFF5A5A8A),
        outlineVariant: Color(0xFF3D3D6B),
        primaryContainer: Color(0xFF3D1F8F),
        onPrimaryContainer: Colors.white,
        secondaryContainer: Color(0xFF1A3A4A),
        onSecondaryContainer: Colors.white,
        error: Color(0xFFFF5252),
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white60),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white54),
      ),
    );
  }
}
