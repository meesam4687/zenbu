import 'package:flutter/material.dart';

class CustomTheme {
  final String name;
  final ColorScheme colorScheme;
  final Color scaffoldBackgroundColor;
  final bool isDarkOnly;
  final bool isLightOnly;

  const CustomTheme({
    required this.name,
    required this.colorScheme,
    required this.scaffoldBackgroundColor,
    this.isDarkOnly = false,
    this.isLightOnly = false,
  });
}

final List<CustomTheme> customThemes = [
  const CustomTheme(
    name: 'Midnight',
    scaffoldBackgroundColor: Colors.black,
    isDarkOnly: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFE0E0E0),
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF2D2D2D),
      onPrimaryContainer: Color(0xFFE0E0E0),
      secondary: Color(0xFFE0E0E0),
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFFE0E0E0),
      onSecondaryContainer: Colors.black,
      tertiary: Color(0xFFE0E0E0),
      onTertiary: Colors.black,
      surface: Colors.black,
      onSurface: Color(0xFFE0E0E0),
      surfaceContainer: Colors.black,
      surfaceContainerLow: Color(0xFF0A0A0A),
      surfaceContainerLowest: Colors.black,
      surfaceContainerHigh: Color(0xFF141414),
      surfaceContainerHighest: Color(0xFF1E1E1E),
      onSurfaceVariant: Color(0xFFB0B0B0),
      onInverseSurface: Color(0xFF222222),
      outline: Color(0xFF444444),
      outlineVariant: Color(0xFF2D2D2D),
      error: Color(0xFFCF6679),
      onError: Colors.black,
    ),
  ),
];
