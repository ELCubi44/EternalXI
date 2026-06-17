import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_action.dart';

/// Decisión de la IA rival antes de ejecutarla (Fase 13).
class ClashRivalAiDecision {
  const ClashRivalAiDecision({
    required this.action,
    required this.summary,
    this.passTargetIndex,
    this.passTargetLabel,
  });

  final ClashRivalAiAction action;
  final String summary;
  final int? passTargetIndex;
  final String? passTargetLabel;
}
