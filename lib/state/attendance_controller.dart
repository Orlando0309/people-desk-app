import 'package:flutter/foundation.dart';
import 'package:people_desk/core/api/api_client.dart';

class AttendanceDay {
  final DateTime date;
  final String status;
  final String? clockInAt;
  final String? clockOutAt;
  const AttendanceDay({required this.date, required this.status, this.clockInAt, this.clockOutAt});
}

class AttendanceController extends ChangeNotifier {
  final ApiClient _api;
  AttendanceController({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  bool isLoading = false;
  String? error;
  AttendanceDay? today;
  List<AttendanceDay> history = const [];

  Future<void> refreshAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([fetchToday(), fetchHistory()]);
    } catch (e) {
      debugPrint('AttendanceController.refreshAll failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchToday() async {
    try {
      final res = await _api.getJson('/attendance/today');
      final data = (res['data'] is Map<String, dynamic>) ? res['data'] as Map<String, dynamic> : res;
      today = _mapDay(data);
    } catch (e) {
      debugPrint('AttendanceController.fetchToday failed: $e');
      error = 'Failed to load today\'s attendance';
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    try {
      final res = await _api.getJson('/attendance');
      final list = res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []);
      history = list
          .whereType<Map>()
          .map((e) => _mapDay(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList(growable: false);
    } catch (e) {
      debugPrint('AttendanceController.fetchHistory failed: $e');
      error = 'Failed to load attendance history';
    } finally {
      notifyListeners();
    }
  }

  Future<void> clockIn() async {
    await _clockAction('/attendance/clock-in');
  }

  Future<void> clockOut() async {
    await _clockAction('/attendance/clock-out');
  }

  Future<void> _clockAction(String path) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.postJson(path);
      await refreshAll();
    } catch (e) {
      debugPrint('AttendanceController clock action failed: $e');
      error = 'Clock action failed';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  AttendanceDay _mapDay(Map<String, dynamic> json) {
    final dateRaw = json['date']?.toString();
    final date = DateTime.tryParse(dateRaw ?? '') ?? DateTime.now();
    return AttendanceDay(
      date: date,
      status: (json['status'] ?? 'Unknown').toString(),
      clockInAt: json['clockInAt']?.toString(),
      clockOutAt: json['clockOutAt']?.toString(),
    );
  }
}
