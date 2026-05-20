import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_match_detail_payload.dart';
import 'package:eternal_xi/data/models/league_match_lineup_models.dart';
import 'package:eternal_xi/data/models/league_match_live_payload.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_lineup_layout.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_coach_pitch_bubble.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

/// Alineaciones del **partido simulado** (equipos reales). Solo usa
/// [LeagueMatchDetailPayload] / [LeagueMatchLivePayload], sin datos fantasy.
class LeagueMatchLineupsTab extends StatelessWidget {
  const LeagueMatchLineupsTab({
    super.key,
    required this.payload,
    required this.summary,
    this.live,
    this.onOpenTeamPlayers,
  });

  final LeagueMatchDetailPayload payload;
  final LeagueMatchSummary summary;
  final LeagueMatchLivePayload? live;
  final Future<void> Function(int idEquipo, String? nombreEquipo, String? fotoEquipo)?
      onOpenTeamPlayers;

  static LeagueMatchLineupSide _pickSide(
    LeagueMatchLineupSide? liveSide,
    LeagueMatchLineupSide? detailSide,
  ) {
    if (liveSide != null && !liveSide.isEmpty) {
      if (detailSide != null && !detailSide.isEmpty) {
        return liveSide.mergedWithFallbackMeta(detailSide);
      }
      return liveSide;
    }
    return detailSide ??
        const LeagueMatchLineupSide(titulares: [], suplentes: []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = _pickSide(live?.lineupLocal, payload.lineupLocal);
    final vis = _pickSide(live?.lineupVisitante, payload.lineupVisitante);
    final titLoc = loc.titulares;
    final subLoc = loc.suplentes;
    final titVis = vis.titulares;
    final subVis = vis.suplentes;
    final hasAny = titLoc.isNotEmpty || titVis.isNotEmpty;
    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 30),
        child: Text(
          'Aun no hay alineaciones disponibles para este partido.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        _LineupTeamField(
          label: 'Local',
          teamName: summary.nombreLocal,
          teamId: summary.idEquipoLocal,
          escudoUrl: summary.escudoLocalUrl(),
          starters: titLoc,
          subs: subLoc,
          formationRaw: loc.formacion,
          coach: loc.entrenador,
          inverted: false,
          onOpenTeamPlayers: onOpenTeamPlayers,
        ),
        const SizedBox(height: 18),
        _LineupTeamField(
          label: 'Visitante',
          teamName: summary.nombreVisitante,
          teamId: summary.idEquipoVisitante,
          escudoUrl: summary.escudoVisitanteUrl(),
          starters: titVis,
          subs: subVis,
          formationRaw: vis.formacion,
          coach: vis.entrenador,
          inverted: true,
          onOpenTeamPlayers: onOpenTeamPlayers,
        ),
      ],
    );
  }
}

class _LineupTeamField extends StatelessWidget {
  const _LineupTeamField({
    required this.label,
    required this.teamName,
    required this.teamId,
    required this.escudoUrl,
    required this.starters,
    required this.subs,
    this.formationRaw,
    this.coach,
    required this.inverted,
    this.onOpenTeamPlayers,
  });

  final String label;
  final String teamName;
  final int teamId;
  final String? escudoUrl;
  final List<LeagueSquadPlayer> starters;
  final List<LeagueSquadPlayer> subs;
  final String? formationRaw;
  final LeagueCoachAssignment? coach;
  final bool inverted;
  final Future<void> Function(int idEquipo, String? nombreEquipo, String? fotoEquipo)?
      onOpenTeamPlayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final counts = parseMatchFormation(formationRaw);
    final slices = buildMatchPitchSlices(starters: starters, counts: counts);
    final grouped = _LineGroups(
      goalkeepers: slices.goalkeepers,
      defenders: slices.defenders,
      midfielders: slices.midfielders,
      forwards: slices.forwards,
    );
    final formationLabel = _formationDisplayLabel(formationRaw, counts);
    final rows = inverted
        ? <_LineRow>[
            _LineRow(type: _LineType.forwards, players: grouped.forwards),
            _LineRow(type: _LineType.midfielders, players: grouped.midfielders),
            _LineRow(type: _LineType.defenders, players: grouped.defenders),
            _LineRow(type: _LineType.goalkeepers, players: grouped.goalkeepers),
          ]
        : <_LineRow>[
            _LineRow(type: _LineType.goalkeepers, players: grouped.goalkeepers),
            _LineRow(type: _LineType.defenders, players: grouped.defenders),
            _LineRow(type: _LineType.midfielders, players: grouped.midfielders),
            _LineRow(type: _LineType.forwards, players: grouped.forwards),
          ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: teamId > 0 && onOpenTeamPlayers != null
                        ? () => onOpenTeamPlayers!(
                              teamId,
                              teamName.trim().isEmpty ? null : teamName.trim(),
                              escudoUrl,
                            )
                        : null,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: LeagueTeamLogo(
                          idEquipo: teamId,
                          size: 38,
                          networkImageUrl: escudoUrl,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        teamName.trim().isEmpty ? 'Equipo' : teamName.trim(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formationLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (coach != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: LeagueMatchCoachPitchBubble(
                      coach: coach!,
                      teamFormationLabel: formationLabel,
                      teamNameDisplay:
                          teamName.trim().isEmpty ? 'Equipo' : teamName.trim(),
                      teamId: teamId,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.33),
                      const Color(0xFF1B4D32),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _PitchMarkingsPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: rows
                              .map((row) => _playerLine(row, counts))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (subs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Suplentes',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subs.map((p) => _BenchChip(player: p)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _playerLine(_LineRow line, MatchFormationCounts counts) {
    final linePlayers = line.players;
    final isForwards = line.type == _LineType.forwards;
    final extraVertical = isForwards ? 8.0 : 0.0;
    if (linePlayers.isEmpty) {
      return SizedBox(height: 50 + extraVertical);
    }
    final tightMid424 = line.type == _LineType.midfielders &&
        linePlayers.length == 2 &&
        counts.defenders == 4 &&
        counts.midfielders == 2 &&
        counts.forwards == 4;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: extraVertical / 2),
      child: tightMid424
          ? Row(
              children: [
                const Spacer(flex: 2),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _FieldPlayerBubble(player: linePlayers[0]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _FieldPlayerBubble(player: linePlayers[1]),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            )
          : Row(
              children: [
                for (final p in linePlayers)
                  Expanded(
                    child: Center(child: _FieldPlayerBubble(player: p)),
                  ),
              ],
            ),
    );
  }

  static String _formationDisplayLabel(
    String? raw,
    MatchFormationCounts counts,
  ) {
    final t = raw?.trim() ?? '';
    if (t.isNotEmpty) {
      return t;
    }
    return '${counts.defenders}-${counts.midfielders}-${counts.forwards}';
  }
}

class _BenchChip extends StatelessWidget {
  const _BenchChip({required this.player});

  final LeagueSquadPlayer player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = LeagueDisplayStrings.shortNickname(
      LeagueDisplayStrings.playerShortName(
        pila: player.pila,
        nombre: player.nombre,
      ),
      maxLen: 14,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LeaguePlayerAvatar(player: player, size: 28, circular: true),
          const SizedBox(width: 6),
          Text(
            name.isEmpty ? 'Jugador' : name,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldPlayerBubble extends StatelessWidget {
  const _FieldPlayerBubble({required this.player});

  final LeagueSquadPlayer player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final short = LeagueDisplayStrings.shortNickname(
      LeagueDisplayStrings.playerShortName(
        pila: player.pila,
        nombre: player.nombre,
      ),
      maxLen: 10,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.56),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LeaguePlayerAvatar(player: player, size: 40, circular: true),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            short.isEmpty ? 'Jugador' : short,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LineGroups {
  const _LineGroups({
    required this.goalkeepers,
    required this.defenders,
    required this.midfielders,
    required this.forwards,
  });

  final List<LeagueSquadPlayer> goalkeepers;
  final List<LeagueSquadPlayer> defenders;
  final List<LeagueSquadPlayer> midfielders;
  final List<LeagueSquadPlayer> forwards;
}

enum _LineType { goalkeepers, defenders, midfielders, forwards }

class _LineRow {
  const _LineRow({required this.type, required this.players});

  final _LineType type;
  final List<LeagueSquadPlayer> players;
}

class _PitchMarkingsPainter extends CustomPainter {
  const _PitchMarkingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.006;

    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(size.shortestSide * 0.03)),
      line,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      line,
    );

    final c = Offset(size.width * 0.5, size.height * 0.5);
    final rad = size.width * 0.18;
    canvas.drawCircle(c, rad, line);

    final boxW = size.width * 0.42;
    final boxH = size.height * 0.22;
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, 0, boxW, boxH),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, size.height - boxH, boxW, boxH),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
