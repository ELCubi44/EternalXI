import 'package:flutter/material.dart';

/// Sub-tema oscuro premium para el módulo de recompensas (independiente del tema global).
class RewardsPremiumTheme {
  RewardsPremiumTheme._();

  static const background = Color(0xFF070910);
  static const surface = Color(0xFF0E121C);
  static const surfaceHigh = Color(0xFF1A2233);
  static const surfaceHighest = Color(0xFF1C2742);
  static const accent = Color(0xFFFFD54F);

  static ThemeData get data {
    const seed = Color(0xFF1E3A5F);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: background,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      primary: accent,
      onPrimary: Color(0xFF1A237E),
      secondary: Color(0xFF4527A0),
      onSecondary: Colors.white,
      inverseSurface: surfaceHighest,
      onInverseSurface: Colors.white,
      outline: Colors.white24,
      outlineVariant: Colors.white12,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: Colors.white54,
        indicatorColor: accent,
        dividerColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: const Color(0xFF263238),
        checkmarkColor: accent,
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70, height: 1.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHighest,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      dividerTheme: const DividerThemeData(color: Colors.white12),
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(color: Colors.white70),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF1A237E),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
    );
  }

  static Widget scope({required Widget child}) {
    return Theme(data: data, child: child);
  }
}
