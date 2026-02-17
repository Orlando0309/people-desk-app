import 'package:flutter/foundation.dart';
import 'package:people_desk/core/api/api_client.dart';

class Payslip {
  final String id;
  final String label;
  final DateTime period;
  final double net;
  const Payslip({required this.id, required this.label, required this.period, required this.net});
}

class PayslipLine {
  final String label;
  final double amount;
  const PayslipLine({required this.label, required this.amount});
}

class PayslipDetail {
  final Payslip payslip;
  final List<PayslipLine> earnings;
  final List<PayslipLine> deductions;
  const PayslipDetail({required this.payslip, required this.earnings, required this.deductions});
}

class PayrollController extends ChangeNotifier {
  final ApiClient _api;
  PayrollController({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  bool isLoading = false;
  String? error;
  List<Payslip> payslips = const [];

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/payslips');
      final list = res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []);
      payslips = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (j) => Payslip(
              id: (j['id'] ?? j['_id'] ?? '').toString(),
              label: (j['label'] ?? j['title'] ?? 'Payslip').toString(),
              period: DateTime.tryParse(j['period']?.toString() ?? '') ?? DateTime.now(),
              net: (j['net'] is num) ? (j['net'] as num).toDouble() : 0,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('PayrollController.refresh failed: $e');
      error = 'Failed to load payslips';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<PayslipDetail?> fetchDetail(String id) async {
    try {
      final res = await _api.getJson('/payslips/$id');
      final data = (res['data'] is Map<String, dynamic>) ? res['data'] as Map<String, dynamic> : res;
      final p = Payslip(
        id: id,
        label: (data['label'] ?? data['title'] ?? 'Payslip').toString(),
        period: DateTime.tryParse(data['period']?.toString() ?? '') ?? DateTime.now(),
        net: (data['net'] is num) ? (data['net'] as num).toDouble() : 0,
      );

      List<PayslipLine> mapLines(dynamic raw) {
        if (raw is! List) return const [];
        return raw
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map(
              (j) => PayslipLine(
                label: (j['label'] ?? j['name'] ?? '').toString(),
                amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : 0,
              ),
            )
            .toList(growable: false);
      }

      return PayslipDetail(
        payslip: p,
        earnings: mapLines(data['earnings']),
        deductions: mapLines(data['deductions']),
      );
    } catch (e) {
      debugPrint('PayrollController.fetchDetail failed: $e');
      return null;
    }
  }
}
