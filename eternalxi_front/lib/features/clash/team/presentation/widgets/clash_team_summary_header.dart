import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';

/// Resumen de alineación activa en pantalla Equipo (Fase 37).
class ClashTeamSummaryHeader extends StatelessWidget {
  const ClashTeamSummaryHeader({required this.controller, super.key});

  final ClashLineupsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = controller.activeLineup;
    final loading =
        controller.state == ClashLineupsLoadState.loading ||
        controller.state == ClashLineupsLoadState.idle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashTeamSummaryTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 4),
            )
          else if (active == null)
            Text(
              l10n.clashTeamNoActiveLineup,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            )
          else ...[
            Text(
              l10n.clashTeamActiveLineup,
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.xiTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              active.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.clashLineupSlotsFilled(
                      controller.filledSlotCount(active),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ),
                Text(
                  '${l10n.clashLineupTotalPower}: ${controller.totalPower(active)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusChip(
              isComplete: active.isComplete,
              missingGoalkeeper: controller.isMissingGoalkeeper(active),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.isComplete,
    required this.missingGoalkeeper,
  });

  final bool isComplete;
  final bool missingGoalkeeper;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final String label;
    final Color color;
    final IconData icon;

    if (isComplete) {
      label = l10n.clashLineupReadyToPlay;
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (missingGoalkeeper) {
      label = l10n.clashLineupNoGoalkeeper;
      color = theme.colorScheme.error;
      icon = Icons.warning_amber_rounded;
    } else {
      label = l10n.clashLineupIncomplete;
      color = theme.colorScheme.error;
      icon = Icons.info_outline_rounded;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
    );
  }
}
