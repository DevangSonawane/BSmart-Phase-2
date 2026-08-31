import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../models/auth/apple_auth_models.dart';

class AppleAuthService {
  static final AppleAuthService _instance = AppleAuthService._internal();
  factory AppleAuthService() => _instance;
  AppleAuthService._internal();

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<AppleAuthenticationResult?> signIn() async {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'Sign in with Apple is currently enabled only on iOS and macOS.',
      );
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);
    final state = _generateNonce(length: 24);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        state: state,
      );

      final identityToken = credential.identityToken?.trim();
      final authorizationCode = credential.authorizationCode.trim();
      final userIdentifier = credential.userIdentifier?.trim() ?? '';

      if (userIdentifier.isEmpty) {
        throw const AppleAuthException(
          'Apple authentication did not return a user identifier.',
        );
      }
      if (identityToken == null || identityToken.isEmpty) {
        throw const AppleAuthException(
          'Apple authentication did not return an identity token.',
        );
      }
      if (authorizationCode.isEmpty) {
        throw const AppleAuthException(
          'Apple authentication did not return an authorization code.',
        );
      }

      return AppleAuthenticationResult(
        credential: AppleCredential(
          userIdentifier: userIdentifier,
          identityToken: identityToken,
          authorizationCode: authorizationCode,
          email: credential.email,
          givenName: credential.givenName,
          familyName: credential.familyName,
          state: credential.state,
        ),
        rawNonce: rawNonce,
        hashedNonce: hashedNonce,
        authenticatedAt: DateTime.now(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw AppleAuthException('Apple sign-in failed: ${e.message}');
    } on SignInWithAppleException catch (e) {
      throw AppleAuthException('Apple sign-in failed: $e');
    } catch (e) {
      throw AppleAuthException('Apple sign-in failed: $e');
    }
  }

  String _generateNonce({int length = 32}) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class AppleAuthException implements Exception {
  final String message;

  const AppleAuthException(this.message);

  @override
  String toString() => message;
}
