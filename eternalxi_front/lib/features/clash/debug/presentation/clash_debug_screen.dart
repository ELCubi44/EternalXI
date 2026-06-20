import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/debug/data/clash_debug_snapshot_loader.dart';
import 'package:eternal_xi/features/clash/debug/domain/clash_debug_snapshot.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashDebugScreen extends StatefulWidget {
  const ClashDebugScreen({super.key, this.sharedPreferences});

  /// Solo para tests: evita depender del singleton de [SharedPreferences].
  final SharedPreferences? sharedPreferences;

  @override
  State<ClashDebugScreen> createState() => _ClashDebugScreenState();
}

class _ClashDebugScreenState extends State<ClashDebugScreen> {
  late final Future<ClashDebugSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<ClashDebugSnapshot> _loadSnapshot() {
    final loader = ClashDebugSnapshotLoader(
      collectionStorage: context.read<ClashPlayerCollectionStorageBackend>(),
      storyRepository: context.read<ClashStoryRepository>(),
      inventoryRepository: context.read<ClashInventoryRepository>(),
      eventsRepository: context.read<ClashCharacterEventsRepository>(),
      gachaRepository: context.read<ClashGachaRepository>(),
      giftsRepository: context.read<ClashGiftsRepository>(),
      dailyMissionsRepository: context.read<ClashDailyMissionsRepository>(),
      weeklyMissionsRepository: context.read<ClashWeeklyMissionsRepository>(),
      achievementsRepository: context.read<ClashAchievementsRepository>(),
      rewardHistoryRepository: context.read<ClashRewardHistoryRepository>(),
      sharedPreferences: widget.sharedPreferences,
    );
    return loader.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clashDebugTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<ClashDebugSnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.clashDebugLoadError,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return Center(child: Text(l10n.clashDebugLoadError));
          }
          return _ClashDebugBody(snapshot: data);
        },
      ),
    );
  }
}

class _ClashDebugBody extends StatelessWidget {
  const _ClashDebugBody({required this.snapshot});

  final ClashDebugSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          l10n.clashDebugReadOnlyHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _ClashDebugSection(
          title: l10n.clashDebugSectionStorage,
          children: [
            _ClashDebugRow(
              label: l10n.clashDebugSchemaVersion,
              value: '${snapshot.schemaVersion}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugLastMigratedAt,
              value: snapshot.lastMigratedAt ?? l10n.emptyStateDash,
            ),
            _ClashDebugRow(
              label: l10n.clashDebugRewardHistoryCount,
              value: '${snapshot.rewardHistoryCount}',
            ),
          ],
        ),
        _ClashDebugSection(
          title: l10n.clashDebugSectionCollection,
          children: [
            _ClashDebugRow(
              label: l10n.clashDebugCollectionTotalCards,
              value: '${snapshot.collectionTotalCards}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugCollectionUniqueCards,
              value: '${snapshot.collectionUniqueCards}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugCollectionDuplicates,
              value: '${snapshot.collectionDuplicateCopies}',
            ),
          ],
        ),
        _ClashDebugSection(
          title: l10n.clashDebugSectionInventory,
          children: [
            _ClashDebugRow(
              label: l10n.clashDebugWalletCoins,
              value: '${snapshot.walletCoins}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugWalletGems,
              value: '${snapshot.walletGems}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugExpMaterials,
              value: '${snapshot.expMaterialQuantity}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugTechniqueBooks,
              value: '${snapshot.techniqueBookQuantity}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugEvolutionMaterials,
              value: '${snapshot.evolutionMaterialQuantity}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugTickets,
              value: '${snapshot.ticketQuantity}',
            ),
          ],
        ),
        _ClashDebugSection(
          title: l10n.clashDebugSectionEvents,
          children: [
            _ClashDebugRow(
              label: l10n.clashDebugEventsTotal,
              value: '${snapshot.totalEvents}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugEventsWithProgress,
              value: '${snapshot.eventsWithProgress}',
            ),
            for (final event in snapshot.eventProgress)
              _ClashDebugRow(
                label: event.eventTitle,
                value: l10n.clashDebugEventStagesProgress(
                  event.completedStages,
                  event.totalStages,
                ),
              ),
          ],
        ),
        _ClashDebugSection(
          title: l10n.clashDebugSectionGacha,
          children: [
            _ClashDebugRow(
              label: l10n.clashDebugGachaHistoryCount,
              value: '${snapshot.gachaHistoryCount}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugGachaDailyAvailable,
              value: '${snapshot.gachaDailyAvailableCount}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugGachaDailyUsed,
              value: '${snapshot.gachaDailyUsedCount}',
            ),
            for (final pity in snapshot.gachaPitySummaries)
              _ClashDebugRow(
                label: pity.bannerId,
                value: l10n.clashDebugGachaPityLine(
                  pity.pullsSinceLastPity,
                  pity.threshold,
                  pity.totalPulls,
                ),
              ),
          ],
        ),
        _ClashDebugSection(
          title: l10n.clashDebugSectionClaims,
          children: [
            _ClashDebugRow(
              label: l10n.clashDebugGiftsClaimed,
              value: l10n.clashDebugClaimProgress(
                snapshot.giftsClaimed,
                snapshot.giftsTotal,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugGiftsPending,
              value: '${snapshot.giftsPending}',
            ),
            _ClashDebugRow(
              label: l10n.clashDebugDailyMissionsClaimed,
              value: l10n.clashDebugClaimProgress(
                snapshot.dailyMissionsClaimed,
                snapshot.dailyMissionsTotal,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugDailyMissionsCompleted,
              value: l10n.clashDebugClaimProgress(
                snapshot.dailyMissionsCompleted,
                snapshot.dailyMissionsTotal,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugWeeklyMissionsClaimed,
              value: l10n.clashDebugClaimProgress(
                snapshot.weeklyMissionsClaimed,
                snapshot.weeklyMissionsTotal,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugWeeklyMissionsCompleted,
              value: l10n.clashDebugClaimProgress(
                snapshot.weeklyMissionsCompleted,
                snapshot.weeklyMissionsTotal,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugAchievementsClaimed,
              value: l10n.clashDebugClaimProgress(
                snapshot.achievementsClaimed,
                snapshot.achievementsTotal,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugAchievementsCompleted,
              value: l10n.clashDebugClaimProgress(
                snapshot.achievementsCompleted,
                snapshot.achievementsTotal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClashDebugSection extends StatelessWidget {
  const _ClashDebugSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _ClashDebugRow extends StatelessWidget {
  const _ClashDebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
