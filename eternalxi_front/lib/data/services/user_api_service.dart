import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/update_user_preferences_request.dart';
import 'package:eternal_xi/data/models/user_notification_item.dart';
import 'package:eternal_xi/data/models/user_preferences_response.dart';
import 'package:eternal_xi/data/models/user_resources_response.dart';
import 'package:eternal_xi/data/models/user_model.dart';
import 'package:eternal_xi/data/models/friendship.dart';
import 'package:eternal_xi/data/models/user_public_profile.dart';
import 'package:eternal_xi/data/models/user_search_result.dart';

class UserApiService {
  UserApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> blockUser({
    required int idUsuario,
    required int idUsuarioBloqueado,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.users}/block',
        data: {
          'idUsuario': idUsuario,
          'idUsuarioBloqueado': idUsuarioBloqueado,
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserModel> getUserById(int id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.users}/$id');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserModel> updateUser({
    required int id,
    required String nickname,
    required int nivel,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.users}/$id',
        data: <String, dynamic>{'nickname': nickname, 'nivel': nivel},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> uploadProfilePhoto({
    required int id,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await _apiClient.dio.put(
        '${ApiConstants.users}/$id/photo',
        data: formData,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.users}/$id');
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserResourcesResponse> getUserResources(int userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$userId/resources',
      );
      return UserResourcesResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserPreferencesResponse> getUserPreferences(int userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$userId/preferences',
      );
      return UserPreferencesResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserPreferencesResponse> updateUserPreferences(
    int userId,
    UpdateUserPreferencesRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.users}/$userId/preferences',
        data: request.toJson(),
      );
      return UserPreferencesResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserNotificationsListResponse> getNotifications({
    required int idUsuario,
    int? idLiga,
    int? limit,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$idUsuario/notifications',
        queryParameters: <String, dynamic>{
          if (idLiga != null) 'idLiga': idLiga,
          if (limit != null) 'limit': limit,
        },
      );
      return UserNotificationsListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<int> getUnreadNotificationsCount({
    required int idUsuario,
    int? idLiga,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$idUsuario/notifications/unread-count',
        queryParameters: <String, dynamic>{
          if (idLiga != null) 'idLiga': idLiga,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['noLeidas'] as num?)?.toInt() ?? 0;
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> markNotificationsRead({
    required int idUsuario,
    List<int>? ids,
    int? idLiga,
    bool marcarTodas = false,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.users}/notifications/mark-read',
        data: <String, dynamic>{
          'idUsuario': idUsuario,
          if (ids != null && ids.isNotEmpty) 'ids': ids,
          if (idLiga != null) 'idLiga': idLiga,
          'marcarTodas': marcarTodas,
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> registerPushToken({
    required int idUsuario,
    required String token,
    required String plataforma,
    String? deviceId,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.users}/push-token',
        data: <String, dynamic>{
          'idUsuario': idUsuario,
          'token': token,
          'plataforma': plataforma,
          'deviceId': deviceId,
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<Friendship>> listFriendships({required int idUsuario}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$idUsuario/friends',
      );
      return Friendship.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<UserSearchResult>> searchUsers({
    required int idUsuario,
    required String query,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$idUsuario/friends/search',
        queryParameters: {'q': query.trim()},
      );
      return UserSearchResult.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<Friendship> sendFriendRequest({
    required int idUsuario,
    required int idAmigo,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.users}/$idUsuario/friends',
        data: {'idAmigo': idAmigo},
      );
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Respuesta de amistad inválida');
      }
      final m = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);
      return Friendship.fromJson(m);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<Friendship> acceptFriendRequest({
    required int idUsuario,
    required int idAmistad,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.users}/$idUsuario/friends/$idAmistad/accept',
      );
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Respuesta de amistad inválida');
      }
      final m = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);
      return Friendship.fromJson(m);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> rejectFriendRequest({
    required int idUsuario,
    required int idAmistad,
  }) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConstants.users}/$idUsuario/friends/requests/$idAmistad',
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> removeFriend({
    required int idUsuario,
    required int idAmigo,
  }) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConstants.users}/$idUsuario/friends/$idAmigo',
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<UserPublicProfile> getPublicProfile({
    required int targetUserId,
    int? viewerUserId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.users}/$targetUserId/public-profile',
        queryParameters: {
          if (viewerUserId != null) 'idUsuario': viewerUserId,
        },
      );
      return UserPublicProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> updateFavoritePlayer({
    required int userId,
    int? idJugador,
  }) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.users}/$userId/favorite-player',
        data: {'idJugador': idJugador},
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }
}