import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Probabilidades provisionales de rareza (Fase 23).
class ClashGachaRarityRates {
  const ClashGachaRarityRates({
    required this.nPercent,
    required this.rPercent,
    required this.srPercent,
    required this.lrPercent,
    required this.xiPercent,
  });

  final int nPercent;
  final int rPercent;
  final int srPercent;
  final int lrPercent;
  final int xiPercent;

  static const provisional = ClashGachaRarityRates(
    nPercent: 60,
    rPercent: 30,
    srPercent: 10,
    lrPercent: 0,
    xiPercent: 0,
  );

  int get totalPercent =>
      nPercent + rPercent + srPercent + lrPercent + xiPercent;

  factory ClashGachaRarityRates.fromJson(Map<String, dynamic> json) {
    return ClashGachaRarityRates(
      nPercent: _readPercent(json['n']),
      rPercent: _readPercent(json['r']),
      srPercent: _readPercent(json['sr']),
      lrPercent: _readPercent(json['lr']),
      xiPercent: _readPercent(json['xi']),
    );
  }

  static int _readPercent(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  List<(ClashRarity rarity, int weight)> get weightedEntries => [
    (ClashRarity.n, nPercent),
    (ClashRarity.r, rPercent),
    (ClashRarity.sr, srPercent),
    (ClashRarity.lr, lrPercent),
    (ClashRarity.xi, xiPercent),
  ];
}
