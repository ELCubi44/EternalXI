import 'clash_json_helpers.dart';
import 'clash_rarity.dart';
import 'clash_technique_level.dart';

/// Progreso del usuario sobre una carta concreta.
///
/// Separado de [ClashCard] para no mezclar definición de carta y estado del jugador.
class ClashCardProgress {
  const ClashCardProgress({
    required this.cardId,
    required this.currentLevel,
    required this.currentExperience,
    required this.unlockedDuplicateNodes,
    required this.techniqueLevels,
    this.evolvedRarity,
  });

  /// Máximo de nodos desbloqueables con duplicados (carta inicial + 5 = 6 copias).
  static const int maxDuplicateNodes = 5;

  final String cardId;
  final int currentLevel;
  final int currentExperience;

  /// Nodos del árbol desbloqueados mediante duplicados (0–5).
  final int unlockedDuplicateNodes;

  /// Nivel de mejora por supertécnica (independiente entre técnicas).
  final Map<String, ClashTechniqueLevel> techniqueLevels;

  /// Rareza alcanzada por evolución local (misma cardId en assets).
  final ClashRarity? evolvedRarity;

  /// Valida reglas de progreso según la rareza de la carta.
  void validateForRarity(ClashRarity rarity) {
    if (currentLevel < 1 || currentLevel > rarity.maxLevel) {
      throw ArgumentError(
        'Nivel de progreso $currentLevel fuera de rango '
        '(1-${rarity.maxLevel}) para ${rarity.name}',
      );
    }

    if (currentExperience < 0) {
      throw ArgumentError('La experiencia no puede ser negativa');
    }

    if (unlockedDuplicateNodes < 0 ||
        unlockedDuplicateNodes > maxDuplicateNodes) {
      throw ArgumentError(
        'Nodos de duplicados fuera de rango (0-$maxDuplicateNodes)',
      );
    }

    if (!rarity.hasDuplicateTree && unlockedDuplicateNodes > 0) {
      throw ArgumentError('Rareza ${rarity.name} no tiene árbol de duplicados');
    }
  }

  /// Indica si el árbol de duplicados está completamente maximizado.
  bool get isTreeMaximized => unlockedDuplicateNodes >= maxDuplicateNodes;

  ClashCardProgress copyWith({
    int? currentLevel,
    int? currentExperience,
    int? unlockedDuplicateNodes,
    Map<String, ClashTechniqueLevel>? techniqueLevels,
    ClashRarity? evolvedRarity,
  }) {
    return ClashCardProgress(
      cardId: cardId,
      currentLevel: currentLevel ?? this.currentLevel,
      currentExperience: currentExperience ?? this.currentExperience,
      unlockedDuplicateNodes:
          unlockedDuplicateNodes ?? this.unlockedDuplicateNodes,
      techniqueLevels: techniqueLevels ?? this.techniqueLevels,
      evolvedRarity: evolvedRarity ?? this.evolvedRarity,
    );
  }

  factory ClashCardProgress.fromJson(Map<String, dynamic> json) {
    final levelsRaw =
        json['techniqueLevels'] as Map<String, dynamic>? ?? const {};
    final techniqueLevels = levelsRaw.map(
      (key, value) => MapEntry(key, ClashTechniqueLevel.fromJson(value)),
    );

    return ClashCardProgress(
      cardId: clashRequireString(json['cardId'], 'cardId'),
      currentLevel: clashRequireInt(json['currentLevel'], 'currentLevel'),
      currentExperience: clashRequireInt(
        json['currentExperience'],
        'currentExperience',
      ),
      unlockedDuplicateNodes: clashRequireInt(
        json['unlockedDuplicateNodes'],
        'unlockedDuplicateNodes',
      ),
      techniqueLevels: Map<String, ClashTechniqueLevel>.unmodifiable(
        techniqueLevels,
      ),
      evolvedRarity: json['evolvedRarity'] == null
          ? null
          : ClashRarity.fromJson(json['evolvedRarity']),
    );
  }

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'currentLevel': currentLevel,
    'currentExperience': currentExperience,
    'unlockedDuplicateNodes': unlockedDuplicateNodes,
    'techniqueLevels': techniqueLevels.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    if (evolvedRarity != null) 'evolvedRarity': evolvedRarity!.toJson(),
  };
}
