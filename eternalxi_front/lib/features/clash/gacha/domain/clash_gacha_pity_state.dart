/// Estado de pity SR local por banner (Fase 25).
///
/// Regla provisional: solo un SR obtenido por pity reinicia el contador.
/// Un SR natural o por garantía multi **no** reinicia el pity.
class ClashGachaPityState {
  const ClashGachaPityState({
    required this.bannerId,
    required this.pullsSinceLastPity,
    required this.threshold,
    required this.totalPulls,
    required this.pityHits,
  });

  static const defaultThreshold = 30;

  final String bannerId;
  final int pullsSinceLastPity;
  final int threshold;
  final int totalPulls;
  final int pityHits;

  int get pullsRemaining {
    final remaining = threshold - pullsSinceLastPity;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isNearPity => pullsRemaining > 0 && pullsRemaining <= 5;

  factory ClashGachaPityState.initial(String bannerId, {int? threshold}) {
    return ClashGachaPityState(
      bannerId: bannerId,
      pullsSinceLastPity: 0,
      threshold: threshold ?? defaultThreshold,
      totalPulls: 0,
      pityHits: 0,
    );
  }

  ClashGachaPityState copyWith({
    int? pullsSinceLastPity,
    int? threshold,
    int? totalPulls,
    int? pityHits,
  }) {
    return ClashGachaPityState(
      bannerId: bannerId,
      pullsSinceLastPity: pullsSinceLastPity ?? this.pullsSinceLastPity,
      threshold: threshold ?? this.threshold,
      totalPulls: totalPulls ?? this.totalPulls,
      pityHits: pityHits ?? this.pityHits,
    );
  }

  factory ClashGachaPityState.fromJson(Map<String, dynamic> json) {
    return ClashGachaPityState(
      bannerId: json['bannerId'] as String? ?? '',
      pullsSinceLastPity: json['pullsSinceLastPity'] as int? ?? 0,
      threshold: json['pityThreshold'] as int? ?? defaultThreshold,
      totalPulls: json['totalPulls'] as int? ?? 0,
      pityHits: json['pityHits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'bannerId': bannerId,
    'pullsSinceLastPity': pullsSinceLastPity,
    'pityThreshold': threshold,
    'totalPulls': totalPulls,
    'pityHits': pityHits,
  };
}
