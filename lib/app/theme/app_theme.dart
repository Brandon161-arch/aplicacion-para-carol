import 'package:flutter/material.dart';

/// Sistema visual cálido de carpintería premium.
///
/// Solo contiene colores, formas, sombras y tipografía: no hay lógica aquí.
abstract final class AppTheme {
  // Paleta base.
  static const Color background = Color(0xFFF5F0E8);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surfaceMuted = Color(0xFFF8F2E9);
  static const Color surfaceSunken = Color(0xFFF1E8DC);
  static const Color seed = Color(0xFF9A6242);
  static const Color primary = Color(0xFF945D3E);
  static const Color primaryDark = Color(0xFF7B462C);
  static const Color secondary = Color(0xFFB07A4F);
  static const Color accent = Color(0xFFC98A5C);
  static const Color ink = Color(0xFF2E2620);
  static const Color inkMuted = Color(0xFF7A6A5D);
  static const Color outline = Color(0xFFCBB9A5);
  static const Color outlineSoft = Color(0xFFE7DCCE);
  static const Color rowStripe = Color(0x08A57A55);
  static const Color shadow = Color(0x1A3B2A1C);

  // Visor 3D.
  static const Color viewerTop = Color(0xFF26211C);
  static const Color viewerBottom = Color(0xFF0B0908);
  static const Color viewerPanel = Color(0xE61C1814);
  static const Color viewerPanelBorder = Color(0x24FFFFFF);

  // Formas y movimiento.
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 220);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFF2E1D2),
          onPrimaryContainer: const Color(0xFF4A2C1B),
          secondary: secondary,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFF7EBDD),
          onSecondaryContainer: const Color(0xFF4A2E1A),
          tertiary: accent,
          onTertiary: Colors.white,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: inkMuted,
          surfaceContainerHighest: surfaceSunken,
          surfaceContainerHigh: const Color(0xFFF5EDE3),
          surfaceContainer: surfaceMuted,
          surfaceContainerLow: const Color(0xFFFBF7F1),
          outline: outline,
          outlineVariant: outlineSoft,
        );

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm + 2),
          borderSide: BorderSide(color: color, width: width),
        );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );

    final baseText = Typography.material2021().black.apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final textTheme = baseText.copyWith(
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.18,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 14, height: 1.45),
      bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        letterSpacing: 0.05,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      fontFamilyFallback: const [
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'Arial',
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadow,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: inkMuted, size: 21),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hoverColor: const Color(0xFFFBF6EF),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: const TextStyle(
          color: inkMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: inkMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        helperStyle: const TextStyle(
          color: inkMuted,
          fontSize: 11.5,
          height: 1.3,
        ),
        prefixIconColor: inkMuted,
        suffixIconColor: inkMuted,
        border: border(outlineSoft),
        enabledBorder: border(outlineSoft),
        focusedBorder: border(primary, width: 1.7),
        errorBorder: border(scheme.error, width: 1.4),
        focusedErrorBorder: border(scheme.error, width: 1.7),
        disabledBorder: border(outlineSoft),
      ),
      dividerTheme: DividerThemeData(
        color: outlineSoft.withValues(alpha: 0.9),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return ink.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) return primaryDark;
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF875239);
            }
            return primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? Colors.white.withValues(alpha: 0.10)
                : null,
          ),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? 3 : 1,
          ),
          shadowColor: const WidgetStatePropertyAll(shadow),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          backgroundColor: const WidgetStatePropertyAll(surface),
          foregroundColor: const WidgetStatePropertyAll(primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? 4 : 1,
          ),
          shadowColor: const WidgetStatePropertyAll(shadow),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.hovered)
                  ? primary.withValues(alpha: 0.7)
                  : outline.withValues(alpha: 0.75),
              width: states.contains(WidgetState.focused) ? 1.5 : 1,
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(primary),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? primary.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? primary.withValues(alpha: 0.10)
                : null,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          foregroundColor: const WidgetStatePropertyAll(primary),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? primary.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(inkMuted),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? primary.withValues(alpha: 0.08)
                : null,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: const Color(0xFFF1E2D4),
        disabledColor: surfaceSunken,
        side: BorderSide(color: outline.withValues(alpha: 0.65)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(
          color: ink,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: primary,
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: 0.07);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? Colors.white : ink,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? primary
                  : outline.withValues(alpha: 0.7),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: primary,
        inactiveTrackColor: outlineSoft,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: outlineSoft.withValues(alpha: 0.85)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: shadow,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2B231C),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Color(0xFFFFF8F0),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(surfaceMuted),
        headingRowHeight: 46,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        horizontalMargin: 18,
        columnSpacing: 22,
        dividerThickness: 0.7,
        headingTextStyle: textTheme.labelLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.25,
        ),
        dataTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
        selectedColor: primary,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        indicatorColor: const Color(0xFFF1E2D4),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        selectedIconTheme: const IconThemeData(color: primary, size: 23),
        unselectedIconTheme: const IconThemeData(color: inkMuted, size: 22),
        selectedLabelTextStyle: const TextStyle(
          color: primary,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: inkMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        useIndicator: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFFF1E2D4),
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: shadow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? primary : inkMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? primary : inkMuted,
          ),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 8 : 5,
        ),
        radius: const Radius.circular(999),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => ink.withValues(
            alpha: states.contains(WidgetState.hovered) ? 0.30 : 0.16,
          ),
        ),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B231C),
        contentTextStyle: const TextStyle(
          color: Color(0xFFFFF8F0),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm + 2),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0xFFE8D3BF),
        selectionHandleColor: primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: outlineSoft,
      ),
    );
  }
}
