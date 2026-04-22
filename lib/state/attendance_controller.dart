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

  Future<void> refreshAll(String? employeeId) async {
    if (employeeId == null) {
      error = 'Employee ID required';
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([fetchToday(employeeId), fetchHistory()]);
    } catch (e) {
      debugPrint('AttendanceController.refreshAll failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchToday(String? employeeId) async {
    if (employeeId == null) {
      error = 'Employee ID required';
      notifyListeners();
      return;
    }
    try {
      final res = await _api.getJson('/attendance/today/$employeeId');
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
      // API returns {attendances: [...]}, fallback to data/items for mock compatibility
      final list = res['attendances'] is List
          ? res['attendances'] as List
          : (res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []));
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

  Future<void> clockIn(String? employeeId) async {
    await _clockAction('/attendance/clock-in', employeeId);
  }

  Future<void> clockOut(String? employeeId) async {
    await _clockAction('/attendance/clock-out', employeeId);
  }

  Future<void> _clockAction(String path, String? employeeId) async {
    if (employeeId == null) {
      error = 'Employee ID required';
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.postJson(path, body: {'employee_id': employeeId});
      await refreshAll(employeeId);
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
      clockInAt: json['clock_in']?.toString() ?? json['clockInAt']?.toString(),
      clockOutAt: json['clock_out']?.toString() ?? json['clockOutAt']?.toString(),
    );
  }
}
