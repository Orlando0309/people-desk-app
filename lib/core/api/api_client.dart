import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:people_desk/core/api/token_storage.dart';
import 'package:people_desk/core/api/mock_api.dart';
import 'package:people_desk/core/config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

/// Simple REST client with optional token refresh.
///
/// Real API contract:
/// - login: POST /auth/login -> {access_token, refresh_token, user}
/// - refresh: POST /auth/refresh -> {access_token} (refresh token remains valid)
class ApiClient {
  final http.Client _http;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
      : _http = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl; // Now a getter for platform detection
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    return _sendJson('GET', path, query: query);
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    return _sendJson('POST', path, body: body);
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    return _sendJson('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> deleteJson(String path, {Object? body}) async {
    return _sendJson('DELETE', path, body: body);
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool retried = false,
  }) async {
    if (AppConfig.useMock) {
      try {
        // Keep the same return contract as the real client (a JSON map).
        return MockApiServer.handle(method, path, body: body);
      } on MockApiException catch (e) {
        throw ApiException(e.message, statusCode: e.statusCode);
      } catch (e) {
        debugPrint('Mock ApiClient failed: $e');
        throw const ApiException('Mock backend error');
      }
    }

    final tokens = await _tokenStorage.readTokens();
    final headers = <String, String>{'content-type': 'application/json'};
    if (tokens != null) headers['authorization'] = 'Bearer ${tokens.accessToken}';

    http.Response res;
    try {
      final uri = _uri(path, query);
      final encodedBody = body == null ? null : jsonEncode(body);
      final req = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = encodedBody ?? '';
      final streamed = await _http.send(req);
      res = await http.Response.fromStream(streamed);
    } catch (e) {
      debugPrint('ApiClient request failed: $e');
      throw const ApiException('Network error');
    }

    if (res.statusCode == 401 && !retried && tokens != null) {
      final refreshed = await _tryRefresh(tokens.refreshToken);
      if (refreshed != null) {
        await _tokenStorage.writeTokens(refreshed);
        return _sendJson(method, path, query: query, body: body, retried: true);
      }
    }

    final decoded = _decodeJson(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (decoded is Map && decoded['message'] is String)
          ? decoded['message'] as String
          : 'Request failed';
      throw ApiException(msg, statusCode: res.statusCode);
    }

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded == null) return <String, dynamic>{};
    return <String, dynamic>{'data': decoded};
  }

  dynamic _decodeJson(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      final text = utf8.decode(res.bodyBytes);
      return jsonDecode(text);
    } catch (e) {
      debugPrint('ApiClient JSON decode failed: $e');
      return null;
    }
  }

  Future<AuthTokens?> _tryRefresh(String refreshToken) async {
    try {
      final uri = _uri('/auth/refresh');
      final res = await _http.post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = _decodeJson(res);
      if (decoded is! Map) return null;
      // Real API returns access_token; keep existing refresh token if not returned
      final access = decoded['access_token'] ?? decoded['accessToken'];
      if (access is! String) return null;
      final refresh = decoded['refresh_token'] ?? decoded['refreshToken'] ?? refreshToken;
      return AuthTokens(accessToken: access, refreshToken: refresh as String);
    } catch (e) {
      debugPrint('ApiClient refresh failed: $e');
      return null;
    }
  }
}
