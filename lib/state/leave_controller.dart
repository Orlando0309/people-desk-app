import 'package:flutter/foundation.dart';
import 'package:people_desk/core/api/api_client.dart';

class LeaveBalance {
  final String label;
  final double remaining;
  final double total;
  const LeaveBalance({required this.label, required this.remaining, required this.total});
}

class LeaveRequest {
  final String id;
  final String type;
  final DateTime start;
  final DateTime end;
  final String status;
  const LeaveRequest({required this.id, required this.type, required this.start, required this.end, required this.status});
}

class LeaveController extends ChangeNotifier {
  final ApiClient _api;
  LeaveController({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  bool isLoading = false;
  String? error;
  List<LeaveBalance> balances = const [];
  List<LeaveRequest> requests = const [];

  Future<void> refreshAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([fetchBalances(), fetchRequests()]);
    } catch (e) {
      debugPrint('LeaveController.refreshAll failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBalances() async {
    try {
      final res = await _api.getJson('/leave/balances');
      final list = res['data'] is List ? res['data'] as List : const [];
      balances = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (j) => LeaveBalance(
              label: (j['label'] ?? j['type'] ?? 'Leave').toString(),
              remaining: (j['remaining'] is num) ? (j['remaining'] as num).toDouble() : 0,
              total: (j['total'] is num) ? (j['total'] as num).toDouble() : 0,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('LeaveController.fetchBalances failed: $e');
      error = 'Failed to load balances';
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchRequests() async {
    try {
      final res = await _api.getJson('/leave/requests');
      final list = res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []);
      requests = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (j) => LeaveRequest(
              id: (j['id'] ?? j['_id'] ?? '').toString(),
              type: (j['type'] ?? 'Leave').toString(),
              start: DateTime.tryParse(j['start']?.toString() ?? '') ?? DateTime.now(),
              end: DateTime.tryParse(j['end']?.toString() ?? '') ?? DateTime.now(),
              status: (j['status'] ?? 'pending').toString(),
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('LeaveController.fetchRequests failed: $e');
      error = 'Failed to load requests';
    } finally {
      notifyListeners();
    }
  }

  Future<void> createRequest({required String type, required DateTime start, required DateTime end, String? reason}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.postJson('/leave/requests', body: {
        'type': type,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        if (reason != null) 'reason': reason,
      });
      await refreshAll();
    } catch (e) {
      debugPrint('LeaveController.createRequest failed: $e');
      error = 'Failed to create request';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelRequest(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.deleteJson('/leave/requests/$id');
      await refreshAll();
    } catch (e) {
      debugPrint('LeaveController.cancelRequest failed: $e');
      error = 'Failed to cancel request';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
