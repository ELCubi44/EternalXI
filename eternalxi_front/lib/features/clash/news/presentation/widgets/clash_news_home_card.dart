import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_compact_card.dart';
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
    final summary = _summary;

    final subtitle = summary == null
        ? null
        : summary.allCaughtUp
        ? l10n.clashNewsHomeAllCaughtUp
        : l10n.clashNewsHomeUnread(summary.unreadCount);

    final headline = summary == null || summary.allCaughtUp
        ? null
        : summary.latestUnreadTitle;

    final detail = headline == null ? subtitle : '$subtitle · $headline';

    return ClashHomeCompactCard(
      icon: Icons.newspaper_rounded,
      title: l10n.clashNewsHomeTitle,
      subtitle: detail,
      viewLabel: l10n.clashNewsHomeView,
      onView: () => context.push(AppRoutes.clashNews),
    );
  }
}
