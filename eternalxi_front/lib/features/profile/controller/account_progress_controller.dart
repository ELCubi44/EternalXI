import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/models/user_model.dart';
import 'package:eternal_xi/data/models/user_progress_response.dart';
import 'package:eternal_xi/data/services/user_progress_api_service.dart';
import 'package:flutter/material.dart';

class AccountProgressController extends ChangeNotifier {
  AccountProgressController({
    required UserProgressApiService progressApiService,
    required SecureStorageService secureStorageService,
  }) : _progressApiService = progressApiService,
       _secureStorageService = secureStorageService;

  final UserProgressApiService _progressApiService;
  final SecureStorageService _secureStorageService;

  UserProgressResponse? progress;
  bool isLoading = false;
  String? errorMessage;
  bool isFromCache = false;
  bool isPlayingCelebration = false;

  bool get hasPendingCelebration =>
      progress != null && progress!.eventosPendientes.isNotEmpty;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<UserProgressResponse?> loadProgress(int userId) async {
    _setLoading(true);
    errorMessage = null;
    isFromCache = false;
    try {
      progress = await _progressApiService.getProgress(userId);
      await _secureStorageService.saveProgressCache(
        userId,
        progress!.toJsonString(),
      );
      notifyListeners();
      return progress;
    } catch (e) {
      final cachedRaw = await _secureStorageService.loadProgressCache(userId);
      final cached = cachedRaw != null
          ? UserProgressResponse.fromJsonString(cachedRaw)
          : null;
      if (cached != null) {
        progress = cached;
        isFromCache = true;
        errorMessage = null;
        notifyListeners();
        return progress;
      }
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markEventsSeen(int userId, List<int> eventIds) async {
    if (eventIds.isEmpty) {
      return;
    }
    try {
      progress = await _progressApiService.markEventsSeen(
        userId: userId,
        eventIds: eventIds,
      );
      isFromCache = false;
      await _secureStorageService.saveProgressCache(
        userId,
        progress!.toJsonString(),
      );
      notifyListeners();
    } catch (_) {
      // No bloquear la UI si falla el ack.
    }
  }

  void setCelebrating(bool value) {
    if (isPlayingCelebration == value) {
      return;
    }
    isPlayingCelebration = value;
    notifyListeners();
  }

  Future<void> syncUserLevel(UserModel user) async {
    if (progress == null) {
      return;
    }
    final updated = UserModel(
      id: user.id,
      correo: user.correo,
      nickname: user.nickname,
      nivel: progress!.nivel,
      foto: user.foto,
    );
    await _secureStorageService.saveUser(updated);
  }
}
