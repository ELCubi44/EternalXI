import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashHeaderBar extends StatelessWidget {
  const ClashHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().currentUser;
    final nickname = user?.nickname.trim();
    final displayName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : l10n.appTitle;

    return Material(
      color: context.xiCardSurface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.xiDivider)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.xiTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.backToModeSelection,
                      onPressed: () => context.go(AppRoutes.mode),
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResourceChip(
                      icon: Icons.bolt_rounded,
                      label: l10n.clashEnergy,
                      value: '—',
                      color: XiColors.techCyan,
                    ),
                    _ResourceChip(
                      icon: Icons.paid_rounded,
                      label: l10n.clashCoins,
                      value: '—',
                      color: XiColors.classicGold,
                    ),
                    _ResourceChip(
                      icon: Icons.diamond_rounded,
                      label: l10n.clashGems,
                      value: '—',
                      color: XiColors.royalBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
