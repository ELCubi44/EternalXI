import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';

/// Texto visible de un evento de partido según idioma (fases + plantillas por tipo).
String localizedMatchEventText(LeagueL10n ll, LeagueMatchEvent event) {
  if (_isBreakMarker(event)) {
    return ll.halfTime;
  }
  if (_isSecondHalfStartMarker(event)) {
    return ll.secondHalfStart;
  }
  if (_isFinalMarker(event)) {
    return ll.matchEnd;
  }

  if (!ll.isEnglish) {
    final text = event.texto.trim();
    if (text.isNotEmpty) {
      return text;
    }
    return _fallbackFromType(ll, event);
  }

  final fromType = _englishFromType(event);
  if (fromType != null) {
    return fromType;
  }

  final text = event.texto.trim();
  if (text.isNotEmpty) {
    return text;
  }
  return _fallbackFromType(ll, event);
}

String _fallbackFromType(LeagueL10n ll, LeagueMatchEvent event) {
  final type = event.tipo.trim();
  final main = event.jugadorPrincipal.trim();
  final sec = event.jugadorSecundario.trim();
  if (type.isNotEmpty && main.isEmpty && sec.isEmpty) {
    return _normalizeNeutralType(ll, type);
  }
  final pieces = <String>[
    if (type.isNotEmpty) type,
    if (main.isNotEmpty) main,
    if (sec.isNotEmpty) sec,
  ];
  return pieces.isEmpty ? ll.genericEvent : pieces.join(' - ');
}

String _normalizeNeutralType(LeagueL10n ll, String rawType) {
  final t = rawType.trim().toUpperCase().replaceAll('_', ' ');
  if (t.contains('INICIO')) {
    return ll.matchStart;
  }
  if (t.contains('DESCANSO')) {
    return ll.halfTime;
  }
  if (t.contains('FINAL')) {
    return ll.matchEnd;
  }
  return rawType.trim();
}

String? _englishFromType(LeagueMatchEvent event) {
  final t = normalizedLeagueMatchEventType(event);
  final main = event.jugadorPrincipal.trim();
  final sec = event.jugadorSecundario.trim();

  if (leagueMatchEventTipoCambioSustitucion(event) &&
      main.isNotEmpty &&
      sec.isNotEmpty) {
    return 'Substitution: $main on for $sec.';
  }

  if ((t == 'GOL' || t.contains('GOL')) && !t.contains('ENCAJ')) {
    if (main.isNotEmpty && sec.isNotEmpty) {
      return 'GOAL! $main scores for $sec.';
    }
    if (main.isNotEmpty) {
      return 'GOAL! $main scores.';
    }
  }

  if (t.contains('ASISTENCIA') && main.isNotEmpty && sec.isNotEmpty) {
    return '$main assists $sec.';
  }

  if (t.contains('TARJETA') && t.contains('ROJA') && main.isNotEmpty) {
    return 'Red card for $main.';
  }

  if (t.contains('TARJETA') && t.contains('AMARILL') && main.isNotEmpty) {
    return 'Yellow card for $main.';
  }

  if (t.contains('LESION') && main.isNotEmpty) {
    return 'Injury: $main.';
  }

  if (t.contains('PARADA') && main.isNotEmpty && sec.isNotEmpty) {
    return '$main saves $sec\'s shot.';
  }

  if (t.contains('DISPARO') && main.isNotEmpty) {
    return '$main shoots.';
  }

  if (t.contains('FALTA') && main.isNotEmpty && sec.isNotEmpty) {
    return 'Foul by $main on $sec.';
  }

  if (t.contains('CESION') && main.isNotEmpty) {
    return 'Loan player $main in action.';
  }

  if (main.isNotEmpty && sec.isNotEmpty) {
    return '$main — $sec';
  }
  if (main.isNotEmpty) {
    return main;
  }
  return null;
}

bool _isBreakMarker(LeagueMatchEvent e) {
  final type = e.tipo.trim().toUpperCase().replaceAll(' ', '_');
  if (type.contains('DESCANSO') ||
      type.contains('HT') ||
      type.contains('HALF_TIME') ||
      type.contains('MEDIO_TIEMPO') ||
      type.contains('INTERVAL')) {
    return true;
  }
  final text = e.texto.trim().toUpperCase();
  return text.contains('DESCANSO') || text.contains('MEDIO TIEMPO');
}

bool _isSecondHalfStartMarker(LeagueMatchEvent e) {
  final type = e.tipo.trim().toUpperCase().replaceAll(' ', '_');
  if (type.contains('INICIO_SEGUNDA_PARTE') ||
      type.contains('SEGUNDA_PARTE') ||
      type.contains('SECOND_HALF') ||
      type.contains('2ND_HALF') ||
      type.contains('REANUD')) {
    return true;
  }
  final text = e.texto.trim().toUpperCase();
  return text.contains('INICIO DE LA SEGUNDA PARTE') ||
      text.contains('SEGUNDA PARTE');
}

bool _isFinalMarker(LeagueMatchEvent e) {
  return leagueMatchEventIsFullTimeMarker(e);
}
