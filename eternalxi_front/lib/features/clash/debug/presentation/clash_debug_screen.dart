import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/debug/data/clash_debug_snapshot_loader.dart';
import 'package:eternal_xi/features/clash/debug/data/clash_debug_sync_controller.dart';
import 'package:eternal_xi/features/clash/debug/domain/clash_debug_bootstrap_result.dart';
import 'package:eternal_xi/features/clash/debug/domain/clash_debug_snapshot.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_online_claim_registrar.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_online_claim_registration_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashDebugScreen extends StatefulWidget {
  const ClashDebugScreen({
    super.key,
    this.sharedPreferences,
    this.syncController,
  });

  /// Solo para tests: evita depender del singleton de [SharedPreferences].
  final SharedPreferences? sharedPreferences;

  /// Inyectable en tests; si es null se crea desde [ClashSyncCoordinator].
  final ClashDebugSyncController? syncController;

  @override
  State<ClashDebugScreen> createState() => _ClashDebugScreenState();
}

class _ClashDebugScreenState extends State<ClashDebugScreen> {
  Future<ClashDebugSnapshot>? _snapshotFuture;
  ClashDebugSyncController? _syncController;
  bool _snapshotLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController ??=
        widget.syncController ??
        ClashDebugSyncController(
          coordinator: context.read<ClashSyncCoordinator>(),
          applier: _readOptional<ClashSyncSnapshotApplier>(context),
          backupStore: _readOptional<ClashSyncLocalBackupStore>(context),
          metadataStorage: _readOptional<ClashSyncMetadataStorage>(context),
          settingsStorage: _readOptional<ClashSyncSettingsStorage>(context),
          onlineClaimRegistrar: _readOptional<ClashOnlineClaimRegistrar>(
            context,
          ),
        );
    if (!_snapshotLoadStarted) {
      _snapshotLoadStarted = true;
      _snapshotFuture = _loadSnapshot();
    }
  }

  @override
  void dispose() {
    if (widget.syncController == null) {
      _syncController?.dispose();
    }
    super.dispose();
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
      body: _snapshotFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<ClashDebugSnapshot>(
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
                return _ClashDebugBody(
                  snapshot: data,
                  syncController: _syncController!,
                );
              },
            ),
    );
  }
}

class _ClashDebugBody extends StatelessWidget {
  const _ClashDebugBody({required this.snapshot, required this.syncController});

  final ClashDebugSnapshot snapshot;
  final ClashDebugSyncController syncController;

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
        _ClashDebugOnlineSyncSection(controller: syncController),
        const SizedBox(height: 8),
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

class _ClashDebugOnlineSyncSection extends StatelessWidget {
  const _ClashDebugOnlineSyncSection({required this.controller});

  final ClashDebugSyncController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final l10n = context.l10n;

        return _ClashDebugSection(
          title: l10n.clashDebugSectionOnlineSync,
          children: [
            Text(
              l10n.clashDebugSyncReadOnlyRemote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.clashDebugSyncBootstrapHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
              ),
            ),
            const SizedBox(height: 8),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLastSuccessfulSync,
              value: _formatMetadataTimestamp(
                l10n,
                controller.metadata.lastSuccessfulSyncAt,
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncKnownRevision,
              value: _knownRevisionLabel(l10n, controller),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncPersistedSummary,
              value: _persistedSummaryLabel(l10n, controller),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncPendingRemoteStatus,
              value: controller.hasPendingRemoteSnapshot
                  ? l10n.clashDebugSyncYes
                  : l10n.clashDebugSyncNo,
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLocalBackupStatus,
              value: controller.hasLocalBackup
                  ? l10n.clashDebugSyncBackupAvailable
                  : l10n.clashDebugSyncBackupUnavailable,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.clashDebugSyncAutoCheckToggle),
              subtitle: Text(
                l10n.clashDebugSyncAutoCheckHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
              ),
              value: controller.autoCheckEnabledOnClashOpen,
              onChanged: controller.busy
                  ? null
                  : controller.setAutoCheckEnabledOnClashOpen,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.clashDebugOnlineClaimsToggle),
              subtitle: Text(
                l10n.clashDebugOnlineClaimsHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
              ),
              value: controller.onlineClaimsEnabled,
              onChanged: controller.busy
                  ? null
                  : controller.setOnlineClaimsEnabled,
            ),
            OutlinedButton(
              onPressed: controller.busy
                  ? null
                  : controller.testOnlineClaimRegistration,
              child: Text(l10n.clashDebugOnlineClaimsTestAction),
            ),
            if (controller.lastOnlineClaimTestResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  _onlineClaimTestResultLabel(
                    l10n,
                    controller.lastOnlineClaimTestResult!,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _onlineClaimTestResultColor(
                      context,
                      controller.lastOnlineClaimTestResult!,
                    ),
                  ),
                ),
              ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLastValidate,
              value: _operationStatusLabel(
                l10n,
                controller.operationResultForDisplay(
                  ClashSyncOperation.validate,
                ),
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLastPull,
              value: _operationStatusLabel(
                l10n,
                controller.operationResultForDisplay(ClashSyncOperation.pull),
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLastApply,
              value: _applyStatusLabelOrDash(
                l10n,
                controller.applyResultForDisplay(restore: false),
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLastRestore,
              value: _applyStatusLabelOrDash(
                l10n,
                controller.applyResultForDisplay(restore: true),
              ),
            ),
            _ClashDebugRow(
              label: l10n.clashDebugSyncLastPush,
              value: _operationStatusLabel(
                l10n,
                controller.operationResultForDisplay(ClashSyncOperation.push),
              ),
            ),
            if (controller.metadata.lastErrorCode != null &&
                controller.metadata.lastMessage != null)
              _ClashDebugRow(
                label: l10n.clashDebugSyncPersistedError,
                value: controller.metadata.lastMessage!,
              ),
            if (controller.authRequired)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  l10n.clashDebugSyncAuthRequired,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              )
            else if (controller.isUnauthorized)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  l10n.clashDebugSyncAuthRequired,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: controller.busy
                  ? null
                  : controller.bootstrapOnlineSave,
              child: Text(l10n.clashDebugSyncBootstrapAction),
            ),
            if (controller.lastBootstrapResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  _bootstrapStatusLabel(l10n, controller.lastBootstrapResult!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _bootstrapStatusColor(
                      context,
                      controller.lastBootstrapResult!,
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: controller.busy ? null : controller.validateLocal,
                  child: Text(l10n.clashDebugSyncValidateLocal),
                ),
                OutlinedButton(
                  onPressed: controller.busy ? null : controller.pullRemote,
                  child: Text(l10n.clashDebugSyncPullRemote),
                ),
                OutlinedButton(
                  onPressed: controller.busy
                      ? null
                      : () => _confirmPushLocal(context, controller),
                  child: Text(l10n.clashDebugSyncPushLocal),
                ),
                OutlinedButton(
                  onPressed:
                      controller.busy || !controller.canApplyPendingRemote
                      ? null
                      : () => _confirmApplyRemote(context, controller),
                  child: Text(l10n.clashDebugSyncApplyRemote),
                ),
              ],
            ),
            if (controller.lastApplyResult != null &&
                controller.lastApplyResult!.message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.lastApplyResult!.message!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (controller.lastApplyResult?.isSuccess == true &&
                controller.lastApplyResult!.skippedSections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.clashDebugSyncApplySkippedSections(
                    controller.lastApplyResult!.skippedSections.join(', '),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
            if (controller.busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  String _bootstrapStatusLabel(
    AppLocalizations l10n,
    ClashDebugBootstrapResult result,
  ) {
    return switch (result.status) {
      ClashDebugBootstrapStatus.remoteFound =>
        result.serverRevision != null
            ? l10n.clashDebugSyncBootstrapRemoteFound(result.serverRevision!)
            : l10n.clashDebugSyncBootstrapRemoteFoundSimple,
      ClashDebugBootstrapStatus.remoteCreated =>
        result.serverRevision != null
            ? l10n.clashDebugSyncBootstrapRemoteCreated(result.serverRevision!)
            : l10n.clashDebugSyncBootstrapRemoteCreatedSimple,
      ClashDebugBootstrapStatus.validationFailed =>
        l10n.clashDebugSyncStatusInvalid,
      ClashDebugBootstrapStatus.unauthorized => l10n.clashDebugSyncAuthRequired,
      ClashDebugBootstrapStatus.unavailable =>
        result.message ?? l10n.clashDebugSyncUnavailable,
      ClashDebugBootstrapStatus.error =>
        result.message ?? l10n.clashDebugSyncStatusFailed,
    };
  }

  Color? _bootstrapStatusColor(
    BuildContext context,
    ClashDebugBootstrapResult result,
  ) {
    return switch (result.status) {
      ClashDebugBootstrapStatus.remoteFound ||
      ClashDebugBootstrapStatus.remoteCreated => null,
      ClashDebugBootstrapStatus.validationFailed ||
      ClashDebugBootstrapStatus.unauthorized ||
      ClashDebugBootstrapStatus.unavailable ||
      ClashDebugBootstrapStatus.error => Theme.of(context).colorScheme.error,
    };
  }

  String _onlineClaimTestResultLabel(
    AppLocalizations l10n,
    ClashOnlineClaimRegistrationResult result,
  ) {
    return switch (result.status) {
      ClashOnlineClaimRegistrationStatus.skippedDisabled =>
        l10n.clashDebugOnlineClaimsDisabled,
      ClashOnlineClaimRegistrationStatus.accepted =>
        l10n.clashDebugOnlineClaimsResultAccepted(result.claimId),
      ClashOnlineClaimRegistrationStatus.alreadyProcessed =>
        l10n.clashDebugOnlineClaimsResultAlreadyProcessed(result.claimId),
      ClashOnlineClaimRegistrationStatus.unauthorized =>
        l10n.clashDebugOnlineClaimsResultUnauthorized,
      ClashOnlineClaimRegistrationStatus.validationFailed =>
        result.errorMessage ??
            l10n.clashDebugOnlineClaimsResultValidationFailed,
      ClashOnlineClaimRegistrationStatus.conflict =>
        result.errorMessage ?? l10n.clashDebugOnlineClaimsResultConflict,
      ClashOnlineClaimRegistrationStatus.failed =>
        result.errorMessage ?? l10n.clashDebugOnlineClaimsResultFailed,
    };
  }

  Color? _onlineClaimTestResultColor(
    BuildContext context,
    ClashOnlineClaimRegistrationResult result,
  ) {
    return switch (result.status) {
      ClashOnlineClaimRegistrationStatus.accepted ||
      ClashOnlineClaimRegistrationStatus.alreadyProcessed => null,
      ClashOnlineClaimRegistrationStatus.skippedDisabled => Theme.of(
        context,
      ).textTheme.bodyMedium?.color,
      ClashOnlineClaimRegistrationStatus.unauthorized ||
      ClashOnlineClaimRegistrationStatus.validationFailed ||
      ClashOnlineClaimRegistrationStatus.conflict ||
      ClashOnlineClaimRegistrationStatus.failed => Theme.of(
        context,
      ).colorScheme.error,
    };
  }

  String _knownRevisionLabel(
    AppLocalizations l10n,
    ClashDebugSyncController controller,
  ) {
    final revision = controller.effectiveKnownRevision;
    if (revision == null || revision == 0) {
      return l10n.emptyStateDash;
    }
    return '$revision';
  }

  String _formatMetadataTimestamp(AppLocalizations l10n, DateTime? timestamp) {
    if (timestamp == null) {
      return l10n.emptyStateDash;
    }
    return timestamp.toUtc().toIso8601String();
  }

  String _persistedSummaryLabel(
    AppLocalizations l10n,
    ClashDebugSyncController controller,
  ) {
    final metadata = controller.metadata;
    final operation = metadata.lastOperation;
    if (operation == null) {
      return l10n.clashDebugSyncStatusNone;
    }
    final status = metadata.lastStatus;
    if (status == null) {
      return operation;
    }
    return '$operation · $status';
  }

  String _operationStatusLabel(
    AppLocalizations l10n,
    ClashSyncOperationResult? result,
  ) {
    if (result == null) {
      return l10n.clashDebugSyncStatusNone;
    }
    if (result.isSuccess) {
      return l10n.clashDebugSyncStatusSuccess;
    }
    if (result.isValidationFailed) {
      return l10n.clashDebugSyncStatusInvalid;
    }
    if (result.isNotFound) {
      return l10n.clashDebugSyncRemoteNotFound;
    }
    if (result.isConflict && result.conflict != null) {
      return l10n.clashDebugSyncConflict(result.conflict!.actualRevision);
    }
    if (result.errorCode == 'unauthorized') {
      return l10n.clashDebugSyncAuthRequired;
    }
    if (result.status == ClashSyncStatus.unavailable) {
      return result.message ?? l10n.clashDebugSyncUnavailable;
    }
    return result.message ?? l10n.clashDebugSyncStatusFailed;
  }

  String _applyStatusLabelOrDash(
    AppLocalizations l10n,
    ClashSyncApplyResult? result,
  ) {
    if (result == null) {
      return l10n.clashDebugSyncStatusNone;
    }
    return _applyStatusLabel(l10n, result);
  }

  Future<void> _confirmPushLocal(
    BuildContext context,
    ClashDebugSyncController controller,
  ) async {
    final l10n = context.l10n;
    final overwrite = await controller.willOverwriteRemoteSave();
    if (!context.mounted) {
      return;
    }
    if (overwrite) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.clashDebugSyncPushConfirmTitle),
          content: Text(l10n.clashDebugSyncPushConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clashDebugSyncPushConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
    }
    await controller.executePushLocal();
  }

  Future<void> _confirmApplyRemote(
    BuildContext context,
    ClashDebugSyncController controller,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clashDebugSyncApplyConfirmTitle),
        content: Text(l10n.clashDebugSyncApplyConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.clashDebugSyncApplyConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await controller.applyPendingRemote();
  }

  String _applyStatusLabel(AppLocalizations l10n, ClashSyncApplyResult result) {
    if (result.isSuccess) {
      return l10n.clashDebugSyncApplySuccess;
    }
    if (result.isValidationFailed) {
      return l10n.clashDebugSyncApplyValidationFailed;
    }
    if (result.isBackupFailed) {
      return l10n.clashDebugSyncApplyBackupFailed;
    }
    if (result.isUnsupported) {
      return l10n.clashDebugSyncApplyUnsupported;
    }
    return l10n.clashDebugSyncApplyFailed;
  }
}

T? _readOptional<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
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
                ),
            ),
          ),
        ],
      ),
    );
  }
}
