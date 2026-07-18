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
  final Set<int> _locallySeenEventIds = <int>{};

  bool get hasPendingCelebration {
    final pending = progress?.eventosPendientes;
    if (pending == null || pending.isEmpty) {
      return false;
    }
    return pending.any((e) => !_locallySeenEventIds.contains(e.id));
  }

  List<UserProgressEvent> get pendingUnseenEvents {
    final pending = progress?.eventosPendientes ?? const [];
    return pending
        .where((e) => !_locallySeenEventIds.contains(e.id))
        .toList(growable: false);
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> _hydrateSeenIds(int userId) async {
    final stored = await _secureStorageService.loadSeenProgressEventIds(userId);
    _locallySeenEventIds
      ..clear()
      ..addAll(stored);
  }

  Future<UserProgressResponse?> loadProgress(int userId) async {
    _setLoading(true);
    errorMessage = null;
    isFromCache = false;
    try {
      await _hydrateSeenIds(userId);
      progress = await _progressApiService.getProgress(userId);
      progress = _withoutLocallySeen(progress!);
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
        await _hydrateSeenIds(userId);
        progress = _withoutLocallySeen(cached);
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

  UserProgressResponse _withoutLocallySeen(UserProgressResponse source) {
    if (_locallySeenEventIds.isEmpty) {
      return source;
    }
    final filtered = source.eventosPendientes
        .where((e) => !_locallySeenEventIds.contains(e.id))
        .toList(growable: false);
    if (filtered.length == source.eventosPendientes.length) {
      return source;
    }
    return source.copyWith(eventosPendientes: filtered);
  }

  /// Marca eventos como vistos en servidor y, si falla, igual en local/caché
  /// para no repetir la animación al volver a entrar.
  Future<void> markEventsSeen(int userId, List<int> eventIds) async {
    if (eventIds.isEmpty) {
      return;
    }

    _locallySeenEventIds.addAll(eventIds);
    await _secureStorageService.saveSeenProgressEventIds(
      userId,
      _locallySeenEventIds,
    );

    if (progress != null) {
      progress = progress!.copyWith(
        eventosPendientes: progress!.eventosPendientes
            .where((e) => !eventIds.contains(e.id))
            .toList(growable: false),
      );
      await _secureStorageService.saveProgressCache(
        userId,
        progress!.toJsonString(),
      );
      notifyListeners();
    }

    try {
      progress = await _progressApiService.markEventsSeen(
        userId: userId,
        eventIds: eventIds,
      );
      progress = _withoutLocallySeen(progress!);
      isFromCache = false;
      await _secureStorageService.saveProgressCache(
        userId,
        progress!.toJsonString(),
      );
      notifyListeners();
    } catch (_) {
      // Ya quedaron marcados en local: no volver a mostrar.
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

  /// Aplica XP de cuenta en local (p. ej. recompensa de historia) y anima la barra.
  /// No sustituye al backend; al recargar progreso se sincroniza de nuevo.
  void applyOptimisticXp(int amount) {
    final current = progress;
    if (current == null || amount <= 0) {
      return;
    }
    var nivel = current.nivel;
    var xpEn = current.xpEnNivel + amount;
    var maxXp = current.xpParaSiguienteNivel <= 0
        ? 100
        : current.xpParaSiguienteNivel;
    while (xpEn >= maxXp) {
      xpEn -= maxXp;
      nivel += 1;
      maxXp = (maxXp * 1.08).round().clamp(100, 9999);
    }
    progress = current.copyWith(
      nivel: nivel,
      xpEnNivel: xpEn,
      xpParaSiguienteNivel: maxXp,
      experienciaTotal: current.experienciaTotal + amount,
    );
    notifyListeners();
  }
}
