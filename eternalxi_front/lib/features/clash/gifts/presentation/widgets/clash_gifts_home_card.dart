import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
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
    final theme = Theme.of(context);
    final summary = _summary;

    final subtitle = summary == null
        ? null
        : summary.hasPending
        ? l10n.clashGiftsHomePending(summary.pendingCount)
        : l10n.clashGiftsHomeNone;

    final headline = summary == null || !summary.hasPending
        ? null
        : summary.latestPendingTitle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clashGiftsHomeTitle,
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
              onPressed: () => context.push(AppRoutes.clashGifts),
              child: Text(l10n.clashGiftsHomeView),
            ),
          ],
        ),
      ),
    );
  }
}
