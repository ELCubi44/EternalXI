import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/rarity_badge.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/features/rewards/utils/reward_rarity_style.dart';
import 'package:flutter/material.dart';

Future<bool> showRewardCardDetailSheet({
  required BuildContext context,
  required RewardCardModel card,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF0E121C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _CardDetailContent(card: card),
  );
  return result == true;
}

class _CardDetailContent extends StatelessWidget {
  const _CardDetailContent({required this.card});

  final RewardCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rl10n = context.rewardsL10n;
    final s = styleForRarity(card.rareza);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final params = rl10n.parseCardParams(card.parametrosJson);
    final effectLabel = rl10n.tipoEfectoLabel(card.tipoEfecto);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _CardVisual(card: card, style: s)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.nombre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                RarityBadge(rarity: card.rareza),
              ],
            ),
            const SizedBox(height: 8),
            if (effectLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Text(
                  effectLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (effectLabel.isNotEmpty)
              const SizedBox(height: 16),
            Text(
              card.descripcion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.4,
              ),
            ),
            if (params.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: s.border.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high_rounded,
                          size: 16,
                          color: s.border.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rl10n.cardEffect,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...params.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•  ',
                              style: TextStyle(color: Colors.white54),
                            ),
                            Expanded(
                              child: Text(
                                line,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.circle,
              iconColor: card.isAvailable
                  ? const Color(0xFF81C784)
                  : Colors.white38,
              iconSize: 8,
              label: rl10n.cardStatus,
              value: rl10n.estadoLabel(card.estado),
            ),
            if (card.obtenidoEn != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                iconColor: Colors.white38,
                iconSize: 14,
                label: rl10n.cardObtained,
                value: formatRewardDateTime(context, card.obtenidoEn),
              ),
            ],
            if (card.usadoEn != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.white38,
                iconSize: 14,
                label: rl10n.cardUsedOn,
                value: formatRewardDateTime(context, card.usadoEn),
              ),
            ],
            const SizedBox(height: 20),
            if (card.isAvailable)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(rl10n.useCard),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    rl10n.cardUsedLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(rl10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  const _CardVisual({required this.card, required this.style});

  final RewardCardModel card;
  final RewardRarityStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        border: Border.all(color: style.border.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.4),
            blurRadius: rarityGlowSigma(card.rareza),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _iconForType(card.tipoEfecto),
          size: 42,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  static IconData _iconForType(String tipo) {
    switch (tipo.trim().toUpperCase()) {
      case 'SELL_PLAYER_BONUS':
        return Icons.sell_rounded;
      case 'DIRECT_CLAUSE':
        return Icons.gavel_rounded;
      case 'PROTECT_PLAYER':
        return Icons.shield_rounded;
      case 'ADD_LEAGUE_POINTS':
        return Icons.stars_rounded;
      case 'TEMPORARY_VALUE_RECOVERY':
        return Icons.trending_up_rounded;
      default:
        return Icons.style_rounded;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
