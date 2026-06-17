import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';

/// Opción de pase hacia un compañero.
class MatchPassOption {
  const MatchPassOption({
    required this.targetIndex,
    required this.targetName,
    required this.targetPosition,
    required this.approximateZone,
    required this.successPercent,
    required this.targetPower,
  });

  final int targetIndex;
  final String targetName;
  final ClashPosition targetPosition;
  final MatchBallZone approximateZone;
  final int successPercent;
  final int targetPower;
}
