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
  static const _sheetMax = 0.78;
  static const _sheetHandleHeight = 36.0;

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

  final _sheetController = DraggableScrollableController();
  final _techniqueSectionKey = GlobalKey();
  final _upgradeSectionKey = GlobalKey();
  final _evolutionSectionKey = GlobalKey();
  final _skillTreeSectionKey = GlobalKey();
  final _sheetExtentNotifier = ValueNotifier(0.05);
  bool _sheetHeaderVisible = false;

  double _sheetMinFor(double screenHeight) =>
      (_sheetHandleHeight / screenHeight).clamp(0.045, 0.065);

  double _sheetRevealThresholdFor(double screenHeight) =>
      _sheetMinFor(screenHeight) + 0.08;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCard());
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _sheetExtentNotifier.dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    if (!_sheetController.isAttached) {
      return;
    }

    final size = _sheetController.size;
    _sheetExtentNotifier.value = size;

    final threshold = _sheetRevealThresholdFor(
      MediaQuery.sizeOf(context).height,
    );
    final headerVisible = size > threshold;
    if (headerVisible != _sheetHeaderVisible) {
      setState(() => _sheetHeaderVisible = headerVisible);
    }
  }

  Future<void> _expandSheet() async {
    if (!_sheetController.isAttached) {
      return;
    }

    await _sheetController.animateTo(
      _sheetMax,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openSheetSection(GlobalKey sectionKey) async {
    await _expandSheet();

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) {
      return;
    }

    final target = sectionKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  Future<void> _openUpgradeSheet() => _openSheetSection(_upgradeSectionKey);

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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetMin = _sheetMinFor(screenHeight);
    final peekHeight = screenHeight * sheetMin;
    final baseCardHeight = screenHeight - peekHeight;
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
        ValueListenableBuilder<double>(
          valueListenable: _sheetExtentNotifier,
          builder: (context, sheetExtent, _) {
            final sheetMinLocal = _sheetMinFor(screenHeight);
            final dragT =
                ((sheetExtent - sheetMinLocal) / (_sheetMax - sheetMinLocal))
                    .clamp(0.0, 1.0);
            final cardScale = 1.0 - (dragT * 0.48);

            return Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  scale: cardScale,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: baseCardHeight,
                    width: double.infinity,
                    child: ClashCardEpicShowcase(
                      entry: entry,
                      detailHero: true,
                      height: baseCardHeight,
                      onLevelUpTap: _openUpgradeSheet,
                    ),
                  ),
                ),
              ),
            );
          },
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
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: sheetMin,
          minChildSize: sheetMin,
          maxChildSize: _sheetMax,
          snap: true,
          snapSizes: [sheetMin, 0.28, _sheetMax],
          snapAnimationDuration: const Duration(milliseconds: 220),
          builder: (context, scrollController) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _sheetHeaderVisible
                    ? context.xiBackground
                    : Colors.transparent,
                borderRadius: _sheetHeaderVisible
                    ? const BorderRadius.vertical(top: Radius.circular(22))
                    : BorderRadius.zero,
                boxShadow: _sheetHeaderVisible
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          blurRadius: 18,
                          offset: const Offset(0, -4),
                        ),
                      ]
                    : const [],
              ),
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _expandSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.xiTextSecondary.withValues(
                              alpha: _sheetHeaderVisible ? 0.35 : 0.55,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: _sheetHeaderVisible ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_sheetHeaderVisible,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.clashCardDetailTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.xiTextPrimary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _SheetActionChip(
                                  label: l10n.clashTechniqueSection,
                                  onTap: () => _openSheetSection(
                                    _techniqueSectionKey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _SheetActionChip(
                                  label: l10n.clashActionUpgrade,
                                  onTap: _openUpgradeSheet,
                                ),
                                const SizedBox(width: 8),
                                _SheetActionChip(
                                  label: l10n.clashActionEvolve,
                                  onTap: () => _openSheetSection(
                                    _evolutionSectionKey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _SheetActionChip(
                                  label: l10n.clashActionTree,
                                  onTap: () => _openSheetSection(
                                    _skillTreeSectionKey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  KeyedSubtree(
                    key: _techniqueSectionKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final technique in card.superTechniques) ...[
                          ClashCardTechniqueSection(
                            baseTechnique: technique,
                            progress: entry.progress,
                            books: _techniqueBooks,
                            isBusy: _usingTechniqueBookFor == technique.id,
                            onUseBook: (bookId) =>
                                _useTechniqueBook(technique.id, bookId),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  KeyedSubtree(
                    key: _upgradeSectionKey,
                    child: ClashCardUpgradeSection(
                      entry: entry,
                      materials: _materials,
                      isBusy: _usingMaterial,
                      onUseMaterial: _useMaterial,
                    ),
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: _evolutionSectionKey,
                    child: ClashCardEvolutionSection(
                      entry: entry,
                      evolutionMaterials: _evolutionMaterials,
                      isBusy: _evolving,
                      onEvolve: _evolveCard,
                    ),
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: _skillTreeSectionKey,
                    child: ClashCardSkillTreeSection(
                      entry: entry,
                      isBusy: _unlockingSkillNode,
                      onUnlock: _unlockSkillTreeNode,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SheetActionChip extends StatelessWidget {
  const _SheetActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
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
