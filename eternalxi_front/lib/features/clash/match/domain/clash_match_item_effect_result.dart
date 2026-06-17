import 'package:eternal_xi/features/clash/match/domain/clash_match_item_player_change.dart';

/// Resultado de intentar usar un objeto en el descanso.
class ClashMatchItemEffectResult {
  const ClashMatchItemEffectResult({
    required this.itemId,
    required this.itemName,
    required this.used,
    required this.affectedPlayers,
    this.errorMessage,
  });

  final String itemId;
  final String itemName;
  final bool used;
  final List<ClashMatchItemPlayerChange> affectedPlayers;
  final String? errorMessage;

  bool get hasEffect => affectedPlayers.isNotEmpty;

  String get summaryMessage {
    if (errorMessage != null) {
      return errorMessage!;
    }
    if (!hasEffect) {
      return 'Sin efecto';
    }
    return affectedPlayers
        .map((change) {
          if (change.ptDelta > 0) {
            return '+${change.ptDelta} PT a ${change.label}';
          }
          if (change.staminaDelta > 0) {
            return '+${change.staminaDelta} resistencia a ${change.label}';
          }
          return change.label;
        })
        .join(' · ');
  }
}
