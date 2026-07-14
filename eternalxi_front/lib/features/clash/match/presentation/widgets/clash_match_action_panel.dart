import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_pass_sheet.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_power_hint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel de acciones de posesión del usuario (Fase 46).
class ClashMatchActionPanel extends StatelessWidget {
  const ClashMatchActionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final match = context.watch<ClashMatchController>();
    final state = match.state;
    if (state == null) {
      return const SizedBox.shrink();
    }

    final canPass = match.canUserPass;
    final canShoot = match.canUserShoot;
    final hasDuelBlock =
        state.hasPendingDuel || state.lastDuelResolution != null;
    final awaitingDefense = state.hasPendingManualDefense;
    final advanceBlocked = hasDuelBlock || awaitingDefense;

    String? shootDisabledReason;
    if (!canShoot) {
      if (hasDuelBlock) {
        shootDisabledReason = l10n.clashMatchActionResolveDuel;
      } else if (awaitingDefense) {
        shootDisabledReason = l10n.clashMatchActionWaitDefense;
      } else if (state.ballZone != MatchBallZone.rivalArea) {
        shootDisabledReason = l10n.clashMatchStatusShootNeedArea;
      }
    }

    String? advanceDisabledReason;
    if (advanceBlocked) {
      advanceDisabledReason = awaitingDefense
          ? l10n.clashMatchActionWaitDefense
          : l10n.clashMatchActionResolveDuel;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashMatchActionPanelTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canPass
                      ? () => showClashMatchPassSheet(context)
                      : null,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(l10n.clashMatchActionPass),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: advanceBlocked ? null : match.advance,
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: Text(l10n.clashMatchActionAdvance),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (!canPass) ...[
            const SizedBox(height: 8),
            _DisabledHint(text: l10n.clashMatchPassUnavailable),
          ],
          if (advanceDisabledReason != null) ...[
            const SizedBox(height: 8),
            _DisabledHint(text: advanceDisabledReason),
          ],
          if (match.advanceChancePercent != null &&
              state.ballZone != MatchBallZone.rivalArea &&
              !advanceBlocked) ...[
            const SizedBox(height: 10),
            ClashMatchPowerHint(percent: match.advanceChancePercent!),
          ],
          const SizedBox(height: 10),
          if (canShoot)
            FilledButton.icon(
              onPressed: match.shoot,
              icon: const Icon(Icons.sports_soccer),
              label: Text(l10n.clashMatchActionShoot),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            )
          else if (shootDisabledReason != null)
            _DisabledHint(text: shootDisabledReason, prominent: true),
        ],
      ),
    );
  }
}

class _DisabledHint extends StatelessWidget {
  const _DisabledHint({required this.text, this.prominent = false});

  final String text;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: context.xiTextSecondary,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
