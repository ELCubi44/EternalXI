import 'package:flutter/material.dart';
String formatRewardMoney(num value) {
  final v = value.abs();
  if (v >= 1e9) {
    return '${(value / 1e9).toStringAsFixed(v >= 10e9 ? 0 : 1)}B €';
  }
  if (v >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(v >= 10e6 ? 0 : 1)}M €';
  }
  if (v >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(0)}k €';
  }
  return '${value.toInt()} €';
}

/// Importe en euros con separador de miles (sin abreviaturas k/M/B).
String formatRewardMoneyFull(num value) {
  final rounded = value.round();
  final neg = rounded < 0;
  final s = rounded.abs().toString();
  final buf = StringBuffer();
  if (neg) {
    buf.write('-');
  }
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return '${buf.toString()} €';
}

String formatRewardPoints(int value, {String unit = 'fichas'}) {
  return '${_formatRewardPointsNumber(value)} $unit';
}

String _formatRewardPointsNumber(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Puntos compactos para chips (p. ej. cabecera de liga): `2.0k`, `1.2M`.
String formatRewardPointsCompact(int value) {
  final v = value.abs();
  if (v >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (v >= 10000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  }
  if (v >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return formatRewardPoints(value);
}

/// [compact] true → [formatRewardPointsCompact]; si no, miles con sufijo de fichas.
String formatRewardPointsForChip(
  int value, {
  required bool compact,
  String unit = 'fichas',
}) {
  if (compact) {
    return formatRewardPointsCompact(value);
  }
  return formatRewardPoints(value, unit: unit);
}

/// Etiqueta de porcentaje/multiplicador según cómo venga el número del backend
/// (ratio 0–1 o valor ya en escala 0–100+).
String formatBackendPercentLike(double? v) {
  if (v == null) {
    return '—';
  }
  if (v > 0 && v <= 1) {
    return '${(v * 100).round()}%';
  }
  if (v == v.roundToDouble()) {
    return '${v.toInt()}%';
  }
  return '${v.toStringAsFixed(1)}%';
}

String formatRewardDateTime(BuildContext context, DateTime? utc) {
  if (utc == null) {
    return '—';
  }
  final local = utc.toLocal();
  final loc = MaterialLocalizations.of(context);
  return '${loc.formatFullDate(local)} · ${TimeOfDay.fromDateTime(local).format(context)}';
}

DateTime? parseRewardDate(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim());
  }
  return null;
}
