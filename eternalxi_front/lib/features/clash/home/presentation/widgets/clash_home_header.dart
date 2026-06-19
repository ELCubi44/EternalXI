import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Cabecera principal del hub Inicio Clash (Fase 35).
class ClashHomeHeader extends StatelessWidget {
  const ClashHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = context.watch<ClashStoryController>().progress;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.xiDivider),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            XiColors.royalBlue.withValues(alpha: 0.2),
            XiColors.techCyan.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashHomeHubTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: context.xiTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.clashHomeHubSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResourceChip(
                icon: Icons.diamond_rounded,
                label: l10n.clashGems,
                value: '${progress.walletGems}',
                color: XiColors.royalBlue,
              ),
              _ResourceChip(
                icon: Icons.paid_rounded,
                label: l10n.clashCoins,
                value: '${progress.walletCoins}',
                color: XiColors.classicGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(l10n.backToModeSelection),
                onPressed: () => context.go(AppRoutes.mode),
              ),
              ActionChip(
                avatar: const Icon(Icons.help_outline_rounded, size: 18),
                label: Text(l10n.clashHelpTitle),
                onPressed: () => context.push(AppRoutes.clashHelp),
              ),
              ActionChip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text(l10n.clashInventoryTitle),
                onPressed: () => context.push(AppRoutes.clashInventory),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.xiTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
