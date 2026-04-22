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
      await Future.wait([fetchBalances(employeeId), fetchRequests()]);
    } catch (e) {
      debugPrint('LeaveController.refreshAll failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Transforms flat API balance response into array format.
  /// API returns: {annual_total, annual_used, annual_remaining, sick_total, sick_used, ...}
  /// Flutter expects: [{label, remaining, total}, ...]
  Future<void> fetchBalances(String? employeeId) async {
    if (employeeId == null) {
      error = 'Employee ID required';
      notifyListeners();
      return;
    }
    try {
      final res = await _api.getJson('/leaves/balance/$employeeId');

      // Get data from response - could be flat object or wrapped in 'data'
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : (res is Map<String, dynamic> ? res : <String, dynamic>{});

      // Check if API returned an array format (backward compatibility)
      if (res['data'] is List || res is List) {
        final list = res['data'] is List ? res['data'] as List : (res is List ? res as List : const []);
        balances = list
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map(
              (j) => LeaveBalance(
                label: (j['label'] ?? j['leave_type'] ?? j['type'] ?? 'Leave').toString(),
                remaining: (j['annual_remaining'] ?? j['remaining']) is num
                    ? ((j['annual_remaining'] ?? j['remaining']) as num).toDouble()
                    : 0,
                total: (j['annual_total'] ?? j['total']) is num
                    ? ((j['annual_total'] ?? j['total']) as num).toDouble()
                    : 0,
              ),
            )
            .toList(growable: false);
      } else {
        // Transform flat API response into array format
        final List<LeaveBalance> list = [];

        // Annual leave
        final annualTotal = (data['annual_total'] as num?)?.toDouble() ?? 30;
        final annualRemaining = (data['annual_remaining'] as num?)?.toDouble() ?? 0;
        list.add(LeaveBalance(
          label: 'Annual',
          remaining: annualRemaining,
          total: annualTotal,
        ));

        // Sick leave
        final sickTotal = (data['sick_total'] as num?)?.toDouble() ?? 10;
        final sickUsed = (data['sick_used'] as num?)?.toDouble() ?? 0;
        list.add(LeaveBalance(
          label: 'Sick',
          remaining: sickTotal - sickUsed,
          total: sickTotal,
        ));

        // Casual leave (if available)
        if (data.containsKey('casual_total') || data.containsKey('casual_remaining')) {
          final casualTotal = (data['casual_total'] as num?)?.toDouble() ?? 0;
          final casualRemaining = (data['casual_remaining'] as num?)?.toDouble() ?? 0;
          if (casualTotal > 0) {
            list.add(LeaveBalance(
              label: 'Casual',
              remaining: casualRemaining,
              total: casualTotal,
            ));
          }
        }

        balances = list;
      }
    } catch (e) {
      debugPrint('LeaveController.fetchBalances failed: $e');
      error = 'Failed to load balances';
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchRequests() async {
    try {
      final res = await _api.getJson('/leaves');
      // API returns {leaves: [...]}, fallback to data/items for mock compatibility
      final list = res['leaves'] is List
          ? res['leaves'] as List
          : (res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []));
      requests = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (j) => LeaveRequest(
              id: (j['id'] ?? j['_id'] ?? '').toString(),
              type: (j['leave_type'] ?? j['type'] ?? 'Leave').toString(),
              start: DateTime.tryParse(j['start_date']?.toString() ?? j['start']?.toString() ?? '') ?? DateTime.now(),
              end: DateTime.tryParse(j['end_date']?.toString() ?? j['end']?.toString() ?? '') ?? DateTime.now(),
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

  Future<void> createRequest({
    required String? employeeId,
    required String type,
    required DateTime start,
    required DateTime end,
    int? daysRequested,
    String? reason,
  }) async {
    if (employeeId == null) {
      error = 'Employee ID required';
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.postJson('/leaves', body: {
        'employee_id': employeeId,
        'leave_type': type,
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        if (daysRequested != null) 'days_requested': daysRequested,
        if (reason != null) 'reason': reason,
      });
      await refreshAll(employeeId);
    } catch (e) {
      debugPrint('LeaveController.createRequest failed: $e');
      error = 'Failed to create request';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelRequest(String id, String? employeeId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.deleteJson('/leaves/$id');
      await refreshAll(employeeId);
    } catch (e) {
      debugPrint('LeaveController.cancelRequest failed: $e');
      error = 'Failed to cancel request';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}