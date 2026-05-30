import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botón de recompensas genérico (fuera de liga): solo icono, sin contador.
class UserTokensAction extends StatelessWidget {
  const UserTokensAction({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: () => context.push(AppRoutes.rewardsShop()),
        icon: Icon(
          Icons.storefront_rounded,
          color: colorScheme.primary,
        ),
        tooltip: context.l10n.rewards,
      ),
    );
  }
}

/// Chip de puntos de recompensa de una liga (dentro de liga): muestra contador.
class LeagueRewardPointsAction extends StatelessWidget {
  const LeagueRewardPointsAction({
    super.key,
    required this.idLiga,
    required this.puntos,
  });

  final int idLiga;
  final int puntos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 400;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ActionChip(
        onPressed: () => context.push(AppRoutes.rewardsShop(idLiga: idLiga)),
        avatar: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFD54F),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.star_rounded,
            size: 14,
            color: Color(0xFF1A237E),
          ),
        ),
        label: Text(
          formatRewardPointsForChip(puntos, compact: compact),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        backgroundColor: colorScheme.secondaryContainer,
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        tooltip: context.rewardsL10n.rewardPointsTooltip,
      ),
    );
  }
}
