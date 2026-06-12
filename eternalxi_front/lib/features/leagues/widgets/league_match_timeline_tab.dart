import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_event_l10n.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_event_row.dart';
import 'package:eternal_xi/shared/widgets/player_injury_icon.dart';
import 'package:eternal_xi/shared/widgets/red_card_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Segundos de juego desde el inicio (minuto + segundo reales), para clasificar y ordenar.
int _eventTotalSeconds(LeagueMatchEvent e) {
  final m = e.minuto < 0 ? 0 : e.minuto;
  final s = e.segundo.clamp(0, 59);
  return m * 60 + s;
}

class LeagueMatchTimelineTab extends StatelessWidget {
  const LeagueMatchTimelineTab({
    super.key,
    required this.roster,
    required this.events,
  });

  final LeagueMatchRoster roster;
  final List<LeagueMatchEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ll = context.leagueL10n;
    final ordered = [...events]..sort(compareLeagueMatchEventsChrono);
    if (kDebugMode) {
      debugPrint(
        '[match-timeline][render-list] incoming=${ordered.length} ids=${ordered.map((e) => e.idEvento).join(",")}',
      );
    }
    if (ordered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Text(
          ll.noMatchEventsYet,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final playersById = roster.playersById;
    final timelineItems = _buildTimelineItems(ordered, ll);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      itemCount: timelineItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = timelineItems[i];
        if (item is _EventItem) {
          final event = item.event;
          if (kDebugMode) {
            final side = _resolveSide(event, roster);
            debugPrint(
              '[match-timeline][loan-detect] id=${event.idEvento} '
              'grouped=${isLoanGroupedEvent(event)} '
              'individual=${isLoanIndividualEvent(event)} '
              'sub=${leagueMatchEventTipoCambioSustitucion(event)} '
              'minuteLabel="${_minuteLabel(event)}" side=$side render=true',
            );
          }
          return LeagueMatchTimelineTab._rowForEvent(
            event,
            roster,
            playersById,
            ll,
          );
        }
        if (item is _ChipItem) {
          return LeagueMatchEventRow(
            minuteLabel: item.minuteLabel,
            text: item.body,
            side: LeagueMatchEventSide.neutral,
            neutralIcon: null,
            isLoanGrouped: false,
            isLoanIndividual: false,
          );
        }
        final section = item as _SectionItem;
        return _SpecialSectionCard(
          bodyEvents: section.bodyEvents,
          closingMarkers: section.closingMarkers,
          roster: roster,
          playersById: playersById,
          ll: ll,
        );
      },
    );
  }

  /// Límites en segundos absolutos de partido:
  /// - Primera parte estricta: < 45:00 (2700 s)
  /// - Ventana descanso / descuento 1ª: [45:00, 46:00) → [2700, 2759] aprox. (usamos < 2760)
  /// - Segunda parte normal: [46:00, 90:00) → [2760, 5399]
  /// - Final / prórroga: >= 90:00 (>= 5400)
  static List<_TimelineItem> _buildTimelineItems(
    List<LeagueMatchEvent> ordered,
    LeagueL10n ll,
  ) {
    const secondHalfStart = 46 * 60;

    final firstHalf = <LeagueMatchEvent>[];
    final secondHalfNormal = <LeagueMatchEvent>[];
    final halfTimeClosingMarkers = <LeagueMatchEvent>[];
    final secondHalfStartMarkers = <LeagueMatchEvent>[];
    final finalClosingMarkers = <LeagueMatchEvent>[];

    for (final event in ordered) {
      final sec = _eventTotalSeconds(event);

      if (_isBreakMarker(event)) {
        halfTimeClosingMarkers.add(event);
        continue;
      }
      if (_isSecondHalfStartMarker(event)) {
        secondHalfStartMarkers.add(event);
        continue;
      }
      if (_isFinalMarker(event)) {
        finalClosingMarkers.add(event);
        continue;
      }

      if (sec < secondHalfStart) {
        firstHalf.add(event);
      } else {
        secondHalfNormal.add(event);
      }
    }

    void sortAll() {
      firstHalf.sort(compareLeagueMatchEventsChrono);
      halfTimeClosingMarkers.sort(compareLeagueMatchEventsChrono);
      secondHalfStartMarkers.sort(compareLeagueMatchEventsChrono);
      secondHalfNormal.sort(compareLeagueMatchEventsChrono);
      finalClosingMarkers.sort(compareLeagueMatchEventsChrono);
    }

    sortAll();

    final items = <_TimelineItem>[...firstHalf.map(_EventItem.new)];

    if (halfTimeClosingMarkers.isNotEmpty) {
      items.add(
        _SectionItem(
          bodyEvents: const [],
          closingMarkers: halfTimeClosingMarkers,
        ),
      );
    }

    if (secondHalfStartMarkers.isNotEmpty) {
      items.add(
        _ChipItem(minuteLabel: '46′', body: ll.secondHalfStart),
      );
    }

    items.addAll(secondHalfNormal.map(_EventItem.new));

    if (finalClosingMarkers.isNotEmpty) {
      items.add(
        _SectionItem(bodyEvents: const [], closingMarkers: finalClosingMarkers),
      );
    }

    return items;
  }

  /// Fila estándar de cronología (CESION_PARTIDO, CAMBIO, gol, etc.).
  static LeagueMatchEventRow _rowForEvent(
    LeagueMatchEvent event,
    LeagueMatchRoster roster,
    Map<int, LeagueSquadPlayer> playersById,
    LeagueL10n ll,
  ) {
    final side = _resolveSide(event, roster);
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

  static LeagueMatchEventSide _resolveSide(
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

  static bool _isFinalMarker(LeagueMatchEvent e) {
    return leagueMatchEventIsFullTimeMarker(e);
  }
}

sealed class _TimelineItem {
  const _TimelineItem();
}

class _EventItem extends _TimelineItem {
  const _EventItem(this.event);
  final LeagueMatchEvent event;
}

class _ChipItem extends _TimelineItem {
  const _ChipItem({required this.minuteLabel, required this.body});
  final String minuteLabel;
  final String body;
}

class _SectionItem extends _TimelineItem {
  const _SectionItem({required this.bodyEvents, required this.closingMarkers});

  final List<LeagueMatchEvent> bodyEvents;
  final List<LeagueMatchEvent> closingMarkers;
}

class _SpecialSectionCard extends StatelessWidget {
  const _SpecialSectionCard({
    required this.bodyEvents,
    required this.closingMarkers,
    required this.roster,
    required this.playersById,
    required this.ll,
  });

  final List<LeagueMatchEvent> bodyEvents;
  final List<LeagueMatchEvent> closingMarkers;
  final LeagueMatchRoster roster;
  final Map<int, LeagueSquadPlayer> playersById;
  final LeagueL10n ll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < bodyEvents.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _buildEventRow(bodyEvents[i]),
              ],
              for (var j = 0; j < closingMarkers.length; j++) ...[
                if (bodyEvents.isNotEmpty || j > 0) const SizedBox(height: 8),
                _buildClosingChip(closingMarkers[j]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventRow(LeagueMatchEvent event) {
    return LeagueMatchTimelineTab._rowForEvent(
      event,
      roster,
      playersById,
      ll,
    );
  }

  Widget _buildClosingChip(LeagueMatchEvent marker) {
    return LeagueMatchTimelineTab._rowForEvent(
      marker,
      roster,
      playersById,
      ll,
    );
  }
}
