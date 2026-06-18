import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_requirement.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_definition.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_node.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_unlock_result.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashCardDetailScreen extends StatefulWidget {
  const ClashCardDetailScreen({required this.cardId, super.key});

  final String cardId;

  @override
  State<ClashCardDetailScreen> createState() => _ClashCardDetailScreenState();
}

class _ClashCardDetailScreenState extends State<ClashCardDetailScreen> {
  ClashCardCatalogEntry? _entry;
  List<ClashExpMaterialInventoryEntry> _materials = const [];
  List<ClashTechniqueBookInventoryEntry> _techniqueBooks = const [];
  List<ClashEvolutionMaterialInventoryEntry> _evolutionMaterials = const [];
  bool _loading = true;
  bool _notFound = false;
  bool _usingMaterial = false;
  bool _evolving = false;
  bool _unlockingSkillNode = false;
  String? _usingTechniqueBookFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCard());
  }

  Future<void> _loadCard() async {
    final controller = context.read<ClashCardsController>();
    final collection = context.read<ClashPlayerCollectionRepository>();
    final materialsRepo = context.read<ClashExpMaterialsRepository>();
    final techniqueBooksRepo = context.read<ClashTechniqueBooksRepository>();
    final evolutionMaterialsRepo = context
        .read<ClashEvolutionMaterialsRepository>();
    if (controller.state == ClashCardsLoadState.idle) {
      await controller.load();
    }
    final entry = await controller.findCard(widget.cardId);
    final inventory = await materialsRepo.fetchInventoryEntries();
    final techniqueBooks = await techniqueBooksRepo.fetchInventoryEntries();
    final evolutionMaterials = await evolutionMaterialsRepo
        .fetchInventoryEntries();
    if (!mounted) {
      return;
    }
    setState(() {
      _entry = entry == null ? null : collection.enrichEntry(entry);
      _materials = inventory;
      _techniqueBooks = techniqueBooks;
      _evolutionMaterials = evolutionMaterials;
      _notFound = entry == null;
      _loading = false;
    });
  }

  Future<void> _useTechniqueBook(String techniqueId, String bookId) async {
    if (_usingTechniqueBookFor != null || _entry == null) {
      return;
    }

    setState(() => _usingTechniqueBookFor = techniqueId);
    final collection = context.read<ClashPlayerCollectionRepository>();
    final techniqueBooksRepo = context.read<ClashTechniqueBooksRepository>();
    final controller = context.read<ClashCardsController>();

    final result = await collection.useTechniqueBookOnCard(
      cardId: widget.cardId,
      techniqueId: techniqueId,
      bookId: bookId,
    );

    if (!mounted) {
      return;
    }

    if (result.succeeded) {
      final entry = await controller.findCard(widget.cardId);
      final books = await techniqueBooksRepo.fetchInventoryEntries();
      setState(() {
        _entry = entry == null ? null : collection.enrichEntry(entry);
        _techniqueBooks = books;
        _usingTechniqueBookFor = null;
      });
      await controller.reloadOwnedCards();
      _showTechniqueBookResultSnackBar(result);
    } else {
      setState(() => _usingTechniqueBookFor = null);
    }
  }

  void _showTechniqueBookResultSnackBar(ClashTechniqueBookUseResult result) {
    final l10n = context.l10n;
    final technique = _entry?.card.superTechniques.firstWhere(
      (item) => item.id == result.techniqueId,
      orElse: () => _entry!.card.superTechniques.first,
    );
    final name = technique?.name ?? result.techniqueId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          l10n.clashTechniqueLevelUpSnack(
            name,
            result.previousLevel.displayLabel,
            result.newLevel.displayLabel,
          ),
        ),
      ),
    );
  }

  Future<void> _evolveCard() async {
    if (_evolving || _entry == null) {
      return;
    }

    setState(() => _evolving = true);
    final collection = context.read<ClashPlayerCollectionRepository>();
    final evolutionMaterialsRepo = context
        .read<ClashEvolutionMaterialsRepository>();
    final controller = context.read<ClashCardsController>();

    final result = await collection.evolveCard(cardId: widget.cardId);

    if (!mounted) {
      return;
    }

    if (result.succeeded) {
      final entry = await controller.findCard(widget.cardId);
      final evolutionMaterials = await evolutionMaterialsRepo
          .fetchInventoryEntries();
      setState(() {
        _entry = entry == null ? null : collection.enrichEntry(entry);
        _evolutionMaterials = evolutionMaterials;
        _evolving = false;
      });
      await controller.reloadOwnedCards();
      _showEvolutionSnackBar(result);
    } else {
      setState(() => _evolving = false);
    }
  }

  void _showEvolutionSnackBar(ClashEvolutionResult result) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          l10n.clashEvolutionSnack(
            ClashCardEvolutionResolver.rarityLabel(result.previousRarity),
            ClashCardEvolutionResolver.rarityLabel(result.newRarity),
          ),
        ),
      ),
    );
  }

  Future<void> _unlockSkillTreeNode(String nodeId) async {
    if (_unlockingSkillNode || _entry == null) {
      return;
    }

    setState(() => _unlockingSkillNode = true);
    final collection = context.read<ClashPlayerCollectionRepository>();
    final controller = context.read<ClashCardsController>();

    final result = await collection.unlockSkillTreeNode(
      cardId: widget.cardId,
      nodeId: nodeId,
    );

    if (!mounted) {
      return;
    }

    if (result.succeeded) {
      final entry = await controller.findCard(widget.cardId);
      setState(() {
        _entry = entry == null ? null : collection.enrichEntry(entry);
        _unlockingSkillNode = false;
      });
      await controller.reloadOwnedCards();
      _showSkillTreeUnlockSnackBar(result);
    } else {
      setState(() => _unlockingSkillNode = false);
    }
  }

  void _showSkillTreeUnlockSnackBar(ClashSkillTreeUnlockResult result) {
    final l10n = context.l10n;
    final boost = result.boostLabel ?? result.nodeId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.clashSkillTreeUnlockSnack(boost)),
      ),
    );
  }

  Future<void> _useMaterial(String materialId) async {
    if (_usingMaterial || _entry == null || _entry!.isMaxLevel) {
      return;
    }

    setState(() => _usingMaterial = true);
    final collection = context.read<ClashPlayerCollectionRepository>();
    final materialsRepo = context.read<ClashExpMaterialsRepository>();
    final controller = context.read<ClashCardsController>();

    final result = await collection.useExpMaterialOnCard(
      cardId: widget.cardId,
      materialId: materialId,
      quantity: 1,
    );

    if (!mounted) {
      return;
    }

    if (result.succeeded) {
      final entry = await controller.findCard(widget.cardId);
      final inventory = await materialsRepo.fetchInventoryEntries();
      setState(() {
        _entry = entry == null ? null : collection.enrichEntry(entry);
        _materials = inventory;
        _usingMaterial = false;
      });
      await controller.reloadOwnedCards();
      _showUseResultSnackBar(result);
    } else {
      setState(() => _usingMaterial = false);
    }
  }

  void _showUseResultSnackBar(ClashExpMaterialUseResult result) {
    final l10n = context.l10n;
    final message = StringBuffer(l10n.clashExpMaterialXp(result.xpGained));
    if (result.didLevelUp) {
      message
        ..write('\n')
        ..write(
          l10n.clashExpMaterialLevelUp(result.previousLevel, result.newLevel),
        );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notFound || _entry == null) {
      return _ErrorState(message: l10n.clashCardNotFound);
    }

    final entry = _entry!;
    final card = entry.displayCard;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                entry.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.xiTextPrimary,
                ),
              ),
            ),
            ClashRarityBadge(rarity: entry.effectiveRarity),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final portrait = ClashCardPortrait(
              name: entry.name,
              imagePath: card.basicPortraitPath,
              height: wide ? 320 : 260,
              borderRadius: 18,
            );

            final info = _InfoPanel(entry: entry);

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: portrait),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        info,
                        const SizedBox(height: 12),
                        _XpPanel(entry: entry),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                portrait,
                const SizedBox(height: 16),
                info,
                const SizedBox(height: 12),
                _XpPanel(entry: entry),
              ],
            );
          },
        ),
        for (final technique in card.superTechniques) ...[
          const SizedBox(height: 20),
          _TechniquePanel(
            baseTechnique: technique,
            progress: entry.progress,
            books: _techniqueBooks,
            isBusy: _usingTechniqueBookFor == technique.id,
            onUseBook: (bookId) => _useTechniqueBook(technique.id, bookId),
          ),
        ],
        const SizedBox(height: 16),
        _UpgradePanel(
          entry: entry,
          materials: _materials,
          isBusy: _usingMaterial,
          onUseMaterial: _useMaterial,
        ),
        const SizedBox(height: 16),
        _EvolutionPanel(
          entry: entry,
          evolutionMaterials: _evolutionMaterials,
          isBusy: _evolving,
          onEvolve: _evolveCard,
        ),
        const SizedBox(height: 16),
        _SkillTreePanel(
          entry: entry,
          isBusy: _unlockingSkillNode,
          onUnlock: _unlockSkillTreeNode,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.xiTextSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n.clashBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = entry.displayCard;
    final stats = entry.displayStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaRow(label: l10n.clashCardTeam, value: entry.team),
          _MetaRow(
            label: l10n.clashCardPosition,
            value: card.position.displayNameEs,
          ),
          _MetaRow(label: l10n.clashCardStyle, value: card.style.displayNameEs),
          _MetaRow(
            label: l10n.clashCardLevel,
            value: '${entry.displayLevel} / ${entry.effectiveRarity.maxLevel}',
          ),
          _MetaRow(label: l10n.clashCardPower, value: '${entry.power}'),
          const SizedBox(height: 12),
          Text(
            l10n.clashCardStats,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _StatRow(label: l10n.clashStatSave, value: stats.save),
          _StatRow(label: l10n.clashStatDefense, value: stats.defense),
          _StatRow(label: l10n.clashStatPass, value: stats.pass),
          _StatRow(label: l10n.clashStatDribble, value: stats.dribble),
          _StatRow(label: l10n.clashStatShot, value: stats.shot),
          _StatRow(label: l10n.clashStatPt, value: stats.techniquePoints),
          _StatRow(label: l10n.clashStatStamina, value: stats.stamina),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary.withValues(alpha: 0.85),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _XpPanel extends StatelessWidget {
  const _XpPanel({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = entry.progress;
    final currentXp = progress?.currentExperience ?? 0;

    if (entry.isMaxLevel) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.xiCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.xiDivider),
        ),
        child: Text(
          l10n.clashCardMaxLevel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.xiTextSecondary,
          ),
        ),
      );
    }

    final needed =
        entry.xpToNextLevel ??
        ClashCardXpTable.xpToNextLevel(
          entry.displayLevel,
          entry.effectiveRarity,
        );
    final ratio = needed <= 0 ? 0.0 : (currentXp / needed).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashCardXpTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: context.xiChipBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashCardXpProgress(currentXp, needed),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradePanel extends StatelessWidget {
  const _UpgradePanel({
    required this.entry,
    required this.materials,
    required this.isBusy,
    required this.onUseMaterial,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
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
          _MetaRow(
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

class _TechniquePanel extends StatelessWidget {
  const _TechniquePanel({
    required this.baseTechnique,
    required this.progress,
    required this.books,
    required this.isBusy,
    required this.onUseBook,
  });

  final ClashSuperTechnique baseTechnique;
  final ClashCardProgress? progress;
  final List<ClashTechniqueBookInventoryEntry> books;
  final bool isBusy;
  final ValueChanged<String> onUseBook;

  static String _typeLabel(ClashTechniqueType type) => switch (type) {
    ClashTechniqueType.save => 'Parada',
    ClashTechniqueType.defense => 'Defensa',
    ClashTechniqueType.dribble => 'Regate',
    ClashTechniqueType.shot => 'Tiro',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
      technique: baseTechnique,
      progress: progress,
    );
    final atMax = resolved.level.isMax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashTechniqueSection,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            resolved.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(resolved.description),
          const SizedBox(height: 10),
          _MetaRow(
            label: l10n.clashTechniqueType,
            value: _typeLabel(resolved.type),
          ),
          _MetaRow(
            label: l10n.clashCardStyle,
            value: resolved.style.displayNameEs,
          ),
          _MetaRow(
            label: l10n.clashTechniqueLevel,
            value: resolved.level.displayLabel,
          ),
          _MetaRow(
            label: l10n.clashTechniqueBasePower,
            value: '${baseTechnique.basePower}',
          ),
          _MetaRow(
            label: l10n.clashTechniquePower,
            value: '${resolved.effectivePower}',
          ),
          _MetaRow(
            label: l10n.clashTechniquePtCost,
            value: '${resolved.ptCost}',
          ),
          const SizedBox(height: 14),
          Text(
            l10n.clashTechniqueUpgradeTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (atMax) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clashCardMaxLevel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
            ),
          ],
          const SizedBox(height: 10),
          for (final item in books) ...[
            _TechniqueBookRow(
              entry: item,
              disabled: atMax || item.quantity <= 0 || isBusy,
              onUse: () => onUseBook(item.book.id),
            ),
            if (item != books.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TechniqueBookRow extends StatelessWidget {
  const _TechniqueBookRow({
    required this.entry,
    required this.disabled,
    required this.onUse,
  });

  final ClashTechniqueBookInventoryEntry entry;
  final bool disabled;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final book = entry.book;

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
                  book.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                l10n.clashTechniqueBookEffect(book.levelUpSteps),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            book.description,
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
                child: Text(l10n.clashTechniqueBookUse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvolutionPanel extends StatelessWidget {
  const _EvolutionPanel({
    required this.entry,
    required this.evolutionMaterials,
    required this.isBusy,
    required this.onEvolve,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
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

class _SkillTreePanel extends StatelessWidget {
  const _SkillTreePanel({
    required this.entry,
    required this.isBusy,
    required this.onUnlock,
  });

  final ClashCardCatalogEntry entry;
  final bool isBusy;
  final ValueChanged<String> onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = entry.card;
    final progress = entry.progress;
    final eligible = entry.hasSkillTree;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashSkillTreeTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (!eligible) ...[
            Text(
              l10n.clashSkillTreeLockedRarity,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
            ),
          ] else if (progress == null) ...[
            Text(
              l10n.clashSkillTreeLockedRarity,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
            ),
          ] else ...[
            Text(l10n.clashSkillTreeDuplicates(progress.duplicateCopies)),
            const SizedBox(height: 6),
            Text(
              l10n.clashSkillTreeProgress(
                progress.unlockedDuplicateNodes,
                ClashSkillTreeDefinition.nodeCount,
              ),
            ),
            const SizedBox(height: 14),
            for (final node in ClashSkillTreeDefinition.nodesFor(card.position))
              _SkillTreeNodeRow(
                node: node,
                progress: progress,
                card: card,
                isBusy: isBusy,
                onUnlock: onUnlock,
              ),
          ],
        ],
      ),
    );
  }
}

enum _SkillTreeNodeVisualState { locked, available, unlocked }

class _SkillTreeNodeRow extends StatelessWidget {
  const _SkillTreeNodeRow({
    required this.node,
    required this.progress,
    required this.card,
    required this.isBusy,
    required this.onUnlock,
  });

  final ClashSkillTreeNode node;
  final ClashCardProgress progress;
  final ClashCard card;
  final bool isBusy;
  final ValueChanged<String> onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = _resolveState();

    final statusLabel = switch (state) {
      _SkillTreeNodeVisualState.unlocked => l10n.clashSkillTreeNodeUnlocked,
      _SkillTreeNodeVisualState.available => l10n.clashSkillTreeNodeAvailable,
      _SkillTreeNodeVisualState.locked => l10n.clashSkillTreeNodeLocked,
    };

    final canUnlock = state == _SkillTreeNodeVisualState.available && !isBusy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            node.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(node.description),
          const SizedBox(height: 4),
          Text(
            '${node.boostLabel} · $statusLabel',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
          ),
          if (canUnlock) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => onUnlock(node.id),
              child: Text(l10n.clashSkillTreeUnlock),
            ),
          ],
        ],
      ),
    );
  }

  _SkillTreeNodeVisualState _resolveState() {
    if (ClashSkillTreeService.isNodeUnlocked(progress, node.id)) {
      return _SkillTreeNodeVisualState.unlocked;
    }
    if (ClashSkillTreeService.canUnlockNode(
      card: card,
      progress: progress,
      node: node,
    )) {
      return _SkillTreeNodeVisualState.available;
    }
    return _SkillTreeNodeVisualState.locked;
  }
}
