import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_grant_result.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_mission_progress_event_hub.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievement_event_sink.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_unlock_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';

/// Colección de cartas poseídas por el jugador (local, sin backend).
class ClashPlayerCollectionRepository {
  ClashPlayerCollectionRepository({
    required ClashPlayerCollectionStorageBackend storage,
    required ClashCardsRepository cardsRepository,
    required ClashExpMaterialsRepository expMaterialsRepository,
    required ClashTechniqueBooksRepository techniqueBooksRepository,
    required ClashEvolutionMaterialsRepository evolutionMaterialsRepository,
    ClashMissionProgressEventHub? progressEventHub,
    ClashDailyMissionEventSink? missionEventSink,
    ClashAchievementEventSink? achievementEventSink,
  }) : _storage = storage,
       _cardsRepository = cardsRepository,
       _expMaterialsRepository = expMaterialsRepository,
       _techniqueBooksRepository = techniqueBooksRepository,
       _evolutionMaterialsRepository = evolutionMaterialsRepository,
       _missionEventSink = missionEventSink,
       _achievementEventSink = achievementEventSink,
       _progressEventHub = progressEventHub;

  final ClashPlayerCollectionStorageBackend _storage;
  final ClashCardsRepository _cardsRepository;
  final ClashExpMaterialsRepository _expMaterialsRepository;
  final ClashTechniqueBooksRepository _techniqueBooksRepository;
  final ClashEvolutionMaterialsRepository _evolutionMaterialsRepository;
  final ClashDailyMissionEventSink? _missionEventSink;
  final ClashAchievementEventSink? _achievementEventSink;
  final ClashMissionProgressEventHub? _progressEventHub;

  ClashPlayerCollectionSnapshot? _cache;

  ClashPlayerCollectionSnapshot _loadSnapshot() {
    _cache ??= _storage.readSnapshot();
    return _cache!;
  }

  Set<String> loadOwnedCardIds() {
    return Set<String>.from(_loadSnapshot().ownedCardIds);
  }

  Future<void> _syncCollectCardsAchievement() async {
    final count = loadOwnedCardIds().length;
    final progressHub = _progressEventHub;
    if (progressHub != null) {
      await progressHub.syncCollectCards(count);
      return;
    }
    await _achievementEventSink?.record(
      ClashAchievementType.collectCards,
      amount: count,
      absolute: true,
    );
  }

  Map<String, ClashCardProgress> loadCardProgress() {
    return Map<String, ClashCardProgress>.from(_loadSnapshot().cardProgress);
  }

  ClashCardProgress? progressFor(String cardId) =>
      _loadSnapshot().cardProgress[cardId];

  ClashCardProgress ensureProgress(String cardId) {
    final snapshot = _loadSnapshot();
    final existing = snapshot.cardProgress[cardId];
    if (existing != null) {
      return existing;
    }
    final created = ClashCardXpService.initialProgress(cardId);
    _cache = snapshot.copyWith(
      cardProgress: {...snapshot.cardProgress, cardId: created},
    );
    return created;
  }

  Future<void> grantCardIds(Iterable<String> cardIds) async {
    if (cardIds.isEmpty) {
      return;
    }

    final snapshot = _loadSnapshot();
    final owned = Set<String>.from(snapshot.ownedCardIds);
    final progress = Map<String, ClashCardProgress>.from(snapshot.cardProgress);
    var changed = false;

    for (final id in cardIds) {
      if (owned.contains(id)) {
        final current = progress[id] ?? ClashCardXpService.initialProgress(id);
        progress[id] = current.copyWith(
          duplicateCopies: current.duplicateCopies + 1,
        );
        changed = true;
      } else {
        owned.add(id);
        progress[id] = ClashCardXpService.initialProgress(id);
        changed = true;
      }
    }

    if (changed) {
      await _save(
        snapshot.copyWith(ownedCardIds: owned, cardProgress: progress),
      );
      await _syncCollectCardsAchievement();
    }
  }

  Future<List<String>> grantMissingCardIds(Iterable<String> cardIds) async {
    final owned = loadOwnedCardIds();
    final progress = loadCardProgress();
    final newlyGranted = <String>[];
    for (final id in cardIds) {
      if (!owned.contains(id)) {
        owned.add(id);
        progress[id] = ClashCardXpService.initialProgress(id);
        newlyGranted.add(id);
      }
    }
    if (newlyGranted.isNotEmpty) {
      await _save(
        _loadSnapshot().copyWith(ownedCardIds: owned, cardProgress: progress),
      );
      await _syncCollectCardsAchievement();
    }
    return newlyGranted;
  }

  Future<List<String>> grantEternalXiStarterNCards() async {
    final catalog = await _cardsRepository.fetchAllCards();
    final starterIds = catalog
        .where(
          (entry) =>
              entry.team == 'Eternal XI' && entry.card.rarity == ClashRarity.n,
        )
        .map((entry) => entry.id)
        .toList(growable: false);
    return grantMissingCardIds(starterIds);
  }

  /// Concede una copia duplicada de una carta ya poseída (tests/recompensas).
  Future<int> grantCardCopy(String cardId) {
    return grantCardCopies(cardId, 1);
  }

  Future<int> grantCardCopies(String cardId, int count) async {
    if (count <= 0) {
      return 0;
    }

    final snapshot = _loadSnapshot();
    if (!snapshot.ownedCardIds.contains(cardId)) {
      return 0;
    }

    final current =
        snapshot.cardProgress[cardId] ??
        ClashCardXpService.initialProgress(cardId);
    final updated = current.copyWith(
      duplicateCopies: current.duplicateCopies + count,
    );
    final progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    progressMap[cardId] = updated;
    await _save(snapshot.copyWith(cardProgress: progressMap));
    return count;
  }

  /// Concede una carta obtenida por gacha local (Fase 23).
  Future<ClashGachaGrantResult> grantGachaCard({
    required String cardId,
    required ClashRarity rarity,
  }) async {
    final entry = await _cardsRepository.findById(cardId);
    if (entry == null) {
      throw ArgumentError('Carta desconocida: $cardId');
    }

    final snapshot = _loadSnapshot();
    final owned = Set<String>.from(snapshot.ownedCardIds);
    final progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    final card = entry.card;

    if (!owned.contains(cardId)) {
      var progress = ClashCardXpService.initialProgress(cardId);
      final evolved = _resolvedEvolvedRarity(
        baseRarity: card.rarity,
        currentEvolved: null,
        pullRarity: rarity,
      );
      if (evolved != null) {
        progress = progress.copyWith(evolvedRarity: evolved);
      }
      owned.add(cardId);
      progressMap[cardId] = progress;
      await _save(
        snapshot.copyWith(ownedCardIds: owned, cardProgress: progressMap),
      );
      await _syncCollectCardsAchievement();
      return ClashGachaGrantResult(
        cardId: cardId,
        grantedRarity: rarity,
        isNew: true,
        isDuplicate: false,
        upgradedRarity: evolved != null,
        duplicateCopiesAfter: progress.duplicateCopies,
      );
    }

    final current =
        progressMap[cardId] ?? ClashCardXpService.initialProgress(cardId);
    final effective = ClashCardEvolutionResolver.effectiveRarity(card, current);

    if (_rarityTier(rarity) > _rarityTier(effective)) {
      final evolved = _resolvedEvolvedRarity(
        baseRarity: card.rarity,
        currentEvolved: current.evolvedRarity,
        pullRarity: rarity,
      );
      final updated = current.copyWith(evolvedRarity: evolved);
      progressMap[cardId] = updated;
      await _save(snapshot.copyWith(cardProgress: progressMap));
      return ClashGachaGrantResult(
        cardId: cardId,
        grantedRarity: rarity,
        isNew: false,
        isDuplicate: false,
        upgradedRarity: true,
        duplicateCopiesAfter: updated.duplicateCopies,
      );
    }

    final updated = current.copyWith(
      duplicateCopies: current.duplicateCopies + 1,
    );
    progressMap[cardId] = updated;
    await _save(snapshot.copyWith(cardProgress: progressMap));
    return ClashGachaGrantResult(
      cardId: cardId,
      grantedRarity: rarity,
      isNew: false,
      isDuplicate: true,
      upgradedRarity: false,
      duplicateCopiesAfter: updated.duplicateCopies,
    );
  }

  static int _rarityTier(ClashRarity rarity) =>
      ClashRarity.values.indexOf(rarity);

  static ClashRarity? _resolvedEvolvedRarity({
    required ClashRarity baseRarity,
    required ClashRarity? currentEvolved,
    required ClashRarity pullRarity,
  }) {
    if (_rarityTier(pullRarity) <= _rarityTier(baseRarity)) {
      return currentEvolved;
    }
    final effective = currentEvolved ?? baseRarity;
    if (_rarityTier(pullRarity) > _rarityTier(effective)) {
      return pullRarity;
    }
    return currentEvolved;
  }

  /// Desbloquea un nodo del árbol de habilidades (Fase 21).
  Future<ClashSkillTreeUnlockResult> unlockSkillTreeNode({
    required String cardId,
    required String nodeId,
  }) async {
    final snapshot = _loadSnapshot();
    if (!snapshot.ownedCardIds.contains(cardId)) {
      return ClashSkillTreeUnlockResult(
        cardId: cardId,
        nodeId: nodeId,
        duplicateConsumed: false,
        remainingDuplicates: 0,
        unlocked: false,
        error: ClashSkillTreeUnlockError.cardNotOwned,
      );
    }

    final entry = await _cardsRepository.findById(cardId);
    if (entry == null) {
      return ClashSkillTreeUnlockResult(
        cardId: cardId,
        nodeId: nodeId,
        duplicateConsumed: false,
        remainingDuplicates: 0,
        unlocked: false,
        error: ClashSkillTreeUnlockError.cardNotFound,
      );
    }

    final current =
        snapshot.cardProgress[cardId] ??
        ClashCardXpService.initialProgress(cardId);
    final preview = ClashSkillTreeService.previewUnlock(
      cardId: cardId,
      card: entry.card,
      progress: current,
      nodeId: nodeId,
    );

    if (!preview.succeeded) {
      return preview;
    }

    final progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    progressMap[cardId] = ClashSkillTreeService.progressAfterUnlock(
      progress: current,
      nodeId: nodeId,
    );
    await _save(snapshot.copyWith(cardProgress: progressMap));
    await _recordUnlockSkillNode();
    return preview;
  }

  Future<List<ClashCardCatalogEntry>> fetchOwnedCards() async {
    final owned = loadOwnedCardIds();
    if (owned.isEmpty) {
      return const [];
    }
    final catalog = await _cardsRepository.fetchAllCards();
    final progress = loadCardProgress();
    return catalog
        .where((entry) => owned.contains(entry.id))
        .map(
          (entry) => entry.withProgress(
            progress[entry.id] ?? ClashCardXpService.initialProgress(entry.id),
          ),
        )
        .toList(growable: false);
  }

  ClashCardCatalogEntry enrichEntry(ClashCardCatalogEntry entry) {
    final progress =
        progressFor(entry.id) ?? ClashCardXpService.initialProgress(entry.id);
    return entry.withProgress(progress);
  }

  Map<String, ClashCardCatalogEntry> enrichCatalog(
    Map<String, ClashCardCatalogEntry> catalogById,
  ) {
    return catalogById.map((key, entry) => MapEntry(key, enrichEntry(entry)));
  }

  /// Concede EXP de partido a cartas de la alineación (solo victoria).
  Future<List<ClashCardXpResult>> grantMatchXp({
    required Iterable<String> cardIds,
    required int xpPerCard,
  }) async {
    if (xpPerCard <= 0 || cardIds.isEmpty) {
      return const [];
    }

    final snapshot = _loadSnapshot();
    var progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    final results = <ClashCardXpResult>[];

    for (final cardId in cardIds) {
      if (!snapshot.ownedCardIds.contains(cardId)) {
        continue;
      }
      final entry = await _cardsRepository.findById(cardId);
      if (entry == null) {
        continue;
      }

      final current =
          progressMap[cardId] ?? ClashCardXpService.initialProgress(cardId);
      final rarity = ClashCardEvolutionResolver.effectiveRarity(
        entry.card,
        current,
      );
      final result = ClashCardXpService.applyXp(
        progress: current,
        rarity: rarity,
        cardName: entry.name,
        xpAmount: xpPerCard,
      );
      progressMap[cardId] = ClashCardXpService.progressAfterResult(
        current,
        result,
      );
      results.add(result);
    }

    if (results.isNotEmpty) {
      await _save(snapshot.copyWith(cardProgress: progressMap));
      final levelUps = results.where((result) => result.didLevelUp).length;
      if (levelUps > 0) {
        await _recordLevelUpCard(levelUps);
      }
    }

    return results;
  }

  /// Calcula EXP de partido sin persistir (preview en fin de partido).
  Future<List<ClashCardXpResult>> previewMatchXp({
    required Iterable<String> cardIds,
    required int xpPerCard,
  }) async {
    if (xpPerCard <= 0 || cardIds.isEmpty) {
      return const [];
    }

    final owned = loadOwnedCardIds();
    final progressMap = loadCardProgress();
    final results = <ClashCardXpResult>[];

    for (final cardId in cardIds) {
      if (!owned.contains(cardId)) {
        continue;
      }
      final entry = await _cardsRepository.findById(cardId);
      if (entry == null) {
        continue;
      }
      final current =
          progressMap[cardId] ?? ClashCardXpService.initialProgress(cardId);
      final rarity = ClashCardEvolutionResolver.effectiveRarity(
        entry.card,
        current,
      );
      results.add(
        ClashCardXpService.applyXp(
          progress: current,
          rarity: rarity,
          cardName: entry.name,
          xpAmount: xpPerCard,
        ),
      );
    }

    return results;
  }

  /// Preview sincrónico para UI de fin de partido.
  List<ClashCardXpResult> previewMatchXpSync({
    required Iterable<String> cardIds,
    required int xpPerCard,
    required Map<String, ClashCardCatalogEntry> catalogById,
  }) {
    if (xpPerCard <= 0 || cardIds.isEmpty) {
      return const [];
    }

    final owned = loadOwnedCardIds();
    final results = <ClashCardXpResult>[];

    for (final cardId in cardIds) {
      if (!owned.contains(cardId)) {
        continue;
      }
      final entry = catalogById[cardId];
      if (entry == null) {
        continue;
      }
      final current =
          entry.progress ?? ClashCardXpService.initialProgress(cardId);
      final rarity = ClashCardEvolutionResolver.effectiveRarity(
        entry.card,
        current,
      );
      results.add(
        ClashCardXpService.applyXp(
          progress: current,
          rarity: rarity,
          cardName: entry.name,
          xpAmount: xpPerCard,
        ),
      );
    }

    return results;
  }

  bool ownsCard(String cardId) => loadOwnedCardIds().contains(cardId);

  Future<void> grantExpMaterials(Map<String, int> additions) {
    return _expMaterialsRepository.grantMaterials(additions);
  }

  Future<void> grantTechniqueBooks(Map<String, int> additions) {
    return _techniqueBooksRepository.grantBooks(additions);
  }

  Future<void> grantEvolutionMaterials(Map<String, int> additions) {
    return _evolutionMaterialsRepository.grantMaterials(additions);
  }

  /// Evoluciona una carta poseída N→R o R→SR (Fase 20).
  Future<ClashEvolutionResult> evolveCard({required String cardId}) async {
    final snapshot = _loadSnapshot();
    if (!snapshot.ownedCardIds.contains(cardId)) {
      return _failedEvolution(
        cardId: cardId,
        error: ClashEvolutionError.cardNotOwned,
      );
    }

    final entry = await _cardsRepository.findById(cardId);
    if (entry == null) {
      return _failedEvolution(
        cardId: cardId,
        error: ClashEvolutionError.cardNotFound,
      );
    }

    final current =
        snapshot.cardProgress[cardId] ??
        ClashCardXpService.initialProgress(cardId);
    final preview = ClashEvolutionService.previewEvolution(
      cardId: cardId,
      card: entry.card,
      progress: current,
      availableMaterials: _evolutionMaterialsRepository
          .loadInventoryQuantities(),
    );

    if (!preview.succeeded) {
      return preview;
    }

    for (final material in preview.materialsConsumed.entries) {
      final consumed = await _evolutionMaterialsRepository.consumeMaterial(
        materialId: material.key,
        quantity: material.value,
      );
      if (!consumed) {
        return preview.withError(ClashEvolutionError.insufficientMaterials);
      }
    }

    final progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    progressMap[cardId] = ClashEvolutionService.progressAfterEvolution(
      progress: current,
      newRarity: preview.newRarity,
    );
    await _save(snapshot.copyWith(cardProgress: progressMap));

    await _recordEvolveCard();

    return preview;
  }

  ClashEvolutionResult _failedEvolution({
    required String cardId,
    required ClashEvolutionError error,
  }) {
    return ClashEvolutionResult(
      cardId: cardId,
      previousRarity: ClashRarity.n,
      newRarity: ClashRarity.n,
      previousMaxLevel: ClashRarity.n.maxLevel,
      newMaxLevel: ClashRarity.n.maxLevel,
      previousLevel: 1,
      newLevel: 1,
      materialsConsumed: const {},
      coinsConsumed: 0,
      error: error,
    );
  }

  /// Usa un libro de técnica sobre una supertécnica (Fase 19).
  Future<ClashTechniqueBookUseResult> useTechniqueBookOnCard({
    required String cardId,
    required String techniqueId,
    required String bookId,
    int quantity = 1,
  }) async {
    if (quantity <= 0) {
      return _failedTechniqueBookUse(
        cardId: cardId,
        techniqueId: techniqueId,
        bookId: bookId,
        error: ClashTechniqueBookUseError.insufficientQuantity,
      );
    }

    final snapshot = _loadSnapshot();
    if (!snapshot.ownedCardIds.contains(cardId)) {
      return _failedTechniqueBookUse(
        cardId: cardId,
        techniqueId: techniqueId,
        bookId: bookId,
        error: ClashTechniqueBookUseError.cardNotOwned,
      );
    }

    final entry = await _cardsRepository.findById(cardId);
    if (entry == null) {
      return _failedTechniqueBookUse(
        cardId: cardId,
        techniqueId: techniqueId,
        bookId: bookId,
        error: ClashTechniqueBookUseError.cardNotFound,
      );
    }

    final technique = _findTechnique(entry, techniqueId);
    if (technique == null) {
      return _failedTechniqueBookUse(
        cardId: cardId,
        techniqueId: techniqueId,
        bookId: bookId,
        error: ClashTechniqueBookUseError.techniqueNotFound,
      );
    }

    final book = await _techniqueBooksRepository.findById(bookId);
    if (book == null) {
      final progress =
          snapshot.cardProgress[cardId] ??
          ClashCardXpService.initialProgress(cardId);
      final previousLevel = ClashTechniqueProgressResolver.resolvedLevel(
        technique: technique,
        progress: progress,
      );
      return ClashTechniqueBookUseResult(
        cardId: cardId,
        techniqueId: techniqueId,
        bookId: bookId,
        quantityUsed: 0,
        previousLevel: previousLevel,
        newLevel: previousLevel,
        previousEffectivePower: ClashTechniqueProgressResolver.effectivePower(
          technique: technique,
          progress: progress,
        ),
        newEffectivePower: ClashTechniqueProgressResolver.effectivePower(
          technique: technique,
          progress: progress,
        ),
        didLevelUp: false,
        reachedMaxLevel: previousLevel.isMax,
        error: ClashTechniqueBookUseError.bookNotFound,
      );
    }

    final available = _techniqueBooksRepository.quantityFor(bookId);
    if (available <= 0 || available < quantity) {
      final progress =
          snapshot.cardProgress[cardId] ??
          ClashCardXpService.initialProgress(cardId);
      final previousLevel = ClashTechniqueProgressResolver.resolvedLevel(
        technique: technique,
        progress: progress,
      );
      return ClashTechniqueBookUseResult(
        cardId: cardId,
        techniqueId: techniqueId,
        bookId: bookId,
        quantityUsed: 0,
        previousLevel: previousLevel,
        newLevel: previousLevel,
        previousEffectivePower: ClashTechniqueProgressResolver.effectivePower(
          technique: technique,
          progress: progress,
        ),
        newEffectivePower: ClashTechniqueProgressResolver.effectivePower(
          technique: technique,
          progress: progress,
        ),
        didLevelUp: false,
        reachedMaxLevel: previousLevel.isMax,
        error: ClashTechniqueBookUseError.insufficientQuantity,
      );
    }

    final current =
        snapshot.cardProgress[cardId] ??
        ClashCardXpService.initialProgress(cardId);
    final preview = ClashTechniqueBookService.applyBook(
      cardId: cardId,
      technique: technique,
      book: book,
      progress: current,
      quantity: quantity,
    );

    if (!preview.succeeded) {
      return preview;
    }

    final consumed = await _techniqueBooksRepository.consumeBook(
      bookId: bookId,
      quantity: quantity,
    );
    if (!consumed) {
      return preview.withError(ClashTechniqueBookUseError.insufficientQuantity);
    }

    final progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    progressMap[cardId] = ClashTechniqueBookService.progressAfterResult(
      progress: current,
      result: preview,
    );
    await _save(snapshot.copyWith(cardProgress: progressMap));

    await _recordUpgradeTechnique(preview.didLevelUp);

    return preview.withQuantityUsed(quantity);
  }

  ClashSuperTechnique? _findTechnique(
    ClashCardCatalogEntry entry,
    String techniqueId,
  ) {
    for (final technique in entry.card.superTechniques) {
      if (technique.id == techniqueId) {
        return technique;
      }
    }
    return null;
  }

  ClashTechniqueBookUseResult _failedTechniqueBookUse({
    required String cardId,
    required String techniqueId,
    required String bookId,
    required ClashTechniqueBookUseError error,
  }) {
    return ClashTechniqueBookUseResult(
      cardId: cardId,
      techniqueId: techniqueId,
      bookId: bookId,
      quantityUsed: 0,
      previousLevel: ClashTechniqueLevel.normal,
      newLevel: ClashTechniqueLevel.normal,
      previousEffectivePower: 0,
      newEffectivePower: 0,
      didLevelUp: false,
      reachedMaxLevel: false,
      error: error,
    );
  }

  /// Usa materiales EXP sobre una carta poseída (Fase 18).
  Future<ClashExpMaterialUseResult> useExpMaterialOnCard({
    required String cardId,
    required String materialId,
    int quantity = 1,
  }) async {
    if (quantity <= 0) {
      return ClashExpMaterialUseResult(
        cardId: cardId,
        materialId: materialId,
        quantityUsed: 0,
        xpGained: 0,
        previousLevel: 1,
        newLevel: 1,
        previousXp: 0,
        newXp: 0,
        didLevelUp: false,
        reachedMaxLevel: false,
        error: ClashExpMaterialUseError.insufficientQuantity,
      );
    }

    final snapshot = _loadSnapshot();
    if (!snapshot.ownedCardIds.contains(cardId)) {
      return _failedMaterialUse(
        cardId: cardId,
        materialId: materialId,
        error: ClashExpMaterialUseError.cardNotOwned,
      );
    }

    final entry = await _cardsRepository.findById(cardId);
    if (entry == null) {
      return _failedMaterialUse(
        cardId: cardId,
        materialId: materialId,
        error: ClashExpMaterialUseError.cardNotFound,
      );
    }

    final material = await _expMaterialsRepository.findById(materialId);
    if (material == null) {
      return _failedMaterialUse(
        cardId: cardId,
        materialId: materialId,
        error: ClashExpMaterialUseError.materialNotFound,
      );
    }

    final available = _expMaterialsRepository.quantityFor(materialId);
    if (available <= 0) {
      final progress =
          snapshot.cardProgress[cardId] ??
          ClashCardXpService.initialProgress(cardId);
      final rarity = ClashCardEvolutionResolver.effectiveRarity(
        entry.card,
        progress,
      );
      return ClashExpMaterialUseResult(
        cardId: cardId,
        materialId: materialId,
        quantityUsed: 0,
        xpGained: 0,
        previousLevel: progress.currentLevel,
        newLevel: progress.currentLevel,
        previousXp: progress.currentExperience,
        newXp: progress.currentExperience,
        didLevelUp: false,
        reachedMaxLevel: ClashCardXpService.isAtMaxLevel(progress, rarity),
        error: ClashExpMaterialUseError.insufficientQuantity,
      );
    }

    if (available < quantity) {
      final progress =
          snapshot.cardProgress[cardId] ??
          ClashCardXpService.initialProgress(cardId);
      final rarity = ClashCardEvolutionResolver.effectiveRarity(
        entry.card,
        progress,
      );
      return ClashExpMaterialUseResult(
        cardId: cardId,
        materialId: materialId,
        quantityUsed: 0,
        xpGained: 0,
        previousLevel: progress.currentLevel,
        newLevel: progress.currentLevel,
        previousXp: progress.currentExperience,
        newXp: progress.currentExperience,
        didLevelUp: false,
        reachedMaxLevel: ClashCardXpService.isAtMaxLevel(progress, rarity),
        error: ClashExpMaterialUseError.insufficientQuantity,
      );
    }

    final current =
        snapshot.cardProgress[cardId] ??
        ClashCardXpService.initialProgress(cardId);
    final effectiveRarity = ClashCardEvolutionResolver.effectiveRarity(
      entry.card,
      current,
    );
    final previousLevel = current.currentLevel;
    final previousXp = current.currentExperience;

    if (ClashCardXpService.isAtMaxLevel(current, effectiveRarity)) {
      return ClashExpMaterialUseResult(
        cardId: cardId,
        materialId: materialId,
        quantityUsed: 0,
        xpGained: 0,
        previousLevel: previousLevel,
        newLevel: previousLevel,
        previousXp: previousXp,
        newXp: previousXp,
        didLevelUp: false,
        reachedMaxLevel: true,
        error: ClashExpMaterialUseError.cardAtMaxLevel,
      );
    }

    final xpAmount = material.xpAmount * quantity;
    final xpResult = ClashCardXpService.applyXp(
      progress: current,
      rarity: effectiveRarity,
      cardName: entry.name,
      xpAmount: xpAmount,
    );

    if (xpResult.xpGained <= 0) {
      return ClashExpMaterialUseResult(
        cardId: cardId,
        materialId: materialId,
        quantityUsed: 0,
        xpGained: 0,
        previousLevel: previousLevel,
        newLevel: previousLevel,
        previousXp: previousXp,
        newXp: previousXp,
        didLevelUp: false,
        reachedMaxLevel: xpResult.reachedMaxLevel,
        error: ClashExpMaterialUseError.cannotGainXp,
      );
    }

    final consumed = await _expMaterialsRepository.consumeMaterial(
      materialId: materialId,
      quantity: quantity,
    );
    if (!consumed) {
      return ClashExpMaterialUseResult(
        cardId: cardId,
        materialId: materialId,
        quantityUsed: 0,
        xpGained: 0,
        previousLevel: previousLevel,
        newLevel: previousLevel,
        previousXp: previousXp,
        newXp: previousXp,
        didLevelUp: false,
        reachedMaxLevel: xpResult.reachedMaxLevel,
        error: ClashExpMaterialUseError.insufficientQuantity,
      );
    }

    final updatedProgress = ClashCardXpService.progressAfterResult(
      current,
      xpResult,
    );
    final progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    progressMap[cardId] = updatedProgress;
    await _save(snapshot.copyWith(cardProgress: progressMap));

    await _recordUseExpMaterial(xpResult.didLevelUp);

    return ClashExpMaterialUseResult(
      cardId: cardId,
      materialId: materialId,
      quantityUsed: quantity,
      xpGained: xpResult.xpGained,
      previousLevel: previousLevel,
      newLevel: xpResult.newLevel,
      previousXp: previousXp,
      newXp: xpResult.newXp,
      didLevelUp: xpResult.didLevelUp,
      reachedMaxLevel: xpResult.reachedMaxLevel,
    );
  }

  ClashExpMaterialUseResult _failedMaterialUse({
    required String cardId,
    required String materialId,
    required ClashExpMaterialUseError error,
  }) {
    return ClashExpMaterialUseResult(
      cardId: cardId,
      materialId: materialId,
      quantityUsed: 0,
      xpGained: 0,
      previousLevel: 1,
      newLevel: 1,
      previousXp: 0,
      newXp: 0,
      didLevelUp: false,
      reachedMaxLevel: false,
      error: error,
    );
  }

  Future<void> _save(ClashPlayerCollectionSnapshot snapshot) async {
    _cache = snapshot;
    await _storage.writeSnapshot(snapshot);
  }

  Future<void> _recordUnlockSkillNode() async {
    final progressHub = _progressEventHub;
    if (progressHub != null) {
      await progressHub.recordUnlockSkillNode();
      return;
    }
    await _achievementEventSink?.record(ClashAchievementType.unlockSkillNode);
  }

  Future<void> _recordEvolveCard() async {
    final progressHub = _progressEventHub;
    if (progressHub != null) {
      await progressHub.recordEvolveCard();
      return;
    }
    await _achievementEventSink?.record(ClashAchievementType.evolveCard);
  }

  Future<void> _recordLevelUpCard(int amount) async {
    final progressHub = _progressEventHub;
    if (progressHub != null) {
      await progressHub.recordLevelUpCard(amount: amount);
      return;
    }
    await _achievementEventSink?.record(
      ClashAchievementType.levelUpCard,
      amount: amount,
    );
  }

  Future<void> _recordUpgradeTechnique(bool didLevelUp) async {
    final progressHub = _progressEventHub;
    if (progressHub != null) {
      await progressHub.recordUpgradeTechnique(didLevelUp: didLevelUp);
      return;
    }
    await _missionEventSink?.record(ClashDailyMissionType.upgradeTechnique);
    if (didLevelUp) {
      await _achievementEventSink?.record(
        ClashAchievementType.upgradeTechnique,
      );
    }
  }

  Future<void> _recordUseExpMaterial(bool didLevelUp) async {
    final progressHub = _progressEventHub;
    if (progressHub != null) {
      await progressHub.recordUseExpMaterial(didLevelUp: didLevelUp);
      return;
    }
    await _missionEventSink?.record(ClashDailyMissionType.useExpMaterial);
    if (didLevelUp) {
      await _achievementEventSink?.record(ClashAchievementType.levelUpCard);
    }
  }

  void clearCacheForTests() => _cache = null;
}
