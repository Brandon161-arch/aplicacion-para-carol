import 'package:flutter/material.dart';

/// Tema claro con una paleta cálida de madera.
abstract final class AppTheme {
  static const Color background = Color(0xFFF4F0EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color seed = Color(0xFF8D6E63);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, width: 1.6),
        errorBorder: border(scheme.error, width: 1.4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
