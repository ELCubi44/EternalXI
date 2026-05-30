import 'package:eternal_xi/app/localization/achievement_l10n.dart';
import 'package:eternal_xi/app/localization/game_labels.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/user_progress_response.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key, this.onRetry});

  final Future<void> Function()? onRetry;

  static const _categoryIcons = <String, IconData>{
    'LEAGUE': Icons.emoji_events_outlined,
    'PERFORMANCE': Icons.bolt_outlined,
    'MARKET': Icons.storefront_outlined,
    'CARDS': Icons.style_outlined,
    'REWARDS': Icons.card_giftcard_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progressCtrl = context.watch<AccountProgressController>();
    final progress = progressCtrl.progress;

    if (progressCtrl.isLoading && progress == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (progress == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.military_tech_outlined, size: 48, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            progressCtrl.errorMessage ?? l10n.achievementsLoadError,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ],
      );
    }

    final grouped = <String, List<UserAchievement>>{};
    for (final achievement in progress.logros) {
      grouped.putIfAbsent(achievement.categoria, () => []).add(achievement);
    }

    final unlocked = progress.logros.where((a) => a.desbloqueado).length;
    final total = progress.logros.length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        if (progressCtrl.isFromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(
                l10n.achievementsFromCache,
              ),
              leading: Icon(Icons.offline_bolt_outlined, color: cs.primary),
              actions: [
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: Text(l10n.update),
                  ),
              ],
            ),
          ),
        AccountLevelDisplay(
          compact: true,
          nivel: progress.nivel,
          rango: progress.rango,
          xpEnNivel: progress.xpEnNivel,
          xpParaSiguiente: progress.xpParaSiguienteNivel,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.achievementsUnlockedSummary(unlocked, total),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          final label = GameLabels.achievementCategoryLabel(
            entry.key,
            l10n: l10n,
          );
          final icon = _categoryIcons[entry.key] ?? Icons.star_outline;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.value.map(
                  (a) => _AchievementTile(achievement: a),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final UserAchievement achievement;

  void _showInfo(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final localeCode = l10n.locale.languageCode;
    final translated = AchievementL10n.byCode(
      achievement.codigo,
      localeCode: localeCode,
    );
    final title = translated?.title ?? achievement.titulo;
    final description = translated?.description ?? achievement.descripcion;
    final info = translated?.information ?? achievement.informacion;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.info_outline_rounded,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                info,
                style: theme.textTheme.bodyMedium,
              ),
              if (achievement.tieneProgreso) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.achievementProgress(
                    achievement.progresoActual ?? 0,
                    achievement.progresoObjetivo ?? 0,
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.achievementRewardXp(achievement.xpRecompensa),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.understand),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final translated = AchievementL10n.byCode(
      achievement.codigo,
      localeCode: l10n.locale.languageCode,
    );
    final title = translated?.title ?? achievement.titulo;
    final description = translated?.description ?? achievement.descripcion;
    final cs = theme.colorScheme;
    final unlocked = achievement.desbloqueado;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: unlocked
          ? cs.primaryContainer.withValues(alpha: 0.35)
          : cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: unlocked ? cs.primary : cs.surfaceContainerHigh,
              child: Icon(
                unlocked ? Icons.check_rounded : Icons.lock_outline,
                color: unlocked ? cs.onPrimary : cs.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: unlocked ? cs.onSurface : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.achievementsHowToGet,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                        onPressed: () => _showInfo(context),
                      ),
                    ],
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (achievement.tieneProgreso) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${achievement.progresoActual}/${achievement.progresoObjetivo}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${achievement.xpRecompensa} XP',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: unlocked ? cs.primary : cs.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
