import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_icon.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashStoryRewardScreen extends StatefulWidget {
  const ClashStoryRewardScreen({required this.levelId, super.key});

  final String levelId;

  @override
  State<ClashStoryRewardScreen> createState() => _ClashStoryRewardScreenState();
}

class _ClashStoryRewardScreenState extends State<ClashStoryRewardScreen> {
  var _historyRecorded = false;
  var _xpApplied = false;
  double? _xpProgressFrom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordHistoryOnce();
      _applyAccountXpOnce();
    });
  }

  void _recordHistoryOnce() {
    if (_historyRecorded || !mounted) {
      return;
    }
    final controller = context.read<ClashStoryController>();
    final completion = controller.lastCompletion;
    if (completion == null) {
      return;
    }
    _historyRecorded = true;
    ClashRewardFeedback.recordCompletionScreenHistory(
      context,
      sourceType: ClashRewardHistorySourceType.story,
      sourceId: widget.levelId,
      title: context.l10n.clashStoryRewardTitle,
      result: ClashRewardFeedback.fromStoryReward(
        completion.rewardsGranted,
        newlyGrantedCardIds: completion.newlyGrantedCardIds,
      ),
    );
  }

  void _applyAccountXpOnce() {
    if (_xpApplied || !mounted) {
      return;
    }
    final completion = context.read<ClashStoryController>().lastCompletion;
    final xp = completion?.rewardsGranted.accountXp ?? 0;
    if (xp <= 0) {
      return;
    }
    final progressCtrl = context.read<AccountProgressController>();
    final before = progressCtrl.progress;
    if (before != null && before.xpParaSiguienteNivel > 0) {
      _xpProgressFrom =
          (before.xpEnNivel / before.xpParaSiguienteNivel).clamp(0.0, 1.0);
    }
    progressCtrl.applyOptimisticXp(xp);
    _xpApplied = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashStoryController>();
    final completion = controller.lastCompletion;
    final rewards = completion?.rewardsGranted ?? const ClashStoryReward();
    final cardsRepo = context.read<ClashCardsRepository>();
    final nextLevel = controller.nextUnlockedLevelAfter(widget.levelId);
    final isTeamFormation =
        rewards.starterRosterKey != null &&
        (completion?.newlyGrantedCardIds.isNotEmpty == true ||
            controller.progress.eternalXiCardsGranted);
    final progressCtrl = context.watch<AccountProgressController>();
    final progress = progressCtrl.progress;
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashStoryRewardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.clashStoryRewardTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashStoryRewardSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
              height: 1.35,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.clashStoryRewardXpSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            AccountLevelDisplay(
              nivel: progress.nivel,
              rango: progress.rango,
              xpEnNivel: progress.xpEnNivel,
              xpParaSiguiente: progress.xpParaSiguienteNivel,
              compact: true,
              showXpUnit: true,
              animateProgress: true,
              progressFrom: _xpProgressFrom,
              progressAnimationDuration: const Duration(milliseconds: 1100),
            ),
            if (rewards.accountXp > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.clashStoryRewardXpGain(rewards.accountXp),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ] else if (user != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => progressCtrl.loadProgress(user.id),
              child: Text(l10n.clashStoryRewardLoadXp),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            l10n.clashStoryFirstClearRewardsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          _StoryGrantedRewards(
            rewards: rewards,
            newlyGrantedCardIds: completion?.newlyGrantedCardIds ?? const [],
            cardsRepo: cardsRepo,
          ),
          if (isTeamFormation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.xiCardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.xiDivider),
              ),
              child: Text(
                l10n.clashStoryTeamFormed,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              controller.clearActiveLevel();
              controller.clearLastCompletion();
              context.go(AppRoutes.clashStory);
            },
            child: Text(l10n.clashStoryBackToMap),
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                controller.clearActiveLevel();
                controller.clearLastCompletion();
                final route = nextLevel.type == ClashStoryLevelType.story
                    ? AppRoutes.clashStoryLevel(nextLevel.id)
                    : AppRoutes.clashStoryLevelPrepare(nextLevel.id);
                context.push(route);
              },
              child: Text(l10n.clashStoryNextLevel),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryGrantedRewards extends StatelessWidget {
  const _StoryGrantedRewards({
    required this.rewards,
    required this.newlyGrantedCardIds,
    required this.cardsRepo,
  });

  final ClashStoryReward rewards;
  final List<String> newlyGrantedCardIds;
  final ClashCardsRepository cardsRepo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var items = ClashRewardDisplayBuilder.fromStoryReward(rewards, l10n);

    if (newlyGrantedCardIds.isNotEmpty) {
      items = items
          .where((item) => item.label != l10n.clashRewardLabelCardNew)
          .toList(growable: false);

      return FutureBuilder(
        future: cardsRepo.fetchAllCards(),
        builder: (context, snapshot) {
          final namesById = snapshot.hasData
              ? {for (final card in snapshot.data!) card.id: card.name}
              : null;
          final cardItems = newlyGrantedCardIds
              .map(
                (cardId) => ClashRewardDisplayItem(
                  icon: ClashRewardIcon.forKind(ClashRewardKind.cardMissing),
                  label: namesById?[cardId] ?? cardId,
                ),
              )
              .toList(growable: false);

          return ClashRewardList(
            items: [...items, ...cardItems],
            layout: ClashRewardListLayout.column,
          );
        },
      );
    }

    return ClashRewardList(items: items, layout: ClashRewardListLayout.column);
  }
}
