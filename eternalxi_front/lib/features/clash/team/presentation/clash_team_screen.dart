import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/team/presentation/widgets/clash_team_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashTeamScreen extends StatefulWidget {
  const ClashTeamScreen({super.key});

  @override
  State<ClashTeamScreen> createState() => _ClashTeamScreenState();
}

class _ClashTeamScreenState extends State<ClashTeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ClashLineupsController>();
      if (controller.state == ClashLineupsLoadState.idle) {
        await controller.load();
      }
    });
  }

  void _openIfUnlocked(BuildContext context, VoidCallback action) {
    if (!ClashStoryGate.isTeamUnlocked(context)) {
      ClashStoryGate.showTeamLockedSnackBar(context);
      return;
    }
    action();
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.clashComingSoon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lineups = context.watch<ClashLineupsController>();
    final soon = l10n.clashTeamComingSoonBadge;

    return ClashScreenScaffold(
      title: l10n.clashTabTeam,
      children: [
        ClashTeamSummaryHeader(controller: lineups),
        const SizedBox(height: 18),
        ClashSectionTile(
          icon: Icons.sports_soccer_rounded,
          title: l10n.clashTeamLineup7,
          subtitle: l10n.clashLineupSlotsFilled(
            lineups.activeLineup == null
                ? 0
                : lineups.filledSlotCount(lineups.activeLineup!),
          ),
          onTap: () => _openIfUnlocked(
            context,
            () => context.push(AppRoutes.clashTeam7v7),
          ),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.badge_rounded,
          title: l10n.clashTeamCharacters,
          onTap: () => _openIfUnlocked(
            context,
            () => context.push(AppRoutes.clashCards),
          ),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.inventory_2_rounded,
          title: l10n.clashTeamInventory,
          onTap: () => context.push(AppRoutes.clashInventory),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.trending_up_rounded,
          title: l10n.clashTeamUpgradeCards,
          onTap: () => _openIfUnlocked(
            context,
            () => context.push(AppRoutes.clashCards),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.clashTeamComingSoonSection,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.xiTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.stadium_rounded,
          title: l10n.clashTeamLineup11,
          subtitle: soon,
          onTap: () {
            if (!ClashStoryGate.isTeamUnlocked(context)) {
              ClashStoryGate.showTeamLockedSnackBar(context);
              return;
            }
            _showComingSoon(context);
          },
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.dashboard_customize_rounded,
          title: l10n.clashTeamTactics,
          subtitle: soon,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.grid_view_rounded,
          title: l10n.clashTeamAdvancedFormations,
          subtitle: soon,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.account_tree_rounded,
          title: l10n.clashTeamSkillTree,
          subtitle: soon,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }
}
