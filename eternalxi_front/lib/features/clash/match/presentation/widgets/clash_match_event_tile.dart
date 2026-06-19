import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:flutter/material.dart';

/// Fila compacta de un evento del partido (Fase 46).
class ClashMatchEventTile extends StatelessWidget {
  const ClashMatchEventTile({required this.event, super.key});

  final MatchEvent event;

  static IconData iconFor(MatchEventType type) {
    return switch (type) {
      MatchEventType.passSuccess => Icons.swap_horiz_rounded,
      MatchEventType.passFail => Icons.swap_horiz_rounded,
      MatchEventType.advanceSuccess => Icons.arrow_upward_rounded,
      MatchEventType.advanceFail => Icons.arrow_upward_rounded,
      MatchEventType.duelStarted => Icons.sports_martial_arts_outlined,
      MatchEventType.duelSuccess => Icons.check_circle_outline,
      MatchEventType.duelFail => Icons.block_outlined,
      MatchEventType.duelTechniqueUsed => Icons.bolt_rounded,
      MatchEventType.shotDuelStarted => Icons.sports_soccer_outlined,
      MatchEventType.saveMade => Icons.back_hand_outlined,
      MatchEventType.goal => Icons.sports_soccer,
      MatchEventType.kickoff => Icons.flag_outlined,
      MatchEventType.rivalAction => Icons.smart_toy_outlined,
      MatchEventType.possessionLost => Icons.swap_horiz_rounded,
      MatchEventType.halftimeStarted => Icons.free_breakfast_outlined,
      MatchEventType.halftimeEnded => Icons.play_arrow_rounded,
      MatchEventType.halftimeItemUsed => Icons.medical_services_outlined,
    };
  }

  static Color? colorFor(BuildContext context, MatchEventType type) {
    return switch (type) {
      MatchEventType.goal => Colors.green,
      MatchEventType.passSuccess ||
      MatchEventType.advanceSuccess ||
      MatchEventType.duelSuccess => Theme.of(context).colorScheme.primary,
      MatchEventType.passFail ||
      MatchEventType.advanceFail ||
      MatchEventType.duelFail => Colors.redAccent,
      MatchEventType.saveMade => Colors.blueAccent,
      MatchEventType.shotDuelStarted => Colors.orange,
      _ => context.xiTextSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = iconFor(event.type);
    final color = colorFor(context, event.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (color ?? theme.colorScheme.surfaceContainerHighest)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
