import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel de turno rival con IA básica (Fase 13).
class ClashMatchRivalTurnPanel extends StatelessWidget {
  const ClashMatchRivalTurnPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final match = context.watch<ClashMatchController>();
    final state = match.state;
    if (state == null || state.possession != MatchTeamSide.rival) {
      return const SizedBox.shrink();
    }

    final holder = state.ballHolderPlayer();
    final lastDecision = match.lastRivalAiDecision;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashMatchRivalTurnTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
            ),
          ),
          if (holder != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clashMatchBallHolder(holder.label),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${l10n.clashMatchZoneLabel}: ${state.ballZone.labelEs()}',
              textAlign: TextAlign.center,
            ),
            Text(
              l10n.clashMatchPtStaminaLabel(
                holder.currentPt,
                holder.maxPt,
                holder.currentStamina,
                holder.maxStamina,
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          if (lastDecision != null) ...[
            const SizedBox(height: 10),
            Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  lastDecision.summary,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.hasPendingDuel || state.lastDuelResolution != null
                ? null
                : match.continueRivalTurn,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.clashMatchActionRivalContinue),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
