import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_requirement.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_service.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Sección de evolución en detalle de carta (Fase 36).
class ClashCardEvolutionSection extends StatelessWidget {
  const ClashCardEvolutionSection({
    required this.entry,
    required this.evolutionMaterials,
    required this.isBusy,
    required this.onEvolve,
    super.key,
  });

  final ClashCardCatalogEntry entry;
  final List<ClashEvolutionMaterialInventoryEntry> evolutionMaterials;
  final bool isBusy;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currentRarity = entry.effectiveRarity;
    final requirement = ClashEvolutionService.activeRequirement(
      entry.card,
      entry.progress,
    );

    return ClashCardDetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashActionEvolve,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (requirement == null) ...[
            Text(
              l10n.clashEvolutionCannotEvolveMore,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ] else ...[
            Text(
              l10n.clashEvolutionRarityArrow(
                ClashCardEvolutionResolver.rarityLabel(currentRarity),
                ClashCardEvolutionResolver.rarityLabel(requirement.toRarity),
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.clashEvolutionRequiredLevel(requirement.minLevel)),
            Text(l10n.clashEvolutionCurrentLevel(entry.displayLevel)),
            if (requirement.coinCost != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.clashEvolutionCoinsPending,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            for (final materialEntry in requirement.requiredMaterials.entries)
              _EvolutionMaterialRequirementRow(
                materialId: materialEntry.key,
                requiredQuantity: materialEntry.value,
                evolutionMaterials: evolutionMaterials,
              ),
            const SizedBox(height: 12),
            _EvolutionActionButton(
              entry: entry,
              requirement: requirement,
              evolutionMaterials: evolutionMaterials,
              isBusy: isBusy,
              onEvolve: onEvolve,
            ),
          ],
        ],
      ),
    );
  }
}

class _EvolutionMaterialRequirementRow extends StatelessWidget {
  const _EvolutionMaterialRequirementRow({
    required this.materialId,
    required this.requiredQuantity,
    required this.evolutionMaterials,
  });

  final String materialId;
  final int requiredQuantity;
  final List<ClashEvolutionMaterialInventoryEntry> evolutionMaterials;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ClashEvolutionMaterialInventoryEntry? inventoryEntry;
    for (final item in evolutionMaterials) {
      if (item.material.id == materialId) {
        inventoryEntry = item;
        break;
      }
    }
    final name = inventoryEntry?.material.name ?? materialId;
    final available = inventoryEntry?.quantity ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        l10n.clashEvolutionRequiredMaterial(name, requiredQuantity, available),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _EvolutionActionButton extends StatelessWidget {
  const _EvolutionActionButton({
    required this.entry,
    required this.requirement,
    required this.evolutionMaterials,
    required this.isBusy,
    required this.onEvolve,
  });

  final ClashCardCatalogEntry entry;
  final ClashEvolutionRequirement requirement;
  final List<ClashEvolutionMaterialInventoryEntry> evolutionMaterials;
  final bool isBusy;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress =
        entry.progress ??
        ClashCardProgress(
          cardId: entry.id,
          currentLevel: entry.displayLevel,
          currentExperience: 0,
          techniqueLevels: const {},
        );
    final quantities = {
      for (final item in evolutionMaterials) item.material.id: item.quantity,
    };
    final preview = ClashEvolutionService.previewEvolution(
      cardId: entry.id,
      card: entry.card,
      progress: progress,
      availableMaterials: quantities,
    );

    String? disabledReason;
    VoidCallback? onPressed;
    if (preview.succeeded) {
      onPressed = isBusy ? null : onEvolve;
    } else {
      disabledReason = switch (preview.error) {
        ClashEvolutionError.insufficientLevel =>
          l10n.clashEvolutionMissingLevel,
        ClashEvolutionError.insufficientMaterials =>
          l10n.clashEvolutionMissingMaterial,
        _ => l10n.clashEvolutionCannotEvolveMore,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (disabledReason != null)
          Text(
            disabledReason,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
          ),
        if (disabledReason != null) const SizedBox(height: 8),
        FilledButton(
          onPressed: onPressed,
          child: Text(l10n.clashEvolutionButton),
        ),
      ],
    );
  }
}
