import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';

/// Resultado opcional de usar un ticket (Fase 26).
class ClashGachaTicketUseResult {
  const ClashGachaTicketUseResult({
    required this.ticketId,
    required this.quantityUsed,
    this.pullResult,
    this.error,
  });

  final String ticketId;
  final int quantityUsed;
  final ClashGachaPullResult? pullResult;
  final ClashGachaPullError? error;
}
