import 'clash_json_helpers.dart';

/// Estadísticas máximas de una carta Clash (fuera de penalizaciones de partido).
class ClashStats {
  const ClashStats({
    required this.save,
    required this.defense,
    required this.pass,
    required this.dribble,
    required this.shot,
    required this.techniquePoints,
    required this.stamina,
  }) : assert(save >= 0, 'Parada no puede ser negativa'),
       assert(defense >= 0, 'Defensa no puede ser negativa'),
       assert(pass >= 0, 'Pase no puede ser negativo'),
       assert(dribble >= 0, 'Regate no puede ser negativo'),
       assert(shot >= 0, 'Tiro no puede ser negativo'),
       assert(techniquePoints >= 0, 'PT no puede ser negativo'),
       assert(stamina >= 0, 'Resistencia no puede ser negativa');

  final int save;
  final int defense;
  final int pass;
  final int dribble;
  final int shot;

  /// Reserva máxima de Puntos de Técnica (PT).
  final int techniquePoints;

  /// Resistencia máxima de la carta.
  final int stamina;

  /// Potencia = suma exacta de todas las estadísticas al máximo.
  int get power =>
      save + defense + pass + dribble + shot + techniquePoints + stamina;

  /// Multiplicador provisional por cansancio en partido.
  ///
  /// - Si [currentStamina] >= 100 → 1.0 (sin penalización).
  /// - Por debajo de 100: `deficit = 100 - currentStamina`,
  ///   `penalty = deficit * 0.003`, multiplicador mínimo 0.70.
  ///
  /// Curva provisional; sujeta a balance futuro. PT no se ve afectado.
  static double staminaPerformanceMultiplier(int currentStamina) {
    if (currentStamina >= 100) {
      return 1.0;
    }
    final deficit = 100 - currentStamina;
    final penalty = deficit * 0.003;
    return (1.0 - penalty).clamp(0.70, 1.0);
  }

  int _effectiveStat(int statValue, int currentStamina) {
    final multiplier = staminaPerformanceMultiplier(currentStamina);
    return (statValue * multiplier).round();
  }

  int effectiveSave(int currentStamina) => _effectiveStat(save, currentStamina);

  int effectiveDefense(int currentStamina) =>
      _effectiveStat(defense, currentStamina);

  int effectivePass(int currentStamina) => _effectiveStat(pass, currentStamina);

  int effectiveDribble(int currentStamina) =>
      _effectiveStat(dribble, currentStamina);

  int effectiveShot(int currentStamina) => _effectiveStat(shot, currentStamina);

  /// PT no disminuye por cansancio; devuelve el máximo de la carta.
  int effectiveTechniquePoints(int currentStamina) => techniquePoints;

  /// Escala stats base por multiplicador de nivel (Fase 17).
  ClashStats scaled(double multiplier) {
    if (multiplier == 1.0) {
      return this;
    }
    int scale(int value) => (value * multiplier).round().clamp(0, 9999);
    return ClashStats(
      save: scale(save),
      defense: scale(defense),
      pass: scale(pass),
      dribble: scale(dribble),
      shot: scale(shot),
      techniquePoints: techniquePoints,
      stamina: stamina,
    );
  }

  factory ClashStats.fromJson(Map<String, dynamic> json) {
    return ClashStats(
      save: clashRequireInt(json['save'], 'save'),
      defense: clashRequireInt(json['defense'], 'defense'),
      pass: clashRequireInt(json['pass'], 'pass'),
      dribble: clashRequireInt(json['dribble'], 'dribble'),
      shot: clashRequireInt(json['shot'], 'shot'),
      techniquePoints: clashRequireInt(
        json['techniquePoints'],
        'techniquePoints',
      ),
      stamina: clashRequireInt(json['stamina'], 'stamina'),
    );
  }

  Map<String, dynamic> toJson() => {
    'save': save,
    'defense': defense,
    'pass': pass,
    'dribble': dribble,
    'shot': shot,
    'techniquePoints': techniquePoints,
    'stamina': stamina,
  };
}
