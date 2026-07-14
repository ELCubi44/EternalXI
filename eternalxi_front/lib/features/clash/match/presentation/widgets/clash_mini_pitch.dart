import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/material.dart';

/// Minicampo abstracto 7vs7 con zona de balón y poseedor destacado.
class ClashMiniPitch extends StatelessWidget {
  const ClashMiniPitch({required this.state, super.key});

  final MatchState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final holder = state.ballHolderPlayer();
    final duel = state.activeDuel;
    final duelPending = duel?.isPending ?? false;
    final ballY = holder != null
        ? (holder.homeY * 0.55 + state.ballZone.normalizedY * 0.45)
        : state.ballZone.normalizedY;
    final ballX = holder?.homeX ?? 0.5;

    int? duelAttackerIndex;
    int? duelDefenderIndex;
    MatchTeamSide? duelAttackerSide;
    MatchTeamSide? duelDefenderSide;
    if (duelPending && duel != null) {
      duelAttackerIndex = duel.attacker.squadIndex;
      duelAttackerSide = duel.attacker.teamSide;
      duelDefenderIndex = duel.defender.squadIndex;
      duelDefenderSide = duel.defender.teamSide;
    }

    final isShotDuel =
        duelPending && duel != null && duel.type == ClashDuelType.shotVsSave;

    return LayoutBuilder(
      builder: (context, constraints) {
        const legendSpace = 36.0;
        const minPitchHeight = 200.0;
        final width = constraints.maxWidth;
        final idealHeight = width / 0.68;
        final maxPitchHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - legendSpace).clamp(minPitchHeight, 520.0)
            : idealHeight.clamp(minPitchHeight, 520.0);
        final pitchHeight = idealHeight.clamp(minPitchHeight, maxPitchHeight);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: width,
              height: pitchHeight,
              child: _PitchCanvas(
                state: state,
                theme: theme,
                holder: holder,
                duel: duel,
                duelPending: duelPending,
                duelAttackerIndex: duelAttackerIndex,
                duelAttackerSide: duelAttackerSide,
                duelDefenderIndex: duelDefenderIndex,
                duelDefenderSide: duelDefenderSide,
                isShotDuel: isShotDuel,
                ballX: ballX,
                ballY: ballY,
              ),
            ),
            const SizedBox(height: 8),
            _PitchLegend(
              ballLabel: l10n.clashMatchPitchLegendBall,
              userLabel: l10n.clashMatchPitchLegendUser,
              rivalLabel: l10n.clashMatchPitchLegendRival,
              userColor: theme.colorScheme.primary,
            ),
          ],
        );
      },
    );
  }

  double _markerX(int index, MatchTeamSide side) =>
      _markerCoord(state, index, side).$1;

  double _markerY(int index, MatchTeamSide side) =>
      _markerCoord(state, index, side).$2;

  static (double, double) _markerCoord(
    MatchState state,
    int index,
    MatchTeamSide side,
  ) {
    final squad = state.squadFor(side);
    for (final player in squad) {
      if (player.index == index) {
        return (player.homeX, player.homeY);
      }
    }
    return (0.5, state.ballZone.normalizedY);
  }
}

class _PitchCanvas extends StatelessWidget {
  const _PitchCanvas({
    required this.state,
    required this.theme,
    required this.holder,
    required this.duel,
    required this.duelPending,
    required this.duelAttackerIndex,
    required this.duelAttackerSide,
    required this.duelDefenderIndex,
    required this.duelDefenderSide,
    required this.isShotDuel,
    required this.ballX,
    required this.ballY,
  });

  final MatchState state;
  final ThemeData theme;
  final MatchSquadPlayer? holder;
  final ClashDuelState? duel;
  final bool duelPending;
  final int? duelAttackerIndex;
  final MatchTeamSide? duelAttackerSide;
  final int? duelDefenderIndex;
  final MatchTeamSide? duelDefenderSide;
  final bool isShotDuel;
  final double ballX;
  final double ballY;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F6B45), Color(0xFF145232)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: const _PitchZonesPainter()),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ZoneBandsPainter(zone: state.ballZone),
              ),
            ),
            if (duelPending && duel != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DuelLinkPainter(
                    attackerX: ClashMiniPitch._markerCoord(
                      state,
                      duel!.attacker.squadIndex,
                      duel!.attacker.teamSide,
                    ).$1,
                    attackerY: ClashMiniPitch._markerCoord(
                      state,
                      duel!.attacker.squadIndex,
                      duel!.attacker.teamSide,
                    ).$2,
                    defenderX: ClashMiniPitch._markerCoord(
                      state,
                      duel!.defender.squadIndex,
                      duel!.defender.teamSide,
                    ).$1,
                    defenderY: ClashMiniPitch._markerCoord(
                      state,
                      duel!.defender.squadIndex,
                      duel!.defender.teamSide,
                    ).$2,
                    isShotDuel: isShotDuel,
                  ),
                ),
              ),
            if (isShotDuel && duel != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ShotGoalLinePainter(
                    attackerX: ClashMiniPitch._markerCoord(
                      state,
                      duel!.attacker.squadIndex,
                      duel!.attacker.teamSide,
                    ).$1,
                    attackerY: ClashMiniPitch._markerCoord(
                      state,
                      duel!.attacker.squadIndex,
                      duel!.attacker.teamSide,
                    ).$2,
                    goalX: 0.5,
                    goalY: duel!.attacker.teamSide == MatchTeamSide.user
                        ? 0.12
                        : 0.88,
                  ),
                ),
              ),
            Center(
              child: Container(
                width: double.infinity,
                height: 1.5,
                color: Colors.white30,
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
              ),
            ),
            for (final marker in [...state.userMarkers, ...state.rivalMarkers])
              Positioned.fill(
                child: Align(
                  alignment: Alignment(marker.x * 2 - 1, marker.y * 2 - 1),
                  child: _PlayerDot(
                    marker: marker,
                    color: marker.side == MatchTeamSide.user
                        ? theme.colorScheme.primary
                        : Colors.redAccent,
                    isBallHolder:
                        holder != null &&
                        holder!.side == marker.side &&
                        holder!.index == marker.index,
                    isDuelAttacker:
                        duelAttackerSide == marker.side &&
                        duelAttackerIndex == marker.index,
                    isDuelDefender:
                        duelDefenderSide == marker.side &&
                        duelDefenderIndex == marker.index,
                  ),
                ),
              ),
            Positioned.fill(
              child: Align(
                alignment: Alignment(ballX * 2 - 1, ballY * 2 - 1),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black38, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchLegend extends StatelessWidget {
  const _PitchLegend({
    required this.ballLabel,
    required this.userLabel,
    required this.rivalLabel,
    required this.userColor,
  });

  final String ballLabel;
  final String userLabel;
  final String rivalLabel;
  final Color userColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          _LegendItem(
            color: Colors.white,
            border: Colors.black38,
            label: ballLabel,
            labelStyle: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: 12),
          _LegendItem(
            color: userColor,
            label: userLabel,
            labelStyle: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: 12),
          _LegendItem(
            color: Colors.redAccent,
            label: rivalLabel,
            labelStyle: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.labelStyle,
    this.border,
  });

  final Color color;
  final Color? border;
  final String label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border!),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: labelStyle),
      ],
    );
  }
}

class _PitchZonesPainter extends CustomPainter {
  const _PitchZonesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final zonePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final bandHeight = size.height / 5;
    for (var i = 0; i < 5; i++) {
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(0, bandHeight * i, size.width, bandHeight),
          zonePaint,
        );
      }
      canvas.drawLine(
        Offset(0, bandHeight * (i + 1)),
        Offset(size.width, bandHeight * (i + 1)),
        linePaint,
      );
    }

    final goalWidth = size.width * 0.42;
    final goalHeight = size.height * 0.08;
    final goalLeft = (size.width - goalWidth) / 2;
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, 0, goalWidth, goalHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, size.height - goalHeight, goalWidth, goalHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DuelLinkPainter extends CustomPainter {
  _DuelLinkPainter({
    required this.attackerX,
    required this.attackerY,
    required this.defenderX,
    required this.defenderY,
    this.isShotDuel = false,
  });

  final double attackerX;
  final double attackerY;
  final double defenderX;
  final double defenderY;
  final bool isShotDuel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isShotDuel ? Colors.orangeAccent : Colors.yellowAccent)
          .withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final start = Offset(attackerX * size.width, attackerY * size.height);
    final end = Offset(defenderX * size.width, defenderY * size.height);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _DuelLinkPainter oldDelegate) =>
      oldDelegate.attackerX != attackerX ||
      oldDelegate.attackerY != attackerY ||
      oldDelegate.defenderX != defenderX ||
      oldDelegate.defenderY != defenderY ||
      oldDelegate.isShotDuel != isShotDuel;
}

class _ShotGoalLinePainter extends CustomPainter {
  _ShotGoalLinePainter({
    required this.attackerX,
    required this.attackerY,
    required this.goalX,
    required this.goalY,
  });

  final double attackerX;
  final double attackerY;
  final double goalX;
  final double goalY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final start = Offset(attackerX * size.width, attackerY * size.height);
    final end = Offset(goalX * size.width, goalY * size.height);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _ShotGoalLinePainter oldDelegate) =>
      oldDelegate.attackerX != attackerX ||
      oldDelegate.attackerY != attackerY ||
      oldDelegate.goalX != goalX ||
      oldDelegate.goalY != goalY;
}

class _ZoneBandsPainter extends CustomPainter {
  _ZoneBandsPainter({required this.zone});

  final MatchBallZone zone;

  @override
  void paint(Canvas canvas, Size size) {
    final bandTop = (zone.normalizedY - 0.08).clamp(0.0, 1.0) * size.height;
    final bandHeight = size.height * 0.16;
    final paint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, bandTop, size.width, bandHeight), paint);

    final border = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, bandTop, size.width, bandHeight), border);
  }

  @override
  bool shouldRepaint(covariant _ZoneBandsPainter oldDelegate) =>
      oldDelegate.zone != zone;
}

class _PlayerDot extends StatelessWidget {
  const _PlayerDot({
    required this.marker,
    required this.color,
    required this.isBallHolder,
    this.isDuelAttacker = false,
    this.isDuelDefender = false,
  });

  final MatchPlayerMarker marker;
  final Color color;
  final bool isBallHolder;
  final bool isDuelAttacker;
  final bool isDuelDefender;

  @override
  Widget build(BuildContext context) {
    final duelBorder = isDuelAttacker
        ? Colors.cyanAccent
        : isDuelDefender
        ? Colors.orangeAccent
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: (isBallHolder || duelBorder != null)
              ? const EdgeInsets.all(2)
              : EdgeInsets.zero,
          decoration: isBallHolder
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellowAccent, width: 2.5),
                )
              : duelBorder != null
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: duelBorder, width: 2.5),
                )
              : null,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          marker.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
