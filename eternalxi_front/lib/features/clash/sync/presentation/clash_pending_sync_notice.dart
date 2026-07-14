import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_pending_sync_notice_presentation.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Lee metadata local y muestra [ClashPendingSyncNotice] si aplica (Fase 80).
class ClashPendingSyncNoticeLoader extends StatefulWidget {
  const ClashPendingSyncNoticeLoader({super.key});

  @override
  State<ClashPendingSyncNoticeLoader> createState() =>
      _ClashPendingSyncNoticeLoaderState();
}

class _ClashPendingSyncNoticeLoaderState
    extends State<ClashPendingSyncNoticeLoader> {
  int? _dismissedOverride;

  @override
  Widget build(BuildContext context) {
    final metadataStorage = _readOptional<ClashSyncMetadataStorage>(context);
    final settingsStorage = _readOptional<ClashSyncSettingsStorage>(context);
    if (metadataStorage == null || settingsStorage == null) {
      return const SizedBox.shrink();
    }

    final metadata = metadataStorage.load();
    final dismissedRevision =
        _dismissedOverride ?? settingsStorage.loadDismissedPendingRevision();
    if (!ClashPendingSyncNoticePresentation.shouldShow(
      hasPendingRemoteSnapshot: metadata.hasPendingRemoteSnapshot,
      knownServerRevision: metadata.knownServerRevision,
      dismissedRevision: dismissedRevision,
    )) {
      return const SizedBox.shrink();
    }

    return ClashPendingSyncNotice(
      metadata: metadata,
      onReview: () => context.push(AppRoutes.clashDebug),
      onDismiss: () async {
        final revision = metadata.knownServerRevision;
        if (revision == null) {
          return;
        }
        await settingsStorage.dismissPendingRevision(revision);
        if (!mounted) {
          return;
        }
        setState(() => _dismissedOverride = revision);
      },
    );
  }
}

/// Aviso informativo de partida online pendiente de revisar.
class ClashPendingSyncNotice extends StatelessWidget {
  const ClashPendingSyncNotice({
    super.key,
    required this.metadata,
    required this.onReview,
    required this.onDismiss,
  });

  final ClashSyncMetadata metadata;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: XiColors.royalBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.xiDivider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 20,
              color: XiColors.royalBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clashSyncPendingNoticeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.xiTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.clashSyncPendingNoticeBody,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                      height: 1.3,
                    ),
                  ),
                  if (metadata.knownServerRevision != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.clashSyncBadgeRevision(
                        metadata.knownServerRevision!,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onReview,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.clashSyncPendingNoticeReview),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: l10n.clashSyncPendingNoticeDismiss,
              onPressed: onDismiss,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

T? _readOptional<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}
