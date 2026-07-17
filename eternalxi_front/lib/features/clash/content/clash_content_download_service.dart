import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eternal_xi/features/clash/content/clash_content_manifest.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Descarga y cachea el catalogo de cartas Clash (estilo gacha movil).
class ClashContentDownloadService {
  ClashContentDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  static const _prefsKeyVersion = 'clash_content_cards_version_v1';
  static const _cardsFileName = 'cards.json';
  static const _bundledCardsAsset = 'assets/data/clash/cards.json';

  final Dio _dio;

  Future<File> _cardsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final clashDir = Directory('${dir.path}/clash_content');
    if (!await clashDir.exists()) {
      await clashDir.create(recursive: true);
    }
    return File('${clashDir.path}/$_cardsFileName');
  }

  Future<bool> isUpToDate(ClashContentManifest manifest) async {
    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt(_prefsKeyVersion) ?? 0;
    final file = await _cardsFile();
    return localVersion >= manifest.cardsVersion && await file.exists();
  }

  /// True si hay catálogo nuevo pendiente de descarga.
  Future<bool> needsDownload() async {
    final manifest = await ClashContentManifest.loadBundled();
    return !(await isUpToDate(manifest));
  }

  Future<ClashContentManifest> loadManifest() =>
      ClashContentManifest.loadBundled();

  /// Usa el catálogo empaquetado en la app sin marcar la versión remota
  /// (así la próxima vez se vuelve a preguntar por el contenido nuevo).
  Future<ClashContentDownloadResult> useBundledForNow({
    void Function(ClashContentDownloadProgress progress)? onProgress,
  }) async {
    try {
      final bundled = await rootBundle.loadString(_bundledCardsAsset);
      final file = await _cardsFile();
      await file.writeAsString(bundled);
      onProgress?.call(
        ClashContentDownloadProgress(
          phase: 'ready',
          downloadedBytes: bundled.length,
          totalBytes: bundled.length,
          detail: 'bundled',
        ),
      );
      return const ClashContentDownloadResult(
        success: true,
        usedBundledFallback: true,
      );
    } catch (e) {
      return ClashContentDownloadResult(
        success: false,
        usedBundledFallback: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String?> loadLocalCardsJson() async {
    final file = await _cardsFile();
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  Future<ClashContentDownloadResult> ensureContent({
    void Function(ClashContentDownloadProgress progress)? onProgress,
  }) async {
    final manifest = await ClashContentManifest.loadBundled();
    if (await isUpToDate(manifest)) {
      onProgress?.call(
        ClashContentDownloadProgress(
          phase: 'ready',
          downloadedBytes: manifest.cardsBytes,
          totalBytes: manifest.cardsBytes,
          detail: 'catalog',
        ),
      );
      return const ClashContentDownloadResult(success: true, usedBundledFallback: false);
    }

    onProgress?.call(
      ClashContentDownloadProgress(
        phase: 'cards',
        downloadedBytes: 0,
        totalBytes: manifest.cardsBytes,
        detail: 'players',
      ),
    );

    try {
      await _downloadCards(manifest, onProgress);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyVersion, manifest.cardsVersion);
      return const ClashContentDownloadResult(success: true, usedBundledFallback: false);
    } catch (e) {
      debugPrint('Clash content download failed: $e');
      final copied = await _copyBundledFallback(manifest, onProgress);
      if (copied) {
        return ClashContentDownloadResult(
          success: true,
          usedBundledFallback: true,
          errorMessage: e.toString(),
        );
      }
      return ClashContentDownloadResult(
        success: false,
        usedBundledFallback: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _downloadCards(
    ClashContentManifest manifest,
    void Function(ClashContentDownloadProgress progress)? onProgress,
  ) async {
    final url = manifest.cardsUrl.trim();
    if (url.isEmpty) {
      throw StateError('cardsUrl vacia en manifest');
    }

    final file = await _cardsFile();
    final tempFile = File('${file.path}.tmp');

    await _dio.download(
      url,
      tempFile.path,
      onReceiveProgress: (received, total) {
        final effectiveTotal = total > 0 ? total : manifest.cardsBytes;
        onProgress?.call(
          ClashContentDownloadProgress(
            phase: 'cards',
            downloadedBytes: received,
            totalBytes: effectiveTotal,
            detail: 'players',
          ),
        );
      },
    );

    if (await tempFile.exists()) {
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
    }

    // Validacion minima JSON
    final raw = await file.readAsString();
    jsonDecode(raw);
  }

  Future<bool> _copyBundledFallback(
    ClashContentManifest manifest,
    void Function(ClashContentDownloadProgress progress)? onProgress,
  ) async {
    try {
      final bundled = await rootBundle.loadString(_bundledCardsAsset);
      final file = await _cardsFile();
      await file.writeAsString(bundled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyVersion, manifest.cardsVersion);
      onProgress?.call(
        ClashContentDownloadProgress(
          phase: 'ready',
          downloadedBytes: bundled.length,
          totalBytes: bundled.length,
          detail: 'bundled',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Bundled cards fallback failed: $e');
      return false;
    }
  }
}
