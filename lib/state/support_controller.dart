import 'package:flutter/foundation.dart';
import 'package:people_desk/core/api/api_client.dart';

class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final DateTime createdAt;
  const SupportTicket({required this.id, required this.subject, required this.status, required this.createdAt});
}

class TicketReply {
  final String id;
  final String message;
  final DateTime createdAt;
  final bool fromStaff;
  const TicketReply({required this.id, required this.message, required this.createdAt, required this.fromStaff});
}

class TicketDetail {
  final SupportTicket ticket;
  final List<TicketReply> replies;
  const TicketDetail({required this.ticket, required this.replies});
}

class SupportController extends ChangeNotifier {
  final ApiClient _api;
  SupportController({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  bool isLoading = false;
  String? error;
  List<SupportTicket> tickets = const [];

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/support/tickets');
      // API returns {tickets: [...]}, fallback to data/items for mock compatibility
      final list = res['tickets'] is List
          ? res['tickets'] as List
          : (res['data'] is List ? res['data'] as List : (res['items'] is List ? res['items'] as List : const []));
      tickets = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (j) => SupportTicket(
              id: (j['id'] ?? j['_id'] ?? '').toString(),
              subject: (j['subject'] ?? 'Ticket').toString(),
              status: (j['status'] ?? 'open').toString(),
              createdAt: DateTime.tryParse(j['created_at']?.toString() ?? j['createdAt']?.toString() ?? '') ?? DateTime.now(),
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('SupportController.refresh failed: $e');
      error = 'Failed to load tickets';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketDetail?> fetchDetail(String id) async {
    try {
      final res = await _api.getJson('/support/tickets/$id');
      // API may return direct ticket object or wrapped in 'data'
      final data = (res['data'] is Map<String, dynamic>) ? res['data'] as Map<String, dynamic> : res;
      final ticket = SupportTicket(
        id: id,
        subject: (data['subject'] ?? 'Ticket').toString(),
        status: (data['status'] ?? 'open').toString(),
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

      final rawReplies = data['replies'];
      final replies = rawReplies is List
          ? rawReplies
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .map(
                (j) => TicketReply(
                  id: (j['id'] ?? j['_id'] ?? '').toString(),
                  message: (j['message'] ?? j['content'] ?? '').toString(),
                  createdAt: DateTime.tryParse(j['created_at']?.toString() ?? j['createdAt']?.toString() ?? '') ?? DateTime.now(),
                  fromStaff: j['from_staff'] == true || j['fromStaff'] == true,
                ),
              )
              .toList(growable: false)
          : const <TicketReply>[];

      return TicketDetail(ticket: ticket, replies: replies);
    } catch (e) {
      debugPrint('SupportController.fetchDetail failed: $e');
      return null;
    }
  }

  Future<void> createTicket({required String subject, required String message, String category = 'other'}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.postJson('/support/tickets', body: {
        'subject': subject,
        'description': message,
        'category': category,
      });
      await refresh();
    } catch (e) {
      debugPrint('SupportController.createTicket failed: $e');
      error = 'Failed to create ticket';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replyToTicket(String id, {required String message}) async {
    try {
      await _api.postJson('/support/tickets/$id/reply', body: {'message': message});
    } catch (e) {
      debugPrint('SupportController.replyToTicket failed: $e');
    }
  }
}