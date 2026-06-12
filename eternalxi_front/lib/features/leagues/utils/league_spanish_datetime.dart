/// Formato de fecha/hora legible (es/en, sin dependencia `intl`).
abstract final class LeagueSpanishDateTime {
  LeagueSpanishDateTime._();

  static const _monthsShortEs = <String>[
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

  static const _monthsShortEn = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static List<String> _monthsShort(bool english) =>
      english ? _monthsShortEn : _monthsShortEs;

  /// Ej.: `25 abr 2026` / `25 Apr 2026`
  static String formatDateLong(DateTime? utcOrLocal, {bool english = false}) {
    if (utcOrLocal == null) {
      return '—';
    }
    final d = utcOrLocal.toLocal();
    final m = _monthsShort(english)[d.month - 1];
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
  static String? todayChipIfSameDay(DateTime? kickoff, {bool english = false}) {
    if (kickoff == null) {
      return null;
    }
    final k = kickoff.toLocal();
    final n = DateTime.now();
    if (k.year == n.year && k.month == n.month && k.day == n.day) {
      return english ? 'Today' : 'Hoy';
    }
    return null;
  }
}
