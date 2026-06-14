import 'clash_json_helpers.dart';
import 'clash_player_style.dart';
import 'clash_position.dart';
import 'clash_rarity.dart';
import 'clash_stats.dart';
import 'clash_super_technique.dart';

/// Definición estática de una carta Clash vinculada a un jugador del catálogo.
///
/// No incluye nombre, equipo ni lore (pertenecen al jugador base vía [playerId]).
class ClashCard {
  const ClashCard({
    required this.id,
    required this.playerId,
    required this.rarity,
    required this.level,
    required this.style,
    required this.position,
    required this.stats,
    required this.superTechniques,
    required this.basicPortraitPath,
    this.passiveId,
    this.specialFullBodyArtPath,
  });

  final String id;

  /// Enlace al jugador real del catálogo Eternal XI (`idJugador`).
  final int playerId;
  final ClashRarity rarity;
  final int level;
  final ClashPlayerStyle style;
  final ClashPosition position;
  final ClashStats stats;
  final List<ClashSuperTechnique> superTechniques;
  final String? passiveId;
  final String basicPortraitPath;
  final String? specialFullBodyArtPath;

  /// Potencia delegada en las estadísticas máximas.
  int get power => stats.power;

  /// Valida reglas de dominio; lanza [FormatException] o [ArgumentError].
  static void validate({
    required ClashRarity rarity,
    required int level,
    required List<ClashSuperTechnique> superTechniques,
    required String? passiveId,
  }) {
    if (level < 1 || level > rarity.maxLevel) {
      throw ArgumentError(
        'Nivel $level fuera de rango (1-${rarity.maxLevel}) para ${rarity.name}',
      );
    }

    if (superTechniques.length > rarity.maxSuperTechniques) {
      throw ArgumentError(
        'Demasiadas supertécnicas (${superTechniques.length}) '
        'para rareza ${rarity.name} (máx. ${rarity.maxSuperTechniques})',
      );
    }

    if (passiveId != null && !rarity.allowsPassive) {
      throw ArgumentError(
        'Solo XI puede tener pasiva; rareza actual: ${rarity.name}',
      );
    }
  }

  factory ClashCard.fromJson(Map<String, dynamic> json) {
    final rarity = ClashRarity.fromJson(json['rarity']);
    final techniquesRaw = json['superTechniques'] as List<dynamic>? ?? const [];
    final techniques = techniquesRaw
        .map(
          (e) =>
              ClashSuperTechnique.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    final level = clashRequireInt(json['level'], 'level');
    final passiveId = clashOptionalString(json['passiveId']);

    validate(
      rarity: rarity,
      level: level,
      superTechniques: techniques,
      passiveId: passiveId,
    );

    return ClashCard(
      id: clashRequireString(json['id'], 'id'),
      playerId: clashRequireInt(json['playerId'], 'playerId'),
      rarity: rarity,
      level: level,
      style: ClashPlayerStyle.fromJson(json['style']),
      position: ClashPosition.fromJson(json['position']),
      stats: ClashStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map),
      ),
      superTechniques: List<ClashSuperTechnique>.unmodifiable(techniques),
      passiveId: passiveId,
      basicPortraitPath: clashRequireString(
        json['basicPortraitPath'],
        'basicPortraitPath',
      ),
      specialFullBodyArtPath: clashOptionalString(
        json['specialFullBodyArtPath'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'rarity': rarity.toJson(),
    'level': level,
    'style': style.toJson(),
    'position': position.toJson(),
    'stats': stats.toJson(),
    'superTechniques': superTechniques.map((t) => t.toJson()).toList(),
    if (passiveId != null) 'passiveId': passiveId,
    'basicPortraitPath': basicPortraitPath,
    if (specialFullBodyArtPath != null)
      'specialFullBodyArtPath': specialFullBodyArtPath,
  };
}
