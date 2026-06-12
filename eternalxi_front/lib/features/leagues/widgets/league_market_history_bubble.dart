import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/data/models/league_market_history_entry.dart';
import 'package:eternal_xi/shared/widgets/market_agreement_icon.dart';
import 'package:eternal_xi/shared/widgets/market_bid_award_icon.dart';
import 'package:eternal_xi/shared/widgets/market_direct_buy_icon.dart';
import 'package:eternal_xi/shared/widgets/market_sale_icon.dart';
import 'package:flutter/material.dart';

class LeagueMarketHistoryBubble extends StatelessWidget {
  const LeagueMarketHistoryBubble({super.key, required this.entry});

  final LeagueMarketHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ll = context.leagueL10n;
    final type = _normalizedType(entry.tipo);
    final accent = marketHistoryColor(context, type);
    final title = ll.marketHistoryTypeTitle(type);
    final description = ll.marketHistoryDescription(
      tipo: entry.tipo,
      idUsuarioComprador: entry.idUsuarioComprador,
      compradorNombre: entry.compradorNombre,
      idUsuarioVendedor: entry.idUsuarioVendedor,
      vendedorNombre: entry.vendedorNombre,
      jugadorNombre: entry.jugadorNombre,
      precio: entry.precio,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: switch (type) {
              'COMPRA_DIRECTA_DOBLE' => const MarketDirectBuyIcon(size: 22),
              'ADJUDICACION_MERCADO' => const MarketBidAwardIcon(size: 26),
              'ACUERDO_USUARIOS' => const MarketAgreementIcon(size: 26),
              'VENTA_MERCADO' => const MarketSaleIcon(size: 22),
              _ => Icon(marketHistoryIcon(type), size: 18, color: accent),
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ll.marketHistoryTimestamp(entry.creadoEn),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _normalizedType(String rawType) => rawType.trim().toUpperCase();

IconData marketHistoryIcon(String tipo) {
  final type = _normalizedType(tipo);
  switch (type) {
    case 'ADJUDICACION_MERCADO':
      return Icons.gavel_rounded;
    case 'COMPRA_DIRECTA_DOBLE':
      return Icons.flash_on_rounded;
    case 'ACUERDO_USUARIOS':
      return Icons.handshake_rounded;
    case 'VENTA_MERCADO':
      return Icons.storefront_rounded;
    case 'ADMIN_KICK':
      return Icons.person_remove_rounded;
    default:
      return Icons.history_rounded;
  }
}

Color marketHistoryColor(BuildContext context, String tipo) {
  final scheme = Theme.of(context).colorScheme;
  final type = _normalizedType(tipo);
  switch (type) {
    case 'ADJUDICACION_MERCADO':
      return scheme.primary;
    case 'COMPRA_DIRECTA_DOBLE':
      return Colors.amber.shade700;
    case 'ACUERDO_USUARIOS':
      return Colors.green.shade600;
    case 'VENTA_MERCADO':
      return Colors.deepOrange.shade600;
    case 'ADMIN_KICK':
      return Colors.red.shade400;
    default:
      return scheme.outline;
  }
}
