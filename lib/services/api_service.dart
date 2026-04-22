import 'package:people_desk/core/api/api_client.dart';

/// Generic service for new PeopleDesk modules.
class ApiService {
  final ApiClient _client;
  ApiService({ApiClient? client}) : _client = client ?? ApiClient();

  // ---- Recruitment ----
  Future<List<dynamic>> getJobs({Map<String, String>? query}) async {
    final res = await _client.getJson('/jobs', query: query);
    return (res['jobs'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    return _client.postJson('/jobs', body: body);
  }

  Future<void> deleteJob(String id) async {
    await _client.deleteJson('/jobs/$id');
  }

  Future<List<dynamic>> getCandidates({Map<String, String>? query}) async {
    final res = await _client.getJson('/candidates', query: query);
    return (res['candidates'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createCandidate(Map<String, dynamic> body) async {
    return _client.postJson('/candidates', body: body);
  }

  Future<Map<String, dynamic>> updateCandidate(String id, Map<String, dynamic> body) async {
    return _client.putJson('/candidates/$id', body: body);
  }

  // ---- Documents ----
  Future<List<dynamic>> getDocuments({Map<String, String>? query}) async {
    final res = await _client.getJson('/documents', query: query);
    return (res['documents'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createDocument(Map<String, dynamic> body) async {
    return _client.postJson('/documents', body: body);
  }

  Future<void> deleteDocument(String id) async {
    await _client.deleteJson('/documents/$id');
  }

  // ---- Expenses ----
  Future<List<dynamic>> getExpenses({Map<String, String>? query}) async {
    final res = await _client.getJson('/expenses', query: query);
    return (res['expenses'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> body) async {
    return _client.postJson('/expenses', body: body);
  }

  Future<Map<String, dynamic>> approveExpense(String id, String approverId) async {
    return _client.putJson('/expenses/$id/approve', body: {'approver_id': approverId});
  }

  Future<Map<String, dynamic>> rejectExpense(String id, String approverId, String reason) async {
    return _client.putJson('/expenses/$id/reject', body: {'approver_id': approverId, 'rejection_reason': reason});
  }

  // ---- Training ----
  Future<List<dynamic>> getTrainingPrograms({Map<String, String>? query}) async {
    final res = await _client.getJson('/training/programs', query: query);
    return (res['programs'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createTrainingProgram(Map<String, dynamic> body) async {
    return _client.postJson('/training/programs', body: body);
  }

  Future<void> deleteTrainingProgram(String id) async {
    await _client.deleteJson('/training/programs/$id');
  }

  Future<List<dynamic>> getEnrollments({Map<String, String>? query}) async {
    final res = await _client.getJson('/training/enrollments', query: query);
    return (res['enrollments'] ?? []) as List;
  }

  // ---- Benefits ----
  Future<List<dynamic>> getBenefitPlans({Map<String, String>? query}) async {
    final res = await _client.getJson('/benefits/plans', query: query);
    return (res['plans'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createBenefitPlan(Map<String, dynamic> body) async {
    return _client.postJson('/benefits/plans', body: body);
  }

  Future<void> deleteBenefitPlan(String id) async {
    await _client.deleteJson('/benefits/plans/$id');
  }

  // ---- Offboarding ----
  Future<List<dynamic>> getOffboardingRecords({Map<String, String>? query}) async {
    final res = await _client.getJson('/offboarding', query: query);
    return (res['records'] ?? []) as List;
  }

  Future<Map<String, dynamic>> createOffboardingRecord(Map<String, dynamic> body) async {
    return _client.postJson('/offboarding', body: body);
  }

  Future<Map<String, dynamic>> updateOffboardingRecord(String id, Map<String, dynamic> body) async {
    return _client.putJson('/offboarding/$id', body: body);
  }

  // ---- Org Chart ----
  Future<List<dynamic>> getOrgChart() async {
    final res = await _client.getJson('/employees/org-chart');
    return (res['org_chart'] ?? []) as List;
  }
}
