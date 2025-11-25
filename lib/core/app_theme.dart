// lib/core/app_theme.dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blueGrey,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
    ),
  );
}
