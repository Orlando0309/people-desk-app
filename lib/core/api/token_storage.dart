import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  const AuthTokens({required this.accessToken, required this.refreshToken});
}

/// Secure storage wrapper (handles web/plugin edge-cases defensively).
class TokenStorage {
  static const _kAccessTokenKey = 'access_token';
  static const _kRefreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  TokenStorage({FlutterSecureStorage? storage})
      : _storage =
            storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  Future<AuthTokens?> readTokens() async {
    try {
      final access = await _storage.read(key: _kAccessTokenKey);
      final refresh = await _storage.read(key: _kRefreshTokenKey);
      if (access == null || refresh == null) return null;
      return AuthTokens(accessToken: access, refreshToken: refresh);
    } catch (e) {
      debugPrint('TokenStorage.readTokens failed: $e');
      return null;
    }
  }

  Future<void> writeTokens(AuthTokens tokens) async {
    try {
      await _storage.write(key: _kAccessTokenKey, value: tokens.accessToken);
      await _storage.write(key: _kRefreshTokenKey, value: tokens.refreshToken);
    } catch (e) {
      debugPrint('TokenStorage.writeTokens failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kAccessTokenKey);
      await _storage.delete(key: _kRefreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage.clear failed: $e');
    }
  }
}
