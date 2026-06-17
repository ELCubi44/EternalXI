import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/material.dart';

/// Minicampo abstracto 7vs7 (placeholder Fase 7).
class ClashMiniPitch extends StatelessWidget {
  const ClashMiniPitch({required this.state, super.key});

  final MatchState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holder = state.ballHolder();

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
                    hasBall:
                        holder != null &&
                        holder.side == marker.side &&
                        holder.index == marker.index,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerDot extends StatelessWidget {
  const _PlayerDot({
    required this.marker,
    required this.color,
    required this.hasBall,
  });

  final MatchPlayerMarker marker;
  final Color color;
  final bool hasBall;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            if (hasBall)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          marker.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
