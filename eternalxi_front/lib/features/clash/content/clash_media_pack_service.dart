import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/clash/content/clash_content_manifest.dart';
import 'package:eternal_xi/features/clash/content/player_image_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Downloads Clash player photos pack (also speeds up Fantasy avatars).
class ClashMediaPackService {
  ClashMediaPackService({Dio? dio}) : _dio = dio ?? Dio();

  static const _prefsPortraitsVersion = 'clash_media_portraits_version_v1';
  static const _prefsReady = 'clash_media_pack_ready_v1';
  static const _concurrency = 6;

  final Dio _dio;
  final PlayerImageCache _cache = PlayerImageCache.instance;

  Future<bool> isReady({required int portraitsVersion}) async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_prefsPortraitsVersion) ?? 0) < portraitsVersion) {
      return false;
    }
    return prefs.getBool(_prefsReady) ?? false;
  }

  /// Info para preguntar antes de descargar.
  Future<({bool needsDownload, int pendingBytes, int pendingCount})>
      pendingDownloadInfo() async {
    final manifest = await ClashContentManifest.loadBundled();
    final ids = await loadPlayerIdsFromCatalog();
    await _cache.playersDirectory();
    final present = await _cache.countPresent(ids);
    final ready = await isReady(portraitsVersion: manifest.portraitsVersion);
    if (ready && present >= ids.length) {
      return (needsDownload: false, pendingBytes: 0, pendingCount: 0);
    }
    final missing = ids.length - present;
    if (missing <= 0 && !ready) {
      // Archivos listos pero falta marcar versión.
      return (needsDownload: false, pendingBytes: 0, pendingCount: 0);
    }
    final avg = 1650000;
    return (
      needsDownload: missing > 0,
      pendingBytes: missing * avg,
      pendingCount: missing,
    );
  }

  Future<Set<int>> loadPlayerIdsFromCatalog() async {
    try {
      final docs = await _cache.playersDirectory();
      final cardsFile = File('${docs.parent.path}/cards.json');
      if (await cardsFile.exists()) {
        return _parsePlayerIds(await cardsFile.readAsString());
      }
    } catch (_) {}
    final bundled = await rootBundle.loadString('assets/data/clash/cards.json');
    return _parsePlayerIds(bundled);
  }

  Set<int> _parsePlayerIds(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final cards = (root['cards'] as List?) ?? const [];
    final ids = <int>{};
    for (final c in cards) {
      if (c is! Map) continue;
      final id = c['playerId'];
      if (id is int && id > 0) {
        ids.add(id);
      } else if (id is num) {
        ids.add(id.toInt());
      }
    }
    return ids;
  }

  Future<ClashContentDownloadResult> ensureMediaPack({
    void Function(ClashContentDownloadProgress progress)? onProgress,
  }) async {
    final manifest = await ClashContentManifest.loadBundled();
    final ids = await loadPlayerIdsFromCatalog();
    if (ids.isEmpty) {
      return const ClashContentDownloadResult(
        success: false,
        usedBundledFallback: false,
        errorMessage: 'Catalog without players',
      );
    }

    await _cache.playersDirectory();
    final estimate = manifest.portraitsBytesEstimate > 0
        ? manifest.portraitsBytesEstimate
        : ids.length * 1650000;

    final already = await _cache.countPresent(ids);
    if (already >= ids.length &&
        await isReady(portraitsVersion: manifest.portraitsVersion)) {
      final bytes = await _cache.bytesPresent(ids);
      onProgress?.call(
        ClashContentDownloadProgress(
          phase: 'ready',
          downloadedBytes: bytes > 0 ? bytes : estimate,
          totalBytes: bytes > 0 ? bytes : estimate,
          detail: 'portraits',
        ),
      );
      return const ClashContentDownloadResult(
        success: true,
        usedBundledFallback: false,
      );
    }

    final missing = <int>[];
    final dir = await _cache.playersDirectory();
    var presentBytes = 0;
    for (final id in ids) {
      final f = _cache.fileFor(id, dir);
      if (await f.exists() && await f.length() > 0) {
        presentBytes += await f.length();
        await _cache.remember(id, f);
      } else {
        missing.add(id);
      }
    }

    final avg = presentBytes > 0 && (ids.length - missing.length) > 0
        ? presentBytes ~/ (ids.length - missing.length)
        : 1650000;
    final totalBytes = presentBytes + missing.length * avg;

    onProgress?.call(
      ClashContentDownloadProgress(
        phase: 'portraits',
        downloadedBytes: presentBytes,
        totalBytes: totalBytes,
        detail: 'portraits',
      ),
    );

    if (missing.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsPortraitsVersion, manifest.portraitsVersion);
      await prefs.setBool(_prefsReady, true);
      onProgress?.call(
        ClashContentDownloadProgress(
          phase: 'ready',
          downloadedBytes: presentBytes,
          totalBytes: presentBytes,
          detail: 'portraits',
        ),
      );
      return const ClashContentDownloadResult(
        success: true,
        usedBundledFallback: false,
      );
    }

    var downloadedBytes = presentBytes;
    var failures = 0;
    final queue = List<int>.from(missing);

    Future<void> worker() async {
      while (true) {
        if (queue.isEmpty) return;
        final id = queue.removeLast();
        try {
          final bytes = await _downloadOne(id, dir);
          downloadedBytes += bytes;
          onProgress?.call(
            ClashContentDownloadProgress(
              phase: 'portraits',
              downloadedBytes: downloadedBytes.clamp(0, totalBytes),
              totalBytes: totalBytes,
              detail: 'portraits',
            ),
          );
        } catch (e) {
          failures++;
          debugPrint('Portrait download failed id=$id: $e');
        }
      }
    }

    final nWorkers = math.min(_concurrency, missing.length);
    await Future.wait(List.generate(nWorkers, (_) => worker()));

    final presentAfter = await _cache.countPresent(ids);
    final ok = presentAfter >= ids.length ||
        presentAfter >= (ids.length * 0.98).floor();

    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsPortraitsVersion, manifest.portraitsVersion);
      await prefs.setBool(_prefsReady, true);
      final bytes = await _cache.bytesPresent(ids);
      onProgress?.call(
        ClashContentDownloadProgress(
          phase: 'ready',
          downloadedBytes: bytes,
          totalBytes: bytes,
          detail: 'portraits',
        ),
      );
      return ClashContentDownloadResult(
        success: true,
        usedBundledFallback: false,
        errorMessage: failures > 0 ? 'Partial failures: $failures' : null,
      );
    }

    return ClashContentDownloadResult(
      success: false,
      usedBundledFallback: false,
      errorMessage:
          'Incomplete download ($presentAfter/${ids.length}). Failures: $failures',
    );
  }

  Future<int> _downloadOne(int playerId, Directory dir) async {
    final url = LeagueAssetUrls.playerPhoto(playerId).toString();
    final dest = _cache.fileFor(playerId, dir);
    final tmp = File('${dest.path}.tmp');
    await _dio.download(
      url,
      tmp.path,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    if (await dest.exists()) {
      await dest.delete();
    }
    await tmp.rename(dest.path);
    final len = await dest.length();
    await _cache.remember(playerId, dest);
    return len;
  }
}
