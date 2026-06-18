import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tarjeta compacta de noticias en Inicio Clash (Fase 31).
class ClashNewsHomeCard extends StatefulWidget {
  const ClashNewsHomeCard({super.key});

  @override
  State<ClashNewsHomeCard> createState() => _ClashNewsHomeCardState();
}

class _ClashNewsHomeCardState extends State<ClashNewsHomeCard> {
  ClashNewsSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final repo = context.read<ClashNewsRepository>();
      final summary = await repo.fetchSummary();
      if (mounted) {
        setState(() => _summary = summary);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = _summary;

    final subtitle = summary == null
        ? null
        : summary.allCaughtUp
        ? l10n.clashNewsHomeAllCaughtUp
        : l10n.clashNewsHomeUnread(summary.unreadCount);

    final headline = summary == null
        ? null
        : summary.allCaughtUp
        ? null
        : summary.latestUnreadTitle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.newspaper_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clashNewsHomeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      headline == null ? subtitle : '$subtitle · $headline',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => context.push(AppRoutes.clashNews),
              child: Text(l10n.clashNewsHomeView),
            ),
          ],
        ),
      ),
    );
  }
}
