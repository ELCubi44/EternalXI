import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_compact_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tarjeta compacta de regalos en Inicio Clash (Fase 32).
class ClashGiftsHomeCard extends StatefulWidget {
  const ClashGiftsHomeCard({super.key});

  @override
  State<ClashGiftsHomeCard> createState() => _ClashGiftsHomeCardState();
}

class _ClashGiftsHomeCardState extends State<ClashGiftsHomeCard> {
  ClashGiftsSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final repo = context.read<ClashGiftsRepository>();
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
        : summary.hasPending
        ? l10n.clashGiftsHomePending(summary.pendingCount)
        : l10n.clashGiftsHomeNone;

    final headline = summary == null || !summary.hasPending
        ? null
        : summary.latestPendingTitle;

    final detail = headline == null ? subtitle : '$subtitle · $headline';

    return ClashHomeCompactCard(
      icon: Icons.card_giftcard_rounded,
      title: l10n.clashGiftsHomeTitle,
      subtitle: detail,
      viewLabel: l10n.clashGiftsHomeView,
      onView: () => context.push(AppRoutes.clashGifts),
    );
  }
}
