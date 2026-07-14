import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/shared/widgets/market_history_icon.dart';
import 'package:eternal_xi/shared/widgets/money_coins_icon.dart';
import 'package:flutter/material.dart';

class LeagueShellBudgetBar extends StatelessWidget {
  const LeagueShellBudgetBar({
    super.key,
    required this.miDinero,
    this.onOpenHistory,
  });

  final double miDinero;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = LeagueMoneyFormat.money(miDinero);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.xiBudgetBarGradient,
        ),
        border: Border.all(
          color: XiColors.classicGold.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: context.xiCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: XiColors.classicGold.withValues(alpha: 0.12),
                border: Border.all(
                  color: XiColors.classicGold.withValues(alpha: 0.35),
                ),
              ),
              child: const Center(
                child: MoneyCoinsIcon(size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.budget.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 9,
                      color: context.xiTextSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 17,
                      color: XiColors.classicGold,
                      height: 1.1,
                      shadows: [
                        Shadow(color: Color(0x55D9A441), blurRadius: 10),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.history,
              child: GestureDetector(
                onTap: onOpenHistory,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.xiChipBackground,
                    border: Border.all(color: context.xiBorderSubtle),
                  ),
                  child: const MarketHistoryIcon(size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
