import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
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
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_card_epic_showcase.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
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

class _ClashCardDetailScreenState extends State<ClashCardDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _panelHeightFactor = 0.62;
  static const _tabCount = 4;

  ClashCardCatalogEntry? _entry;
  List<ClashTechniqueBookInventoryEntry> _techniqueBooks = const [];
  List<ClashEvolutionMaterialInventoryEntry> _evolutionMaterials = const [];
  List<ClashExpMaterialInventoryEntry> _materials = const [];
  bool _loading = true;
  bool _notFound = false;
  bool _detailsOpen = false;
  bool _evolving = false;
  bool _unlockingSkillNode = false;
  bool _usingMaterial = false;
  String? _usingTechniqueBookFor;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDetails() {
    if (_detailsOpen) {
      return;
    }
    setState(() => _detailsOpen = true);
  }

  void _closeDetails() {
    if (!_detailsOpen) {
      return;
    }
    setState(() => _detailsOpen = false);
  }

  Future<void> _loadCard() async {
    final controller = context.read<ClashCardsController>();
    final collection = context.read<ClashPlayerCollectionRepository>();
    final techniqueBooksRepo = context.read<ClashTechniqueBooksRepository>();
    final evolutionMaterialsRepo = context
        .read<ClashEvolutionMaterialsRepository>();
    final materialsRepo = context.read<ClashExpMaterialsRepository>();
    if (controller.state == ClashCardsLoadState.idle) {
      await controller.load();
    }
    final entry = await controller.findCard(widget.cardId);
    final techniqueBooks = await techniqueBooksRepo.fetchInventoryEntries();
    final evolutionMaterials = await evolutionMaterialsRepo
        .fetchInventoryEntries();
    final materials = await materialsRepo.fetchInventoryEntries();
    if (!mounted) {
      return;
    }
    setState(() {
      _entry = entry == null ? null : collection.enrichEntry(entry);
      _techniqueBooks = techniqueBooks;
      _evolutionMaterials = evolutionMaterials;
      _materials = materials;
      _notFound = entry == null;
      _loading = false;
    });
  }

  Future<void> _openLevelUpSheet() async {
    if (_entry == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.xiBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: ClashCardUpgradeSection(
              entry: _entry!,
              materials: _materials,
              isBusy: _usingMaterial,
              onUseMaterial: _useMaterial,
            ),
          ),
        );
      },
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
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const ColoredBox(
        color: XiColors.nightBlue,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _entry == null) {
      return _ErrorState(message: l10n.clashCardNotFound);
    }

    final entry = _entry!;
    final card = entry.displayCard;
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;
    final panelHeight = screenHeight * _panelHeightFactor;
    final sheetTop = screenHeight - panelHeight;
    final detailsButtonReserve = 72.0 + safeBottom;
    final areaTop = safeTop + 56;
    final areaBottomClosed = detailsButtonReserve;
    final areaBottomOpen = screenHeight - sheetTop + 12;
    final slotHeight = _detailsOpen
        ? (screenHeight - areaTop - areaBottomOpen).clamp(160.0, screenHeight)
        : (screenHeight - areaTop - areaBottomClosed).clamp(260.0, screenHeight);
    final slotHorizontal = _detailsOpen ? 36.0 : 20.0;

    // Proporciones fijas: al abrir detalles se escala la misma carta.
    final designWidth = media.size.width - 40;
    final designHeight = (designWidth * 1.45).clamp(380.0, 580.0);

    final bgPath = ClashEpicAssets.detailBackgroundForTeam(
      entry.team,
      entry.effectiveRarity,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            bgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: XiColors.nightBlue,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.22),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
        if (!_detailsOpen)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Material(
                  color: context.xiBackground.withValues(alpha: 0.94),
                  elevation: 6,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: _openDetails,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      child: Text(
                        l10n.clashDetailsOpen,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: _detailsOpen ? 0 : -panelHeight,
          height: panelHeight,
          child: Material(
            color: context.xiBackground,
            elevation: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          tabs: [
                            Tab(text: l10n.clashDetailsTabStats),
                            Tab(text: l10n.clashDetailsTabTechniques),
                            Tab(text: l10n.clashActionTree),
                            Tab(text: l10n.clashActionEvolve),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.clashDetailsCollapse,
                        onPressed: _closeDetails,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          20 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          ClashCardStatsPanel(entry: entry),
                        ],
                      ),
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          20 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          for (final technique in card.superTechniques) ...[
                            ClashCardTechniqueSection(
                              baseTechnique: technique,
                              progress: entry.progress,
                              books: _techniqueBooks,
                              isBusy:
                                  _usingTechniqueBookFor == technique.id,
                              onUseBook: (bookId) =>
                                  _useTechniqueBook(technique.id, bookId),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          20 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          ClashCardSkillTreeSection(
                            entry: entry,
                            isBusy: _unlockingSkillNode,
                            onUnlock: _unlockSkillTreeNode,
                          ),
                        ],
                      ),
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          20 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          ClashCardEvolutionSection(
                            entry: entry,
                            evolutionMaterials: _evolutionMaterials,
                            isBusy: _evolving,
                            onEvolve: _evolveCard,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          left: slotHorizontal,
          right: slotHorizontal,
          top: areaTop,
          height: slotHeight,
          child: IgnorePointer(
            ignoring: _detailsOpen,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: designWidth,
                  height: designHeight,
                  child: ClashCardEpicShowcase(
                    entry: entry,
                    detailHero: true,
                    height: designHeight,
                    onLevelUpTap: _openLevelUpSheet,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
