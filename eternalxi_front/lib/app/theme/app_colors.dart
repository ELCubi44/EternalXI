import 'package:flutter/material.dart';

abstract final class XiColors {
  // --- Paleta principal ---
  static const nightBlue = Color(0xFF101B35);
  static const navyBlue = Color(0xFF173A63);
  static const royalBlue = Color(0xFF2457C5);
  static const iceBlue = Color(0xFF8FD9FF);
  static const techCyan = Color(0xFF30D6E8);
  static const darkGreen = Color(0xFF123B31);
  static const jungleGreen = Color(0xFF1F6B46);
  static const emeraldGreen = Color(0xFF41B978);
  static const heroRed = Color(0xFFD93632);
  static const darkRed = Color(0xFF8E1F2D);
  static const energyOrange = Color(0xFFF47A24);
  static const classicGold = Color(0xFFD9A441);
  static const sandGold = Color(0xFFC99A5A);
  static const ivoryUniform = Color(0xFFF2E6C8);
  static const warmWhite = Color(0xFFFFF8E8);
  static const magicPurple = Color(0xFF4B2E83);
  static const darkViolet = Color(0xFF2A1848);
  static const uniformBlack = Color(0xFF111217);
  static const steelGray = Color(0xFF59606D);
  static const techLightGray = Color(0xFFDDE4EA);

  // --- Superficies UI (derivadas de la paleta) ---
  static const background = nightBlue;
  static const surfaceCard = Color(0xFF152240); // navyBlue ligeramente más oscuro
  static const surfaceElevated = Color(0xFF1C2E52);
  static const surfaceContainer = Color(0xFF0D1628);
  static const divider = Color(0xFF4A6490); // visible sobre fondos oscuros

  // --- Texto ---
  static const textPrimary = warmWhite;
  static const textSecondary = techLightGray;
  static const textDisabled = steelGray;
  static const textOnPrimary = warmWhite;

  // --- Semánticos ---
  static const primary = royalBlue;
  static const primaryLight = iceBlue;
  static const secondary = techCyan;
  static const accent = classicGold;
  static const success = emeraldGreen;
  static const error = heroRed;
  static const warning = energyOrange;

  // --- ColorScheme fijo oscuro ---
  static const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: royalBlue,
    onPrimary: warmWhite,
    primaryContainer: Color(0xFF1A3A8A),
    onPrimaryContainer: iceBlue,
    secondary: techCyan,
    onSecondary: nightBlue,
    secondaryContainer: Color(0xFF0E4A52),
    onSecondaryContainer: techCyan,
    tertiary: classicGold,
    onTertiary: nightBlue,
    tertiaryContainer: Color(0xFF4A3510),
    onTertiaryContainer: classicGold,
    error: heroRed,
    onError: warmWhite,
    errorContainer: Color(0xFF5C1210),
    onErrorContainer: Color(0xFFFFB3AE),
    surface: nightBlue,
    onSurface: warmWhite,
    surfaceContainerLowest: uniformBlack,
    surfaceContainerLow: Color(0xFF0D1628),
    surfaceContainer: Color(0xFF152240),
    surfaceContainerHigh: Color(0xFF1C2E52),
    surfaceContainerHighest: Color(0xFF233565),
    onSurfaceVariant: techLightGray,
    outline: Color(0xFF6B8EC4),       // visible sobre todos los fondos oscuros
    outlineVariant: Color(0xFF4A6490), // mismo que divider
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: ivoryUniform,
    onInverseSurface: nightBlue,
    inversePrimary: royalBlue,
  );
}
