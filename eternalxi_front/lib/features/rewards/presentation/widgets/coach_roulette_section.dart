import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_coach_detail_card.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/shared/widgets/coach_roulette_icon.dart';
import 'package:flutter/material.dart';

class CoachRouletteSection extends StatelessWidget {
  const CoachRouletteSection({
    super.key,
    required this.summary,
    required this.busy,
    required this.onSpin,
  });

  final RewardSummaryModel summary;
  final bool busy;
  final VoidCallback? onSpin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rl10n = context.rewardsL10n;
    final used = summary.ruletaEntrenadorUsada;
    final coach = summary.entrenadorActual;
    final canAfford =
        summary.puntosRecompensaUsuario >= summary.costeRuletaEntrenador;
    final enabled = !used && canAfford && !busy;
    final dark = context.isXiDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: used
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.xiCompactCardGradient,
              )
            : (dark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A237E),
                      Color(0xFF311B92),
                      Color(0xFF4527A0),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: context.xiCompactCardGradient,
                  )),
        border: Border.all(color: context.xiBorderSubtle),
        boxShadow: context.xiCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                used
                    ? Icon(
                        Icons.sports_soccer_rounded,
                        color: context.xiTextPrimary,
                        size: 28,
                      )
                    : const CoachRouletteIcon(size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    used ? rl10n.yourCoach : rl10n.coachRouletteTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: context.xiTextPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!used) ...[
                  CoachRouletteInfoButton(
                    costePuntos: summary.costeRuletaEntrenador,
                  ),
                  const SizedBox(width: 6),
                ],
                if (!used && summary.costeRuletaEntrenador > 0)
                  Text(
                    formatRewardPoints(
                      summary.costeRuletaEntrenador,
                      unit: context.rewardsL10n.fichasUnit,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: dark
                          ? const Color(0xFFFFE082)
                          : XiColors.energyOrange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (used && coach != null)
              RewardCoachDetailCard(coach: coach, onDarkGradient: dark)
            else if (used)
              Text(
                rl10n.rouletteUsed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextPrimary,
                ),
              )
            else ...[
              Text(
                rl10n.coachRouletteHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              if (!canAfford)
                Text(
                  rl10n.insufficientPoints,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFFAB91),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (!canAfford) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: enabled ? onSpin : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: dark
                        ? Colors.white.withValues(alpha: 0.14)
                        : XiColors.royalBlue.withValues(alpha: 0.12),
                    foregroundColor: context.xiTextPrimary,
                    disabledBackgroundColor: dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : context.xiSurfaceInset.withValues(alpha: 0.55),
                    disabledForegroundColor:
                        context.xiTextPrimary.withValues(alpha: 0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.2)
                            : context.xiBorderSubtle,
                      ),
                    ),
                  ),
                  child: busy
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.xiTextPrimary,
                          ),
                        )
                      : Text(
                          rl10n.spin,
                          style: TextStyle(
                            fontFamily: 'Lumiare',
                            fontWeight: FontWeight.w800,
                            color: context.xiTextPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
