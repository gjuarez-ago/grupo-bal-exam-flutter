import 'package:flutter/material.dart';

/// Tema de la aplicación basado en Material 3.
abstract final class AppTheme {
  static const _seedColor = Color(0xFF3F51B5);

  /// Tema claro y sobrio, generado a partir de un color semilla.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor);

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
