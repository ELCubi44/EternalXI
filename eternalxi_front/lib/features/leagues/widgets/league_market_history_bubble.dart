import 'package:eternal_xi/data/models/league_market_history_entry.dart';
import 'package:flutter/material.dart';

class LeagueMarketHistoryBubble extends StatelessWidget {
  const LeagueMarketHistoryBubble({super.key, required this.entry});

  final LeagueMarketHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = _normalizedType(entry.tipo);
    final accent = marketHistoryColor(context, type);
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
            child: Icon(marketHistoryIcon(type), size: 18, color: accent),
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
                        marketHistoryTitle(type),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(entry.creadoEn),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entry.descripcion, style: theme.textTheme.bodyMedium),
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
    default:
      return scheme.outline;
  }
}

String marketHistoryTitle(String tipo) {
  final type = _normalizedType(tipo);
  switch (type) {
    case 'ADJUDICACION_MERCADO':
      return 'Adjudicación';
    case 'COMPRA_DIRECTA_DOBLE':
      return 'Compra directa';
    case 'ACUERDO_USUARIOS':
      return 'Acuerdo';
    case 'VENTA_MERCADO':
      return 'Venta al mercado';
    default:
      return 'Movimiento de mercado';
  }
}

String _formatTimestamp(DateTime? value) {
  if (value == null) {
    return 'Fecha no disponible';
  }
  final d = value.toLocal();
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  if (diff == 0) {
    return 'Hoy · $hh:$mm';
  }
  if (diff == 1) {
    return 'Ayer · $hh:$mm';
  }
  final dd = d.day.toString().padLeft(2, '0');
  final mo = d.month.toString().padLeft(2, '0');
  return '$dd/$mo/${d.year} · $hh:$mm';
}
