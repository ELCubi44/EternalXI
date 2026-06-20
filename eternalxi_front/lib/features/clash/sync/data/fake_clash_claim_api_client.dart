import 'package:eternal_xi/features/clash/sync/domain/clash_claim_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';

/// Contrato mínimo del cliente claims (HTTP o fake en tests).
abstract class ClashClaimApiPort {
  Future<ClashClaimResponse> submitClaim(ClashClaimRequest request);
}

/// Cliente fake de claims en memoria (Fase 83).
class FakeClashClaimApiClient implements ClashClaimApiPort {
  int submitCalls = 0;
  Map<String, dynamic>? lastRequestJson;
  ClashClaimResponse? nextResponse;
  ClashClaimApiException? nextError;
  final Map<String, ClashClaimResponse> processed = {};

  @override
  Future<ClashClaimResponse> submitClaim(ClashClaimRequest request) async {
    submitCalls += 1;
    lastRequestJson = request.toJson();
    if (nextError != null) {
      throw nextError!;
    }
    final cached = processed[request.claimId];
    if (cached != null) {
      return ClashClaimResponse(
        claimId: cached.claimId,
        status: cached.status,
        alreadyProcessed: true,
        serverRevision: cached.serverRevision,
        rawRewards: cached.rawRewards,
        message: cached.message,
      );
    }
    final response =
        nextResponse ??
        ClashClaimResponse(
          claimId: request.claimId,
          status: 'ACCEPTED',
          alreadyProcessed: false,
          message: 'accepted',
        );
    processed[request.claimId] = response;
    return response;
  }
}
