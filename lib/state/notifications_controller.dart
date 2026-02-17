import 'package:flutter/foundation.dart';
import 'package:people_desk/core/api/api_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  const AppNotification({required this.id, required this.title, required this.body, required this.createdAt, required this.read});
}

class NotificationsController extends ChangeNotifier {
  final ApiClient _api;
  NotificationsController({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  bool isLoading = false;
  String? error;
  List<AppNotification> items = const [];

  int get unreadCount => items.where((n) => !n.read).length;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/notifications');
      final list = res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []);
      items = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (j) => AppNotification(
              id: (j['id'] ?? j['_id'] ?? '').toString(),
              title: (j['title'] ?? 'Notification').toString(),
              body: (j['body'] ?? j['message'] ?? '').toString(),
              createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
              read: j['read'] == true,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('NotificationsController.refresh failed: $e');
      error = 'Failed to load notifications';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.postJson('/notifications/$id/read');
    } catch (e) {
      debugPrint('NotificationsController.markRead failed: $e');
    }
    items = items
        .map((n) => n.id == id ? AppNotification(id: n.id, title: n.title, body: n.body, createdAt: n.createdAt, read: true) : n)
        .toList(growable: false);
    notifyListeners();
  }
}
