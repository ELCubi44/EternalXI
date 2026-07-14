import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tarjeta de evento destacado en Inicio Clash (Fase 35).
class ClashHomeFeaturedEventCard extends StatefulWidget {
  const ClashHomeFeaturedEventCard({super.key});

  @override
  State<ClashHomeFeaturedEventCard> createState() =>
      _ClashHomeFeaturedEventCardState();
}

class _ClashHomeFeaturedEventCardState
    extends State<ClashHomeFeaturedEventCard> {
  ClashCharacterEventSummary? _featured;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repo = context.read<ClashCharacterEventsRepository>();
      final summaries = await repo.fetchEventSummaries();
      final available = summaries.where((item) => item.isAvailable).toList();
      final featured = available.isEmpty
          ? null
          : available.firstWhere(
              (item) => item.event.isPinned,
              orElse: () => available.first,
            );
      if (mounted) {
        setState(() => _featured = featured);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final featured = _featured;

    if (featured == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.event_busy_rounded,
                color: context.xiTextSecondary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.clashHomeFeaturedEventTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.clashEventsHomeNone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final event = featured.event;
    final progressLabel = l10n.clashHomeFeaturedEventProgress(
      featured.completedStages,
      featured.totalStages,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              XiColors.royalBlue.withValues(alpha: 0.14),
              XiColors.classicGold.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.clashHomeFeaturedEventTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  ),
              ),
              const SizedBox(height: 4),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                progressLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.clashEventDetail(event.id)),
                  child: Text(l10n.clashHomeFeaturedEventEnter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
