import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_weekly_missions_home_card.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/widgets/clash_achievements_home_card.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_daily_missions_home_card.dart';
import 'package:eternal_xi/features/clash/news/presentation/widgets/clash_news_home_card.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/widgets/clash_gifts_home_card.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashHomeScreen extends StatelessWidget {
  const ClashHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ClashScreenScaffold(
      title: l10n.clashHomeTitle,
      children: [
        _ProtagonistSquadBlock(
          title: l10n.clashHomeProtagonistSquad,
          hint: l10n.clashHomeProtagonistHint,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.clashHomeMainAccess,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.xiTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        const ClashDailyMissionsHomeCard(),
        const SizedBox(height: 10),
        const ClashWeeklyMissionsHomeCard(),
        const SizedBox(height: 10),
        const ClashAchievementsHomeCard(),
        const SizedBox(height: 10),
        const ClashNewsHomeCard(),
        const SizedBox(height: 10),
        const ClashGiftsHomeCard(),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.menu_book_rounded,
          title: l10n.clashHomeStory,
          onTap: () => context.push(AppRoutes.clashStory),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.celebration_rounded,
          title: l10n.clashHomeEvents,
          onTap: ClashStoryGate.isTeamUnlocked(context)
              ? null
              : () => ClashStoryGate.showEventsLockedSnackBar(context),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.flag_rounded,
          title: l10n.clashHomeChallenges,
        ),
      ],
    );
  }
}

class _ProtagonistSquadBlock extends StatelessWidget {
  const _ProtagonistSquadBlock({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.xiDivider),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            XiColors.royalBlue.withValues(alpha: 0.18),
            XiColors.techCyan.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.xiTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (index) => CircleAvatar(
                radius: 22,
                backgroundColor: context.xiSurfaceInset,
                child: Icon(
                  Icons.person_rounded,
                  color: XiColors.royalBlue.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
