import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_event_l10n.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_event_row.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_timeline_summary.dart';
import 'package:eternal_xi/shared/widgets/player_injury_icon.dart';
import 'package:eternal_xi/shared/widgets/red_card_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LeagueMatchTimelineTab extends StatelessWidget {
  const LeagueMatchTimelineTab({
    super.key,
    required this.roster,
    required this.events,
    this.ll,
    this.phase = LeagueMatchDisplayPhase.finished,
    this.scoreLocal = 0,
    this.scoreVisitante = 0,
    this.liveMinuteLabel,
    this.localTeamName = '',
    this.awayTeamName = '',
  });

  final LeagueMatchRoster roster;
  final List<LeagueMatchEvent> events;
  final LeagueL10n? ll;
  final LeagueMatchDisplayPhase phase;
  final int scoreLocal;
  final int scoreVisitante;
  final String? liveMinuteLabel;
  final String localTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    final leagueL10n = ll ?? LeagueL10n.of(context);
    return LeagueMatchTimelineSummary(
      roster: roster,
      events: events,
      ll: leagueL10n,
      phase: phase,
      scoreLocal: scoreLocal,
      scoreVisitante: scoreVisitante,
      liveMinuteLabel: liveMinuteLabel,
      localTeamName: localTeamName,
      awayTeamName: awayTeamName,
    );
  }

  /// Fila estándar de cronología (CESION_PARTIDO, CAMBIO, gol, etc.).
  static LeagueMatchEventRow rowForEvent(
    LeagueMatchEvent event,
    LeagueMatchRoster roster,
    Map<int, LeagueSquadPlayer> playersById,
    LeagueL10n ll,
  ) {
    final side = resolveSide(event, roster);
    final playerIn = playersById[event.idLigaJugadorPrincipal];
    final playerOut = playersById[event.idLigaJugadorSecundario];
    final isGrouped = isLoanGroupedEvent(event);
    final isSub = leagueMatchEventTipoCambioSustitucion(event);
    final isIndividual = !isSub && isLoanIndividualEvent(event);
    final loanUri =
        (!isGrouped && !isSub) ? _loanPhotoUri(event) : null;
    final isRedCard = isRedCardMatchEvent(event);
    final isInjury = isInjuryMatchEvent(event);
    final dec =
        (isRedCard || isInjury) ? null : _eventTypeDecoration(event);
    Uri? subIn;
    Uri? subOut;
    if (isSub) {
      subIn = _substitutionPhotoInUri(event);
      subOut = _substitutionPhotoOutUri(event);
    }
    return LeagueMatchEventRow(
      minuteLabel: _minuteLabel(event),
      text: localizedMatchEventText(ll, event),
      fallbackText: ll.genericEvent,
      side: side,
      player: (side == LeagueMatchEventSide.neutral && !isIndividual && !isSub)
          ? null
          : playerIn,
      playerOut: playerOut,
      loanEventPhotoUri: loanUri,
      neutralIcon: _neutralIconForEvent(event),
      isLoanGrouped: isGrouped,
      isLoanIndividual: isIndividual,
      isSubstitution: isSub,
      substitutionPhotoInUri: subIn,
      substitutionPhotoOutUri: subOut,
      eventTypeIcon: dec?.icon,
      eventTypeIconColor: dec?.color,
      eventTypeLeading: isRedCard
          ? const RedCardIcon(size: 22)
          : isInjury
              ? const PlayerInjuryIcon(size: 22)
              : null,
    );
  }

  /// Principal = entra; URL API + cedido principal / legacy.
  static Uri? _substitutionPhotoInUri(LeagueMatchEvent e) {
    final u = LeaguePlayerPhoto.uriFromRawPhoto(e.fotoUrlJugadorPrincipal);
    if (u != null) {
      return u;
    }
    final idIn = e.idJugadorCedidoTemporadaPrincipal > 0
        ? e.idJugadorCedidoTemporadaPrincipal
        : e.idJugadorCedidoTemporada;
    return LeaguePlayerPhoto.resolveLoanTimelinePhoto(
      idJugadorCedidoTemporada: idIn,
      fotoRaw: e.fotoCedidoRaw,
    );
  }

  /// Secundario = sale.
  static Uri? _substitutionPhotoOutUri(LeagueMatchEvent e) {
    final u = LeaguePlayerPhoto.uriFromRawPhoto(e.fotoUrlJugadorSecundario);
    if (u != null) {
      return u;
    }
    return LeaguePlayerPhoto.resolveLoanTimelinePhoto(
      idJugadorCedidoTemporada: e.idJugadorCedidoTemporadaSecundario,
      fotoRaw: e.fotoCedidoSecundarioRaw,
    );
  }

  static ({IconData icon, Color? color})? _eventTypeDecoration(
    LeagueMatchEvent e,
  ) {
    if (leagueMatchEventTipoCambioSustitucion(e)) {
      return null;
    }
    if (isLoanGroupedEvent(e) || isLoanIndividualEvent(e)) {
      return null;
    }
    final t = normalizedLeagueMatchEventType(e);
    if (t == 'TARJETA_AMARILLA' ||
        (t.contains('TARJETA') && t.contains('AMARILL')) ||
        t.contains('AMARILLA')) {
      return (icon: Icons.style_rounded, color: Colors.amber.shade800);
    }
    if ((t == 'GOL' || t.contains('GOL')) && !t.contains('ENCAJ')) {
      return (icon: Icons.sports_soccer, color: null);
    }
    if (t.contains('ASISTENCIA')) {
      return (icon: Icons.sports_handball_outlined, color: null);
    }
    return null;
  }

  /// Foto de cedido en cronología solo para **CESION_PARTIDO** / heurística de cesión.
  static Uri? _loanPhotoUri(LeagueMatchEvent e) {
    Uri? uri;
    var motivoFallback = '';

    if (isLoanIndividualEvent(e)) {
      uri = LeaguePlayerPhoto.resolveLoanTimelinePhoto(
        idJugadorCedidoTemporada: e.idJugadorCedidoTemporada,
        fotoRaw: e.fotoCedidoRaw,
      );
      motivoFallback =
          uri != null ? '' : 'individual:sin_resolve_loan_photo';
    } else {
      final id = e.idJugadorCedidoTemporada;
      final raw = e.fotoCedidoRaw.trim();
      if (id > 0 || raw.isNotEmpty) {
        uri = LeaguePlayerPhoto.resolveLoanTimelinePhoto(
          idJugadorCedidoTemporada: id,
          fotoRaw: raw,
        );
        motivoFallback = uri != null ? '' : 'otro:sin_resolve';
      }
    }

    if (kDebugMode && _shouldLogLoanPhotoEvent(e)) {
      debugPrint(
        '[loan-photo][event] tipo=${e.tipo} texto="${e.texto}" '
        'idLigaJugadorPrincipal=${e.idLigaJugadorPrincipal} '
        'idJugadorCedidoTemporadaPrincipal=${e.idJugadorCedidoTemporadaPrincipal} '
        'fotoUrlJugadorPrincipal="${e.fotoUrlJugadorPrincipal}" '
        'idLigaJugadorSecundario=${e.idLigaJugadorSecundario} '
        'idJugadorCedidoTemporadaSecundario=${e.idJugadorCedidoTemporadaSecundario} '
        'fotoUrlJugadorSecundario="${e.fotoUrlJugadorSecundario}" '
        'loanPhotoUriElegida=${uri ?? '(null)'} '
        'motivoFallback=${motivoFallback.isEmpty ? '(ninguno)' : motivoFallback}',
      );
    }

    return uri;
  }

  static bool _shouldLogLoanPhotoEvent(LeagueMatchEvent e) {
    final tx = e.texto.toUpperCase();
    return isAnyLoanEvent(e) ||
        e.idJugadorCedidoTemporadaPrincipal > 0 ||
        e.idJugadorCedidoTemporadaSecundario > 0 ||
        e.idJugadorCedidoTemporada > 0 ||
        (!leagueMatchEventTipoCambioSustitucion(e) && tx.contains('CEDID'));
  }

  static String _minuteLabel(LeagueMatchEvent e) {
    if (isAnyLoanEvent(e)) {
      return '';
    }
    if (e.minuto <= 0) {
      return '0′';
    }
    return '${e.minuto}′';
  }

  /// Icono solo para tipos concretos; el texto sigue viniendo del backend.
  static IconData? _neutralIconForEvent(LeagueMatchEvent e) {
    if (isLoanGroupedEvent(e)) {
      return Icons.swap_horiz_rounded;
    }
    return null;
  }

  static LeagueMatchEventSide resolveSide(
    LeagueMatchEvent e,
    LeagueMatchRoster roster,
  ) {
    if (_isNeutralType(e)) {
      return LeagueMatchEventSide.neutral;
    }
    final id = e.idLigaJugadorPrincipal;
    if (id <= 0) {
      return LeagueMatchEventSide.neutral;
    }
    if (roster.localPlayerIds.contains(id)) {
      return LeagueMatchEventSide.local;
    }
    if (roster.awayPlayerIds.contains(id)) {
      return LeagueMatchEventSide.away;
    }
    return LeagueMatchEventSide.neutral;
  }

  static bool _isNeutralType(LeagueMatchEvent e) {
    if (leagueMatchEventIsFullTimeMarker(e) ||
        _isBreakMarker(e) ||
        _isSecondHalfStartMarker(e)) {
      return true;
    }
    if (isLoanGroupedEvent(e)) {
      return true;
    }
    final type = e.tipo.trim().toUpperCase().replaceAll(' ', '_');
    if (type.contains('INICIO') ||
        type.contains('DESCANSO') ||
        type.contains('INTERVAL') ||
        type.contains('MITAD') ||
        type.contains('MEDIO') ||
        type.contains('HT') ||
        type.contains('SEGUNDA') ||
        type.contains('2ND') ||
        type.contains('2DO') ||
        type.contains('REANUD') ||
        type.contains('COMIENZO')) {
      return true;
    }
    final txt = e.texto.trim().toUpperCase();
    return txt.contains('INICIO') ||
        txt.contains('DESCANSO') ||
        txt.contains('SEGUNDA PARTE') ||
        txt.contains('2ª PARTE');
  }

  static bool _isBreakMarker(LeagueMatchEvent e) {
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

  static bool _isSecondHalfStartMarker(LeagueMatchEvent e) {
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
}
