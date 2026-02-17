import 'package:flutter/foundation.dart';
import 'package:people_desk/core/api/api_client.dart';
import 'package:people_desk/core/api/token_storage.dart';
import 'package:people_desk/models/user.dart';

class AuthController extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;

  User? user;
  bool isLoading = false;
  String? error;

  AuthController({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _api = apiClient ?? ApiClient(),
        _storage = tokenStorage ?? TokenStorage();

  bool get isAuthed => user != null;

  Future<void> bootstrap() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final tokens = await _storage.readTokens();
      if (tokens == null) return;
      // Attempt to fetch current user; adjust endpoint to your backend.
      final res = await _api.getJson('/me');
      if (res['user'] is Map<String, dynamic>) user = User.fromJson(res['user'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AuthController.bootstrap failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.postJson('/auth/login', body: {'email': email, 'password': password});
      final access = res['accessToken'];
      final refresh = res['refreshToken'];
      if (access is String && refresh is String) {
        await _storage.writeTokens(AuthTokens(accessToken: access, refreshToken: refresh));
      }
      if (res['user'] is Map<String, dynamic>) {
        user = User.fromJson(res['user'] as Map<String, dynamic>);
      } else {
        // Fallback: at least keep email visible.
        user = User(id: 'me', email: email);
      }
      return true;
    } catch (e) {
      debugPrint('AuthController.login failed: $e');
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _storage.clear();
      user = null;
    } catch (e) {
      debugPrint('AuthController.logout failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
