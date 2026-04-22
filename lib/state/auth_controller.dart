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
      // Fetch current user profile from real API endpoint.
      final res = await _api.getJson('/auth/profile');
      if (res['user'] is Map<String, dynamic>) {
        user = User.fromJson(res['user'] as Map<String, dynamic>);
      } else if (res is Map<String, dynamic>) {
        // Response might be the user object directly
        user = User.fromJson(res);
      }
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
      // Parse snake_case fields from real API response
      final access = res['access_token'] ?? res['accessToken'];
      final refresh = res['refresh_token'] ?? res['refreshToken'];
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
