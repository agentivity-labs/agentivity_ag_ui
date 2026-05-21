import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const TravelDemoApp());
}

class TravelDemoApp extends StatelessWidget {
  const TravelDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Trip Planner',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: _buildTheme(),
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF00B4D8); // ocean cyan
    const background = Color(0xFF0A1628); // deep navy
    const surface = Color(0xFF122236);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF48CAE4),
        surface: surface,
        surfaceContainerHighest: Color(0xFF1C3248),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        outline: Color(0xFF2A4A6A),
        outlineVariant: Color(0xFF1E3850),
        primaryContainer: Color(0xFF0A3850),
        onPrimaryContainer: Colors.white,
        secondaryContainer: Color(0xFF12334D),
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
        titleMedium:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white54),
      ),
    );
  }
}
