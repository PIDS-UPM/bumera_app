import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff6750a4),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
}
