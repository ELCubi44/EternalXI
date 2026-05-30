import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/user_progress_response.dart';

class UserProgressApiService {
  UserProgressApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProgressResponse> getProgress(int userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$userId/progress',
      );
      return UserProgressResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserProgressResponse> markEventsSeen({
    required int userId,
    required List<int> eventIds,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.users}/$userId/progress/events/seen',
        data: <String, dynamic>{'idsEventos': eventIds},
      );
      return UserProgressResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }
}
