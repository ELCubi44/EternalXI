import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_action.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel de turno rival con IA básica (Fase 13).
class ClashMatchRivalTurnPanel extends StatelessWidget {
  const ClashMatchRivalTurnPanel({super.key});

  String? _contextHint(BuildContext context, ClashMatchController match) {
    final l10n = context.l10n;
    final state = match.state;
    if (state == null) {
      return null;
    }
    if (state.hasPendingManualDefense) {
      return l10n.clashMatchRivalAwaitingDefense;
    }
    final decision = match.lastRivalAiDecision;
    if (decision == null) {
      return null;
    }
    return switch (decision.action) {
      ClashRivalAiAction.advance => l10n.clashMatchRivalPreparingAdvance,
      ClashRivalAiAction.shoot => l10n.clashMatchRivalPreparingShot,
      ClashRivalAiAction.pass => decision.summary,
    };
  }

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
    final contextHint = _contextHint(context, match);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smart_toy_outlined, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                l10n.clashMatchRivalTurnTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          if (contextHint != null) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  contextHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent.shade200,
                  ),
                ),
              ),
            ),
          ],
          if (holder != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashMatchBallHolder(holder.label),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
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
          if (lastDecision != null && contextHint != lastDecision.summary) ...[
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
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
