/// IDs de recompensa e ítems concedibles conocidos en Clash (Fase 55).
abstract final class ClashRewardIds {
  static const eternalXiStarterRosterKey = 'eternal_xi_starter_n';

  static const expMaterials = <String>{
    'basic-training-manual',
    'advanced-training-manual',
    'master-training-manual',
  };

  static const techniqueBooks = <String>{
    'basic-technique-book',
    'advanced-technique-book',
    'master-technique-book',
  };

  static const evolutionMaterials = <String>{'insignia-r', 'insignia-sr'};

  static const tickets = <String>{'starter-single-ticket'};

  /// Mapeo de ítems narrativos de historia a materiales EXP concedibles.
  static const storyItemToExpMaterial = <String, String>{
    'basic-book': 'basic-training-manual',
  };

  static bool isKnownExpMaterial(String id) => expMaterials.contains(id);

  static bool isKnownTechniqueBook(String id) => techniqueBooks.contains(id);

  static bool isKnownEvolutionMaterial(String id) =>
      evolutionMaterials.contains(id);

  static bool isKnownTicket(String id) => tickets.contains(id);

  static bool isKnownGrantableItemId(String id) =>
      isKnownExpMaterial(id) ||
      isKnownTechniqueBook(id) ||
      isKnownEvolutionMaterial(id) ||
      isKnownTicket(id);
}
