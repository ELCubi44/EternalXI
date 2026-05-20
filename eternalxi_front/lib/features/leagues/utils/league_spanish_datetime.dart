/// Formato de fecha/hora legible para usuario español (sin dependencia `intl`).
abstract final class LeagueSpanishDateTime {
  LeagueSpanishDateTime._();

  static const _monthsShort = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// Ej.: `25 abr 2026`
  static String formatDateLong(DateTime? utcOrLocal) {
    if (utcOrLocal == null) {
      return '—';
    }
    final d = utcOrLocal.toLocal();
    final m = _monthsShort[d.month - 1];
    return '${d.day} $m ${d.year}';
  }

  /// Ej.: `25/04/2026` (útil en cabeceras compactas)
  static String formatDateNumeric(DateTime? utcOrLocal) {
    if (utcOrLocal == null) {
      return '—';
    }
    final d = utcOrLocal.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  /// Ej.: `19:00`
  static String formatTimeHm(DateTime? utcOrLocal) {
    if (utcOrLocal == null) {
      return '—';
    }
    final d = utcOrLocal.toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Etiqueta corta si el día coincide con hoy (fecha local).
  static String? todayChipIfSameDay(DateTime? kickoff) {
    if (kickoff == null) {
      return null;
    }
    final k = kickoff.toLocal();
    final n = DateTime.now();
    if (k.year == n.year && k.month == n.month && k.day == n.day) {
      return 'Hoy';
    }
    return null;
  }
}
