import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_unlock_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_use_result.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_header.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_evolution_section.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_skill_tree_section.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_stats_panel.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_technique_section.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_upgrade_section.dart';
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

    return Material(
      color: Colors.transparent,
      child: ListView(
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
                  l10n.clashCardDetailTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.xiTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClashCardDetailHeader(entry: entry),
          const SizedBox(height: 16),
          ClashCardStatsPanel(entry: entry),
          for (final technique in card.superTechniques) ...[
            const SizedBox(height: 16),
            ClashCardTechniqueSection(
              baseTechnique: technique,
              progress: entry.progress,
              books: _techniqueBooks,
              isBusy: _usingTechniqueBookFor == technique.id,
              onUseBook: (bookId) => _useTechniqueBook(technique.id, bookId),
            ),
          ],
          const SizedBox(height: 16),
          ClashCardUpgradeSection(
            entry: entry,
            materials: _materials,
            isBusy: _usingMaterial,
            onUseMaterial: _useMaterial,
          ),
          const SizedBox(height: 16),
          ClashCardEvolutionSection(
            entry: entry,
            evolutionMaterials: _evolutionMaterials,
            isBusy: _evolving,
            onEvolve: _evolveCard,
          ),
          const SizedBox(height: 16),
          ClashCardSkillTreeSection(
            entry: entry,
            isBusy: _unlockingSkillNode,
            onUnlock: _unlockSkillTreeNode,
          ),
        ],
      ),
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
