import 'package:flutter/material.dart';

/// Etiqueta cualitativa para UI (no sustituye al porcentaje numérico del backend).
String starterTitularidadBandLabel(int? p) {
  if (p == null) {
    return 'Sin calcular';
  }
  if (p >= 80) {
    return 'Muy probable';
  }
  if (p >= 50) {
    return 'Probable';
  }
  if (p >= 25) {
    return 'Duda';
  }
  if (p >= 1) {
    return 'Poco probable';
  }
  return 'No disponible';
}

String starterTitularidadPercentLabel(int? p) {
  if (p == null) {
    return 'Sin calcular';
  }
  return '$p%';
}

Color starterTitularidadChipBackground(int? p, ColorScheme cs) {
  if (p == null) {
    return cs.surfaceContainerHighest.withValues(alpha: 0.72);
  }
  if (p >= 80) {
    return cs.primaryContainer.withValues(alpha: 0.5);
  }
  if (p >= 50) {
    return cs.secondaryContainer.withValues(alpha: 0.42);
  }
  if (p >= 25) {
    return cs.tertiaryContainer.withValues(alpha: 0.38);
  }
  if (p >= 1) {
    return cs.surfaceContainerHighest.withValues(alpha: 0.78);
  }
  return cs.errorContainer.withValues(alpha: 0.38);
}

Color starterTitularidadChipForeground(int? p, ColorScheme cs) {
  if (p == null) {
    return cs.onSurfaceVariant;
  }
  if (p >= 80) {
    return cs.onPrimaryContainer;
  }
  if (p >= 50) {
    return cs.onSecondaryContainer;
  }
  if (p >= 25) {
    return cs.onTertiaryContainer;
  }
  if (p >= 1) {
    return cs.onSurface;
  }
  return cs.onErrorContainer;
}

/// Rojo (baja) → verde (alta). Backend suele usar 0–95.
Color starterTitularidadScaleBackgroundSolid(int percent) {
  final t = (percent.clamp(0, 100)) / 100.0;
  const red = Color(0xFFC62828);
  const green = Color(0xFF2E7D32);
  return Color.lerp(red, green, t)!;
}

Color starterTitularidadScaleOnBackground(int percent) {
  final bg = starterTitularidadScaleBackgroundSolid(percent);
  return bg.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
}
