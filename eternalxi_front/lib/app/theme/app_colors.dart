import 'package:flutter/material.dart';

abstract final class XiColors {
  // --- Paleta principal ---
  // Trial look oscuro en negro (antes night/navy azul).
  static const nightBlue = Color(0xFF0A0A0A);
  static const navyBlue = Color(0xFF1A1A1A);
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
  static const accentViolet = Color(0xFF9D6BFF);
  static const darkViolet = Color(0xFF2A1848);
  static const uniformBlack = Color(0xFF000000);
  static const steelGray = Color(0xFF8A8F98);
  static const techLightGray = Color(0xFFDDE4EA);

  // --- Superficies UI (derivadas de la paleta) ---
  static const background = nightBlue;
  static const surfaceCard = Color(0xFF161616);
  static const surfaceElevated = Color(0xFF222222);
  static const surfaceContainer = Color(0xFF111111);
  static const divider = Color(0xFF3A3A3A);

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
    surfaceContainerLow: Color(0xFF111111),
    surfaceContainer: Color(0xFF161616),
    surfaceContainerHigh: Color(0xFF222222),
    surfaceContainerHighest: Color(0xFF2C2C2C),
    onSurfaceVariant: techLightGray,
    outline: Color(0xFF6A6A6A),
    outlineVariant: Color(0xFF3A3A3A),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: ivoryUniform,
    onInverseSurface: nightBlue,
    inversePrimary: royalBlue,
  );
}
