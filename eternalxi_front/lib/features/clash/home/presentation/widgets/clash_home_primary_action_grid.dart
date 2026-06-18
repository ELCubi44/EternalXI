import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Accesos principales destacados en Inicio Clash (Fase 35).
class ClashHomePrimaryActionGrid extends StatelessWidget {
  const ClashHomePrimaryActionGrid({super.key});

  void _goToTab(BuildContext context, int tabIndex) {
    context.read<ClashNavigationController>().selectTab(tabIndex);
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      final path = GoRouterState.of(context).uri.path;
      if (path != AppRoutes.clash) {
        context.go(AppRoutes.clash);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final teamUnlocked = context
        .watch<ClashStoryController>()
        .clashTeamUnlocked;

    final actions = <_PrimaryAction>[
      _PrimaryAction(
        icon: Icons.menu_book_rounded,
        title: l10n.clashHomeStory,
        description: l10n.clashHomePrimaryStoryDesc,
        onTap: () => context.push(AppRoutes.clashStory),
      ),
      _PrimaryAction(
        icon: Icons.celebration_rounded,
        title: l10n.clashHomeEvents,
        description: l10n.clashHomePrimaryEventsDesc,
        onTap: () => context.push(AppRoutes.clashEvents),
      ),
      _PrimaryAction(
        icon: Icons.groups_rounded,
        title: l10n.clashTabTeam,
        description: l10n.clashHomePrimaryTeamDesc,
        locked: !teamUnlocked,
        onTap: teamUnlocked ? () => _goToTab(context, 1) : null,
      ),
      _PrimaryAction(
        icon: Icons.auto_awesome_rounded,
        title: l10n.clashTabSummon,
        description: l10n.clashHomePrimarySummonDesc,
        onTap: () => _goToTab(context, 2),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) =>
          _PrimaryActionTile(action: actions[index]),
    );
  }
}

class _PrimaryAction {
  const _PrimaryAction({
    required this.icon,
    required this.title,
    required this.description,
    this.locked = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool locked;
  final VoidCallback? onTap;
}

class _PrimaryActionTile extends StatelessWidget {
  const _PrimaryActionTile({required this.action});

  final _PrimaryAction action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final enabled = !action.locked && action.onTap != null;

    return Material(
      color: context.xiCardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.xiDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled
            ? action.onTap
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(l10n.clashHomePrimaryLocked),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    action.locked ? Icons.lock_rounded : action.icon,
                    color: enabled
                        ? theme.colorScheme.primary
                        : context.xiTextSecondary,
                  ),
                  const Spacer(),
                  if (action.locked)
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: context.xiTextSecondary.withValues(alpha: 0.7),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.xiTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
