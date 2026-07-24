import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B1220);
  static const Color primary = Color(0xFF00D084);
  static const Color card = Color(0xFF182235);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primary,
      surface: card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}