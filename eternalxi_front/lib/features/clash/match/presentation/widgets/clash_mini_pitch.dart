import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
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
    final holder = state.ballHolderPlayer();
    final ballY = holder != null
        ? (holder.homeY * 0.55 + state.ballZone.normalizedY * 0.45)
        : state.ballZone.normalizedY;
    final ballX = holder?.homeX ?? 0.5;

    return AspectRatio(
      aspectRatio: 0.68,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E3B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ZoneBandsPainter(zone: state.ballZone),
              ),
            ),
            Center(
              child: Container(
                width: double.infinity,
                height: 1,
                color: Colors.white24,
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
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
                        holder.side == marker.side &&
                        holder.index == marker.index,
                  ),
                ),
              ),
            Positioned.fill(
              child: Align(
                alignment: Alignment(ballX * 2 - 1, ballY * 2 - 1),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
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

class _ZoneBandsPainter extends CustomPainter {
  _ZoneBandsPainter({required this.zone});

  final MatchBallZone zone;

  @override
  void paint(Canvas canvas, Size size) {
    final bandTop = (zone.normalizedY - 0.08).clamp(0.0, 1.0) * size.height;
    final bandHeight = size.height * 0.16;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, bandTop, size.width, bandHeight), paint);
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
  });

  final MatchPlayerMarker marker;
  final Color color;
  final bool isBallHolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: isBallHolder ? const EdgeInsets.all(2) : EdgeInsets.zero,
          decoration: isBallHolder
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellowAccent, width: 2),
                )
              : null,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          marker.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: isBallHolder ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
