import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:eternal_xi/core/auth/oauth_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OAuthSignInService {
  OAuthSignInService({GoogleSignIn? googleSignIn}) : _googleSignIn = googleSignIn;

  GoogleSignIn? _googleSignIn;
  String? _webClientId;

  Future<GoogleSignIn> _ensureGoogleSignIn() async {
    if (_googleSignIn != null) {
      return _googleSignIn!;
    }
    _webClientId = await OAuthConfig.resolveGoogleWebClientId();
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: (_webClientId == null || _webClientId!.isEmpty)
          ? null
          : _webClientId,
    );
    return _googleSignIn!;
  }

  Future<String?> signInWithGoogle({bool forceAccountPicker = false}) async {
    try {
      final googleSignIn = await _ensureGoogleSignIn();
      if ((_webClientId ?? '').isEmpty) {
        throw StateError(
          'Falta GOOGLE_WEB_CLIENT_ID. Configuralo en assets/app/oauth_config.json '
          'o compila con --dart-define=GOOGLE_WEB_CLIENT_ID=...',
        );
      }
      if (forceAccountPicker) {
        await googleSignIn.signOut();
      }
      final account = await googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google no devolvio idToken. Revisa el Web Client ID en Firebase.',
        );
      }
      return idToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[oauth] Google sign-in error: $e');
      }
      rethrow;
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw StateError(
          'Iniciar sesion con Apple no esta disponible en este dispositivo.',
        );
      }
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Apple no devolvio identityToken');
      }
      return idToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      if (kDebugMode) {
        debugPrint('[oauth] Apple authorization error: ${e.code} ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[oauth] Apple sign-in error: $e');
      }
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      final googleSignIn = _googleSignIn ?? await _ensureGoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
