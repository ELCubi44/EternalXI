import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashTeamScreen extends StatelessWidget {
  const ClashTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClashScreenScaffold(
      title: l10n.clashTabTeam,
      children: [
        ClashSectionTile(
          icon: Icons.sports_soccer_rounded,
          title: l10n.clashTeamLineup7,
          onTap: () {
            if (!ClashStoryGate.isTeamUnlocked(context)) {
              ClashStoryGate.showTeamLockedSnackBar(context);
              return;
            }
            context.push(AppRoutes.clashTeam7v7);
          },
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.stadium_rounded,
          title: l10n.clashTeamLineup11,
          onTap: () {
            if (!ClashStoryGate.isTeamUnlocked(context)) {
              ClashStoryGate.showTeamLockedSnackBar(context);
            }
          },
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.badge_rounded,
          title: l10n.clashTeamCharacters,
          onTap: () {
            if (!ClashStoryGate.isTeamUnlocked(context)) {
              ClashStoryGate.showTeamLockedSnackBar(context);
              return;
            }
            context.push(AppRoutes.clashCards);
          },
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.trending_up_rounded,
          title: l10n.clashTeamUpgrade,
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.account_tree_rounded,
          title: l10n.clashTeamSkillTree,
        ),
      ],
    );
  }
}
