import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_status_badge_kind.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Lee metadata local y muestra [ClashSyncStatusBadge] (Fase 78).
///
/// No ejecuta sync ni llamadas HTTP.
class ClashSyncStatusBadgeLoader extends StatelessWidget {
  const ClashSyncStatusBadgeLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = _readOptional<ClashSyncMetadataStorage>(context);
    if (storage == null) {
      return const SizedBox.shrink();
    }
    return ClashSyncStatusBadge(
      metadata: storage.load(),
      onTap: () => context.push(AppRoutes.clashDebug),
    );
  }
}

/// Indicador compacto del estado de sync Clash basado en metadata local.
class ClashSyncStatusBadge extends StatelessWidget {
  const ClashSyncStatusBadge({super.key, required this.metadata, this.onTap});

  final ClashSyncMetadata metadata;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = ClashSyncStatusBadgePresentation.resolve(metadata);
    final theme = Theme.of(context);
    final accent = _accentColor(context, kind);
    final label = _label(l10n, kind);
    final subtitle = _subtitle(l10n, kind, metadata);

    return Semantics(
      button: onTap != null,
      label: '$label. ${l10n.clashSyncBadgeOpenDiagnostics}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.xiDivider),
            ),
            child: Row(
              children: [
                Icon(_icon(kind), size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: context.xiTextPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.xiTextSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: context.xiTextSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _label(dynamic l10n, ClashSyncStatusBadgeKind kind) {
    return switch (kind) {
      ClashSyncStatusBadgeKind.notPrepared => l10n.clashSyncBadgeNotPrepared,
      ClashSyncStatusBadgeKind.synced => l10n.clashSyncBadgeSynced,
      ClashSyncStatusBadgeKind.pendingLocal => l10n.clashSyncBadgePendingLocal,
      ClashSyncStatusBadgeKind.conflict => l10n.clashSyncBadgeConflict,
      ClashSyncStatusBadgeKind.error => l10n.clashSyncBadgeError,
      ClashSyncStatusBadgeKind.backupAvailable => l10n.clashSyncBadgeBackup,
    };
  }

  String? _subtitle(
    dynamic l10n,
    ClashSyncStatusBadgeKind kind,
    ClashSyncMetadata metadata,
  ) {
    final revision = metadata.knownServerRevision;
    final parts = <String>[];

    if (revision != null && revision > 0) {
      parts.add(l10n.clashSyncBadgeRevision(revision));
    }
    if (kind == ClashSyncStatusBadgeKind.synced &&
        metadata.lastSuccessfulSyncAt != null) {
      parts.add(
        l10n.clashSyncBadgeLastSync(
          _formatShortDate(metadata.lastSuccessfulSyncAt!),
        ),
      );
    }
    if (kind == ClashSyncStatusBadgeKind.error &&
        metadata.lastMessage != null &&
        metadata.lastMessage!.isNotEmpty) {
      parts.add(metadata.lastMessage!);
    }
    if (kind == ClashSyncStatusBadgeKind.conflict &&
        metadata.lastConflictServerRevision != null) {
      parts.add(
        l10n.clashSyncBadgeConflictRevision(
          metadata.lastConflictServerRevision!,
        ),
      );
    }

    if (parts.isEmpty) {
      return l10n.clashSyncBadgeOpenDiagnostics;
    }
    return parts.join(' · ');
  }

  Color _accentColor(BuildContext context, ClashSyncStatusBadgeKind kind) {
    return switch (kind) {
      ClashSyncStatusBadgeKind.notPrepared => context.xiTextSecondary,
      ClashSyncStatusBadgeKind.synced => XiColors.techCyan,
      ClashSyncStatusBadgeKind.pendingLocal => XiColors.royalBlue,
      ClashSyncStatusBadgeKind.conflict => XiColors.classicGold,
      ClashSyncStatusBadgeKind.error => Theme.of(context).colorScheme.error,
      ClashSyncStatusBadgeKind.backupAvailable => XiColors.royalBlue,
    };
  }

  IconData _icon(ClashSyncStatusBadgeKind kind) {
    return switch (kind) {
      ClashSyncStatusBadgeKind.notPrepared => Icons.cloud_off_outlined,
      ClashSyncStatusBadgeKind.synced => Icons.cloud_done_outlined,
      ClashSyncStatusBadgeKind.pendingLocal => Icons.sync_outlined,
      ClashSyncStatusBadgeKind.conflict => Icons.warning_amber_rounded,
      ClashSyncStatusBadgeKind.error => Icons.error_outline_rounded,
      ClashSyncStatusBadgeKind.backupAvailable => Icons.backup_outlined,
    };
  }

  String _formatShortDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

T? _readOptional<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}
