import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_pack_model.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/features/rewards/utils/reward_rarity_style.dart';
import 'package:eternal_xi/shared/widgets/pack_envelope_icon.dart';
import 'package:flutter/material.dart';

class RewardPackCard extends StatelessWidget {
  const RewardPackCard({
    super.key,
    required this.pack,
    required this.userPoints,
    required this.onOpen,
    required this.busy,
  });

  final RewardPackModel pack;
  final int userPoints;
  final VoidCallback? onOpen;
  final bool busy;

  LinearGradient _gradientForType() {
    switch (pack.packType) {
      case 'PREMIUM_PACK':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3E2723),
            Color(0xFF6D1A1A),
            Color(0xFFFFB300),
          ],
        );
      case 'COMMON_PACK':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF311B92),
            Color(0xFF4527A0),
          ],
        );
      case 'BASIC_PACK':
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF263238),
            Color(0xFF37474F),
            Color(0xFF5D4037),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rl10n = context.rewardsL10n;
    final canAfford = userPoints >= pack.costePuntos;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: _gradientForType(),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PackEnvelopeIcon(size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rl10n.packDisplayName(pack.packType),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                _PackInfoButton(pack: pack),
                const SizedBox(width: 6),
                Text(
                  formatRewardPoints(
                    pack.costePuntos,
                    unit: rl10n.fichasUnit,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFFE082),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              rl10n.moneyRange(
                formatRewardMoney(pack.presupuestoMin),
                formatRewardMoney(pack.presupuestoMax),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            if (!canAfford)
              Text(
                rl10n.insufficientPoints,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFFFAB91),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (canAfford && !busy) ? onOpen : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(rl10n.openPack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackInfoButton extends StatelessWidget {
  const _PackInfoButton({required this.pack});

  final RewardPackModel pack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPackProbabilities(context, pack),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

String _packProbabilityRowLabel(RewardsL10n rl10n, String key) =>
    rl10n.rarityLabel(key);

void _showPackProbabilities(BuildContext context, RewardPackModel pack) {
  final rl10n = context.rewardsL10n;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0E121C),
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final entries = pack.probabilidades.orderedEntries
          .map(
            (e) => _ProbEntry(
              _packProbabilityRowLabel(rl10n, e.key),
              e.key,
              e.value,
            ),
          )
          .toList();
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rl10n.packProbabilitiesTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1A2233),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rl10n.packDisplayName(pack.packType),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rl10n.packCost(
                      formatRewardPoints(
                        pack.costePuntos,
                        unit: rl10n.fichasUnit,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFFE082),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rl10n.packBudget(
                      formatRewardMoney(pack.presupuestoMin),
                      formatRewardMoney(pack.presupuestoMax),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text(
                rl10n.noProbabilityData,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
              )
            else
              ...entries.map((e) => _ProbRow(entry: e)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                ),
                child: Text(rl10n.close),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ProbEntry {
  const _ProbEntry(this.label, this.rarityKey, this.percent);
  final String label;
  final String rarityKey;
  final int percent;
}

class _ProbRow extends StatelessWidget {
  const _ProbRow({required this.entry});

  final _ProbEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = styleForRarity(entry.rarityKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.badgeBackground,
              border: Border.all(color: s.border.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.percent / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: s.badgeBackground,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(
              '${entry.percent}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: s.badgeForeground == Colors.black
                    ? s.badgeBackground
                    : s.badgeForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
