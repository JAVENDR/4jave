import 'package:flutter/material.dart';

/// Палитра 4jave: глубокая морская синева, бирюзовая волна, янтарь.
class J {
  static const deep = Color(0xFF0A1128);
  static const surface = Color(0xFF121B3A);
  static const surface2 = Color(0xFF1A2550);
  static const wave = Color(0xFF19C3B1);
  static const foam = Color(0xFFE8F7F5);
  static const amber = Color(0xFFFFB454);
  static const coral = Color(0xFFFF6B6B);
  static const muted = Color(0xFF8A96B8);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: wave,
      brightness: Brightness.dark,
    ).copyWith(primary: wave, secondary: amber, error: coral, surface: surface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: deep,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: deep,
        indicatorColor: surface2,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: surface2,
      ),
      textTheme: ThemeData.dark().textTheme.apply(bodyColor: foam, displayColor: foam),
    );
  }
}
