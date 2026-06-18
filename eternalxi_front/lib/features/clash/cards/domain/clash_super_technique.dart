import 'clash_json_helpers.dart';
import 'clash_player_style.dart';
import 'clash_technique_level.dart';
import 'clash_technique_type.dart';

/// Supertécnica activa de una carta Clash.
class ClashSuperTechnique {
  const ClashSuperTechnique({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.style,
    required this.basePower,
    required this.ptCost,
    required this.level,
    this.specialArtPath,
  }) : assert(basePower > 0, 'basePower debe ser mayor que 0'),
       assert(ptCost > 0, 'ptCost debe ser mayor que 0');

  final String id;
  final String name;
  final String description;
  final ClashTechniqueType type;
  final ClashPlayerStyle style;
  final int basePower;
  final int ptCost;
  final ClashTechniqueLevel level;
  final String? specialArtPath;

  /// Potencia efectiva según el nivel de la técnica.
  int get effectivePower => (basePower * level.powerMultiplier).round();

  ClashSuperTechnique withLevel(ClashTechniqueLevel value) {
    if (value == level) {
      return this;
    }
    return ClashSuperTechnique(
      id: id,
      name: name,
      description: description,
      type: type,
      style: style,
      basePower: basePower,
      ptCost: ptCost,
      level: value,
      specialArtPath: specialArtPath,
    );
  }

  /// Indica si hay PT suficientes para activar la técnica.
  bool canBeUsed(int currentPt) => currentPt >= ptCost;

  factory ClashSuperTechnique.fromJson(Map<String, dynamic> json) {
    return ClashSuperTechnique(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      type: ClashTechniqueType.fromJson(json['type']),
      style: ClashPlayerStyle.fromJson(json['style']),
      basePower: clashRequireInt(json['basePower'], 'basePower'),
      ptCost: clashRequireInt(json['ptCost'], 'ptCost'),
      level: ClashTechniqueLevel.fromJson(json['level']),
      specialArtPath: clashOptionalString(json['specialArtPath']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.toJson(),
    'style': style.toJson(),
    'basePower': basePower,
    'ptCost': ptCost,
    'level': level.toJson(),
    if (specialArtPath != null) 'specialArtPath': specialArtPath,
  };
}
