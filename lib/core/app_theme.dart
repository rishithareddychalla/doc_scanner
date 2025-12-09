// lib/core/app_theme.dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2563EB),
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1F2937),
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 12,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Color(0xFF2563EB), size: 28);
        }
        return const IconThemeData(color: Color(0xFF9CA3AF), size: 26);
      }),
    ),
    scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  );
}
