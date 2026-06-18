import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Estado vacío de la colección Clash (Fase 36).
class ClashCollectionEmptyState extends StatelessWidget {
  const ClashCollectionEmptyState({
    required this.controller,
    this.onClearFilters,
    super.key,
  });

  final ClashCardsController controller;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final filtered = controller.ownedCount > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.filter_alt_off_rounded : Icons.style_rounded,
              size: 56,
              color: context.xiTextSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? l10n.clashCollectionEmptyTitle
                  : l10n.clashCollectionEmptyOwnedTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? l10n.clashCollectionEmptyFiltered
                  : l10n.clashCollectionEmptyOwned,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (filtered) ...[
              FilledButton.tonal(
                onPressed: onClearFilters ?? controller.clearFilters,
                child: Text(l10n.clashCollectionClearFilters),
              ),
            ] else ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.clash),
                    child: Text(l10n.clashBack),
                  ),
                  FilledButton.tonal(
                    onPressed: () => context.push(AppRoutes.clashStory),
                    child: Text(l10n.clashCollectionGoStory),
                  ),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.clash),
                    child: Text(l10n.clashCollectionGoSummon),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
