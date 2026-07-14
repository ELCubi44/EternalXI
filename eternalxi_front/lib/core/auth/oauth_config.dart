import 'dart:convert';

import 'package:flutter/services.dart';

/// Resuelve el Web Client ID de Google para obtener idToken en Android.
class OAuthConfig {
  OAuthConfig._();

  static String? _cachedWebClientId;

  static const _assetPath = 'assets/app/oauth_config.json';

  static Future<String> resolveGoogleWebClientId() async {
    if (_cachedWebClientId != null) {
      return _cachedWebClientId!;
    }

    const fromDefine = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) {
      _cachedWebClientId = fromDefine.trim();
      return _cachedWebClientId!;
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final fromAsset = (json['googleWebClientId'] ?? '').toString().trim();
      if (fromAsset.isNotEmpty) {
        _cachedWebClientId = fromAsset;
        return fromAsset;
      }
    } catch (_) {}

    return '';
  }
}
