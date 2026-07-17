import 'dart:convert';

import 'package:flutter/services.dart';

/// Manifiesto local del pack de cartas Clash descargable.
class ClashContentManifest {
  const ClashContentManifest({
    required this.schemaVersion,
    required this.cardsVersion,
    required this.cardsUrl,
    required this.cardsBytes,
    required this.playerCount,
    required this.cardCount,
    this.portraitsBaseUrl,
    this.portraitsBytesEstimate = 0,
    this.portraitsVersion = 1,
  });

  final int schemaVersion;
  final int cardsVersion;
  final String cardsUrl;
  final int cardsBytes;
  final int playerCount;
  final int cardCount;
  final String? portraitsBaseUrl;
  final int portraitsBytesEstimate;
  final int portraitsVersion;

  static const assetPath = 'assets/data/clash/cards_manifest.json';

  static Future<ClashContentManifest> loadBundled() async {
    final raw = await rootBundle.loadString(assetPath);
    return ClashContentManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory ClashContentManifest.fromJson(Map<String, dynamic> json) {
    return ClashContentManifest(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      cardsVersion: json['cardsVersion'] as int? ?? 1,
      cardsUrl: json['cardsUrl'] as String? ?? '',
      cardsBytes: json['cardsBytes'] as int? ?? 0,
      playerCount: json['playerCount'] as int? ?? 0,
      cardCount: json['cardCount'] as int? ?? 0,
      portraitsBaseUrl: json['portraitsBaseUrl'] as String?,
      portraitsBytesEstimate: json['portraitsBytesEstimate'] as int? ?? 0,
      portraitsVersion: json['portraitsVersion'] as int? ?? 1,
    );
  }
}

/// Progreso de descarga del contenido Clash (cartas + datos).
class ClashContentDownloadProgress {
  const ClashContentDownloadProgress({
    required this.phase,
    required this.downloadedBytes,
    required this.totalBytes,
    this.detail,
  });

  final String phase;
  final int downloadedBytes;
  final int totalBytes;
  final String? detail;

  double get fraction =>
      totalBytes <= 0 ? 0 : (downloadedBytes / totalBytes).clamp(0.0, 1.0);

  String get mbLabel {
    String fmt(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '${fmt(downloadedBytes)} / ${fmt(totalBytes)} MB';
  }
}

/// Resultado final de la descarga de contenido.
class ClashContentDownloadResult {
  const ClashContentDownloadResult({
    required this.success,
    required this.usedBundledFallback,
    this.errorMessage,
  });

  final bool success;
  final bool usedBundledFallback;
  final String? errorMessage;
}
