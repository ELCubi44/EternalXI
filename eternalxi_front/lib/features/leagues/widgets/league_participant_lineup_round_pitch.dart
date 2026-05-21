import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_lineup_empty_slot.dart';
import 'package:eternal_xi/data/models/league_participant_lineup_history.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_position_bucket.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_round_fantasy_substitution_badge.dart';
import 'package:flutter/material.dart';

/// Fallback `4-3-3` si [raw] es inválido (copia de criterio al campo editable).
({int defCount, int midCount, int fwdCount}) _parseFormationCounts(String? raw) {
  const fd = 4;
  const fm = 3;
  const fw = 3;
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  final parts =
      trimmed
          .split(RegExp(r'[-\s,/]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s.trim()))
          .toList();
  if (parts.length != 3) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  final d = parts[0];
  final m = parts[1];
  final f = parts[2];
  if (d == null || m == null || f == null || d < 0 || m < 0 || f < 0) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  if (d + m + f != 10) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  return (defCount: d, midCount: m, fwdCount: f);
}

bool _emptySlotLineMatches(LeagueSquadLine line, String rawPosicion) {
  var bucket = LeagueSquadPositionBucket.forPosition(rawPosicion);
  if (bucket == LeagueSquadLine.otros) {
    final u = rawPosicion.trim().toUpperCase();
    if (u.startsWith('DEF')) {
      bucket = LeagueSquadLine.defensas;
    } else if (u.startsWith('MED') || u.startsWith('MC')) {
      bucket = LeagueSquadLine.mediocentros;
    } else if (u.startsWith('DEL')) {
      bucket = LeagueSquadLine.delanteros;
    } else if (u.startsWith('POR') || u == 'GK') {
      bucket = LeagueSquadLine.porteros;
    }
  }
  return bucket == line;
}

bool _emptySlotOrdenMatches(int ordenBackend, int slotIndex0Based) {
  final oneBased = slotIndex0Based + 1;
  return ordenBackend == oneBased || ordenBackend == slotIndex0Based;
}

String _penaltyVisualLabel(LeagueLineupEmptySlot e) {
  final p = e.penalizacion;
  if (p < 0) {
    return '$p';
  }
  if (p > 0) {
    return '-$p';
  }
  return '0';
}

LeagueLineupEmptySlot? _penalizedMeta({
  required LeagueSquadLine line,
  required int slotIndex0Based,
  required LeagueParticipantLineupRoundPlayer? player,
  required List<LeagueLineupEmptySlot> emptySlots,
}) {
  if (player != null) {
    return null;
  }
  for (final es in emptySlots) {
    if (!es.emptySlot) {
      continue;
    }
    if (!_emptySlotLineMatches(line, es.posicion)) {
      continue;
    }
    if (!_emptySlotOrdenMatches(es.orden, slotIndex0Based)) {
      continue;
    }
    return es;
  }
  return null;
}

/// Campo de jornada del historial de alineación.
///
/// Las burbujas de puntos por jugador muestran [LeagueParticipantLineupRoundPlayer.puntosJornada]
/// (base individual, sin x2 de capitán). El total fantasy de la jornada debe mostrarse solo con
/// [LeagueParticipantLineupRoundDetail.puntosTotales] o [LeagueParticipantLineupRoundSummary.puntosTotales]
/// del API; no sumar en cliente los valores del campo.
class LeagueParticipantLineupRoundPitch extends StatelessWidget {
  const LeagueParticipantLineupRoundPitch({
    super.key,
    required this.titulares,
    required this.idCapitan,
    required this.formacionEfectiva,
    required this.emptySlots,
    required this.showJornadaPitchBadges,
    this.entrenadorAsignado,
    this.onPlayerTap,
  });

  final List<LeagueParticipantLineupRoundPlayer> titulares;
  final int idCapitan;
  final String formacionEfectiva;
  final List<LeagueLineupEmptySlot> emptySlots;

  /// `EN_CURSO` / `FINALIZADA`: burbujas de puntos en jugadores y entrenador. `PENDIENTE`: sin burbujas.
  final bool showJornadaPitchBadges;
  final LeagueCoachAssignment? entrenadorAsignado;
  final void Function(LeagueParticipantLineupRoundPlayer player)? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...titulares]..sort((a, b) => a.orden.compareTo(b.orden));
    final counts = _parseFormationCounts(formacionEfectiva);
    final normalized = _NormalizedLineup.fromPlayers(sorted);

    final gkSlots = <LeagueParticipantLineupRoundPlayer?>[
      normalized.gk.isNotEmpty ? normalized.gk.first : null,
    ];
    final defSlots = _expandLine(normalized.def, counts.defCount);
    final midSlots = _expandLine(normalized.mid, counts.midCount);
    final fwdSlots = _expandLine(normalized.fwd, counts.fwdCount);

    return AspectRatio(
      aspectRatio: 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4E6A8D), Color(0xFF1B4D32)],
          ),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2B000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _PitchMarkingsPainter()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PitchRow.line(
                      slots: gkSlots,
                      line: LeagueSquadLine.porteros,
                      idCapitan: idCapitan,
                      emptySlots: emptySlots,
                      showJornadaPitchBadges: showJornadaPitchBadges,
                      onPlayerTap: onPlayerTap,
                    ),
                    if (counts.defCount > 0)
                      _PitchRow.line(
                        slots: defSlots,
                        line: LeagueSquadLine.defensas,
                        idCapitan: idCapitan,
                        emptySlots: emptySlots,
                        showJornadaPitchBadges: showJornadaPitchBadges,
                        onPlayerTap: onPlayerTap,
                      ),
                    if (counts.midCount > 0)
                      _PitchRow.line(
                        slots: midSlots,
                        line: LeagueSquadLine.mediocentros,
                        idCapitan: idCapitan,
                        emptySlots: emptySlots,
                        showJornadaPitchBadges: showJornadaPitchBadges,
                        onPlayerTap: onPlayerTap,
                      ),
                    if (counts.fwdCount > 0)
                      _PitchRow.line(
                        slots: fwdSlots,
                        line: LeagueSquadLine.delanteros,
                        idCapitan: idCapitan,
                        emptySlots: emptySlots,
                        showJornadaPitchBadges: showJornadaPitchBadges,
                        onPlayerTap: onPlayerTap,
                      ),
                  ],
                ),
              ),
              // Esquina superior derecha del campo (no alinear con la última línea: solapa al último jugador).
              if (entrenadorAsignado != null)
                Positioned(
                  top: 8,
                  right: 4,
                  child: _RoundCoachBubble(
                    coach: entrenadorAsignado!,
                    showPointsBadge: showJornadaPitchBadges,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static List<LeagueParticipantLineupRoundPlayer?> _expandLine(
    List<LeagueParticipantLineupRoundPlayer> filled,
    int slotCount,
  ) {
    final out = List<LeagueParticipantLineupRoundPlayer?>.filled(
      slotCount,
      null,
    );
    for (var i = 0; i < filled.length && i < slotCount; i++) {
      out[i] = filled[i];
    }
    return out;
  }
}

class _RoundCoachBubble extends StatelessWidget {
  const _RoundCoachBubble({
    required this.coach,
    required this.showPointsBadge,
  });

  final LeagueCoachAssignment coach;
  final bool showPointsBadge;

  String get _displayName {
    final pila = coach.entrenadorPila?.trim() ?? '';
    if (pila.isNotEmpty) {
      return pila;
    }
    final nombre = coach.entrenadorNombre?.trim() ?? '';
    if (nombre.isEmpty) {
      return 'Coach';
    }
    return nombre;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo =
        LeagueCoachPhoto.resolveUrl(
          idEntrenador: coach.idEntrenador,
          foto: coach.foto,
        ) ??
        '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                child: ClipOval(
                  child: photo.isNotEmpty
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _coachFallbackIcon(context),
                        )
                      : _coachFallbackIcon(context),
                ),
              ),
              if (showPointsBadge)
                Positioned(
                  left: -4,
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.colorScheme.onPrimaryContainer),
                    ),
                    child: Text(
                      '${coach.puntosEntrenadorJornada}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachFallbackIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Icon(
        Icons.sports_soccer_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
    );
  }
}

class _PitchRow extends StatelessWidget {
  const _PitchRow.line({
    required this.slots,
    required this.line,
    required this.idCapitan,
    required this.emptySlots,
    required this.showJornadaPitchBadges,
    required this.onPlayerTap,
  });

  final List<LeagueParticipantLineupRoundPlayer?> slots;
  final LeagueSquadLine line;
  final int idCapitan;
  final List<LeagueLineupEmptySlot> emptySlots;
  final bool showJornadaPitchBadges;
  final void Function(LeagueParticipantLineupRoundPlayer player)? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < slots.length; i++)
          Expanded(
            child: Center(
              child: _slotCell(
                context,
                player: slots[i],
                line: line,
                slotIndex: i,
                showJornadaPitchBadges: showJornadaPitchBadges,
              ),
            ),
          ),
      ],
    );
  }

  Widget _slotCell(
    BuildContext context, {
    required LeagueParticipantLineupRoundPlayer? player,
    required LeagueSquadLine line,
    required int slotIndex,
    required bool showJornadaPitchBadges,
  }) {
    final penalized = _penalizedMeta(
      line: line,
      slotIndex0Based: slotIndex,
      player: player,
      emptySlots: emptySlots,
    );
    if (player != null) {
      return _RoundPitchPlayerBubble(
        player: player,
        isCaptain: player.idLigaJugador == idCapitan || player.capitan,
        showJornadaPitchBadges: showJornadaPitchBadges,
        showFantasyTitularSinConteoBadge:
            showJornadaPitchBadges &&
            player.fantasyTitularSinConteoPorBanquillo,
        onTap: onPlayerTap == null ? null : () => onPlayerTap!(player),
      );
    }
    if (penalized != null) {
      return _RoundPenalizedEmptyBubble(emptySlot: penalized);
    }
    return const SizedBox(width: 44, height: 76);
  }
}

class _RoundPenalizedEmptyBubble extends StatelessWidget {
  const _RoundPenalizedEmptyBubble({
    required this.emptySlot,
  });

  final LeagueLineupEmptySlot emptySlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const size = 44.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.error.withValues(alpha: 0.22),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.72),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error.withValues(alpha: 0.92),
                  size: size * 0.42,
                ),
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.88),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _penaltyVisualLabel(emptySlot),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundPitchPlayerBubble extends StatelessWidget {
  const _RoundPitchPlayerBubble({
    required this.player,
    required this.isCaptain,
    required this.showJornadaPitchBadges,
    required this.showFantasyTitularSinConteoBadge,
    this.onTap,
  });

  final LeagueParticipantLineupRoundPlayer player;
  final bool isCaptain;
  final bool showJornadaPitchBadges;
  final bool showFantasyTitularSinConteoBadge;
  final VoidCallback? onTap;

  String get _displayName {
    final preferred = player.nombreMostrado.trim().isNotEmpty
        ? player.nombreMostrado.trim()
        : player.pila.trim().isNotEmpty
        ? player.pila.trim()
        : player.nombre.trim();
    if (preferred.length <= 10) {
      return preferred;
    }
    return '${preferred.substring(0, 9)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeText = leagueRoundPlayerPitchBadgeText(
      player,
      showJornadaPitchBadges,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                    child: LeaguePlayerAvatar(
                      player: player.toSquadPlayer(),
                      size: 44,
                      circular: true,
                    ),
                  ),
                  if (badgeText.isNotEmpty)
                    Positioned(
                      left: -4,
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (showFantasyTitularSinConteoBadge)
                    Positioned(
                      left: -6,
                      top: -8,
                      child: LeagueRoundFantasySubstitutionBadge(
                        message:
                            'Titular sin puntos fantasy en esta jornada: '
                            'cuentan los del suplente de tu banquillo.',
                        iconSize: 13,
                        padding: const EdgeInsets.all(2.5),
                      ),
                    ),
                  if (isCaptain)
                    Positioned(
                      right: -4,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white70),
                        ),
                        child: Text(
                          'C',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onTertiary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NormalizedLineup {
  const _NormalizedLineup({
    required this.gk,
    required this.def,
    required this.mid,
    required this.fwd,
  });

  final List<LeagueParticipantLineupRoundPlayer> gk;
  final List<LeagueParticipantLineupRoundPlayer> def;
  final List<LeagueParticipantLineupRoundPlayer> mid;
  final List<LeagueParticipantLineupRoundPlayer> fwd;

  static String _normPos(String raw) {
    final p = raw.trim().toUpperCase();
    if (p == 'POR' || p == 'GK') {
      return 'POR';
    }
    if (p == 'DEF' || p == 'DF') {
      return 'DEF';
    }
    if (p == 'MC' || p == 'MED' || p == 'MID') {
      return 'MC';
    }
    if (p == 'DEL' || p == 'FW' || p == 'DC') {
      return 'DEL';
    }
    return 'OTRO';
  }

  /// Agrupa titulares por demarcación real (POR / DEF / MED·MC / DEL). Dentro de cada
  /// línea se respeta `orden` del snapshot. No se mueve nadie a otra línea para rellenar
  /// huecos; los slots que faltan quedan en null vía [_expandLine].
  factory _NormalizedLineup.fromPlayers(
    List<LeagueParticipantLineupRoundPlayer> players,
  ) {
    if (players.isEmpty) {
      return const _NormalizedLineup(gk: [], def: [], mid: [], fwd: []);
    }

    int ordenCmp(
      LeagueParticipantLineupRoundPlayer a,
      LeagueParticipantLineupRoundPlayer b,
    ) {
      final o = a.orden.compareTo(b.orden);
      return o != 0 ? o : a.idLigaJugador.compareTo(b.idLigaJugador);
    }

    final sorted = [...players]..sort(ordenCmp);

    List<LeagueParticipantLineupRoundPlayer> bucket(String norm) {
      return sorted
          .where((p) => _normPos(p.posicion) == norm)
          .toList(growable: false);
    }

    return _NormalizedLineup(
      gk: bucket('POR'),
      def: bucket('DEF'),
      mid: bucket('MC'),
      fwd: bucket('DEL'),
    );
  }
}

class _PitchMarkingsPainter extends CustomPainter {
  const _PitchMarkingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.006;

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      line,
    );

    final c = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawCircle(c, size.width * 0.18, line);

    final boxW = size.width * 0.42;
    final boxH = size.height * 0.22;
    canvas.drawRect(Rect.fromLTWH((size.width - boxW) / 2, 0, boxW, boxH), line);
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, size.height - boxH, boxW, boxH),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
