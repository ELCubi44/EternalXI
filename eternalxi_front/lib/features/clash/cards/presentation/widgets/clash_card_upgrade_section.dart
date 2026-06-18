import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Sección de mejora EXP en detalle de carta (Fase 36).
class ClashCardUpgradeSection extends StatelessWidget {
  const ClashCardUpgradeSection({
    required this.entry,
    required this.materials,
    required this.isBusy,
    required this.onUseMaterial,
    super.key,
  });

  final ClashCardCatalogEntry entry;
  final List<ClashExpMaterialInventoryEntry> materials;
  final bool isBusy;
  final ValueChanged<String> onUseMaterial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final atMax = entry.isMaxLevel;

    return ClashCardDetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashActionUpgrade,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClashCardDetailMetaRow(
            label: l10n.clashCardLevel,
            value: '${entry.displayLevel} / ${entry.effectiveRarity.maxLevel}',
          ),
          if (atMax) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clashUpgradeMaxLevelHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final item in materials) ...[
            _MaterialRow(
              entry: item,
              disabled: atMax || item.quantity <= 0 || isBusy,
              onUse: () => onUseMaterial(item.material.id),
            ),
            if (item != materials.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.entry,
    required this.disabled,
    required this.onUse,
  });

  final ClashExpMaterialInventoryEntry entry;
  final bool disabled;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = entry.material;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.xiChipBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  material.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                l10n.clashExpMaterialXp(material.xpAmount),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            material.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.clashExpMaterialQuantity(entry.quantity),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton.tonal(
                onPressed: disabled ? null : onUse,
                child: Text(l10n.clashExpMaterialUseOne),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
