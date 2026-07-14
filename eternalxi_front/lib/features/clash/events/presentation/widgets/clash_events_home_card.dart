import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tarjeta compacta de eventos en Inicio Clash (Fase 33).
class ClashEventsHomeCard extends StatefulWidget {
  const ClashEventsHomeCard({super.key});

  @override
  State<ClashEventsHomeCard> createState() => _ClashEventsHomeCardState();
}

class _ClashEventsHomeCardState extends State<ClashEventsHomeCard> {
  List<ClashCharacterEventSummary> _summaries = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repo = context.read<ClashCharacterEventsRepository>();
      final summaries = await repo.fetchEventSummaries();
      if (mounted) {
        setState(() => _summaries = summaries);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final available = _summaries.where((item) => item.isAvailable).toList();
    final featured = available.isEmpty
        ? null
        : available.firstWhere(
            (item) => item.event.isPinned,
            orElse: () => available.first,
          );

    final subtitle = available.isEmpty
        ? l10n.clashEventsHomeNone
        : l10n.clashEventsHomeAvailable(available.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.celebration_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clashEventsHomeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    featured == null
                        ? subtitle
                        : '$subtitle · ${featured.event.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => context.push(AppRoutes.clashEvents),
              child: Text(l10n.clashEventsHomeView),
            ),
          ],
        ),
      ),
    );
  }
}
