import 'package:dio/dio.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';

String mapRewardsActionError(Object error, ApiClient apiClient) {
  if (error is ApiException) {
    return error.message;
  }
  if (error is! DioException) {
    return apiClient.extractErrorMessage(error);
  }

  final extracted = apiClient.extractErrorMessage(error);

  final response = error.response;
  final status = response?.statusCode;

  if (status == 409) {
    final lower = extracted.toLowerCase();
    if (lower.contains('punto') ||
        lower.contains('point') ||
        lower.contains('insufficient')) {
      if (lower.contains('ruleta') || lower.contains('roulette')) {
        return 'No tienes puntos suficientes para usar la ruleta.';
      }
      return 'No tienes puntos suficientes para abrir este sobre.';
    }
    if (lower.contains('carta') &&
        (lower.contains('usad') || lower.contains('used'))) {
      return 'Esta carta ya se ha usado.';
    }
    if (lower.contains('proteg') || lower.contains('protect')) {
      return 'Este jugador está protegido.';
    }
    if (lower.contains('presupuesto') ||
        lower.contains('budget') ||
        lower.contains('fondos')) {
      return 'No tienes presupuesto suficiente.';
    }
    if (lower.contains('entrenador') ||
        lower.contains('coach') ||
        lower.contains('no hay')) {
      return 'No hay entrenadores disponibles en esta liga.';
    }
  }

  return extracted;
}
