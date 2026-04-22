import 'dart:math';

import 'package:flutter/foundation.dart';

/// Lightweight in-memory mock backend.
///
/// This lets the app run without depending on a real API.
/// The response shape matches the real API (snake_case fields, same endpoints).
class MockApiServer {
  static final _rng = Random();

  static Map<String, dynamic> _user = <String, dynamic>{
    'id': 'usr_001',
    'email': 'demo@peopledesk.app',
    'full_name': 'Demo User',
    'employee_id': 'emp_001',
    'role': 'employee',
  };

  static final List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[
    {
      'id': 'ntf_001',
      'title': 'Welcome to PeopleDesk',
      'body': 'Your account is ready. Clock in to start your day.',
      'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'is_read': false,
    },
    {
      'id': 'ntf_002',
      'title': 'Leave policy updated',
      'body': 'Annual leave carry-forward rules were updated this week.',
      'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      'is_read': true,
    },
  ];

  static final List<Map<String, dynamic>> _leaveRequests = <Map<String, dynamic>>[
    {
      'id': 'lv_001',
      'leave_type': 'Annual',
      'start_date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      'end_date': DateTime.now().subtract(const Duration(days: 13)).toIso8601String(),
      'status': 'approved',
    },
    {
      'id': 'lv_002',
      'leave_type': 'Sick',
      'start_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'end_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'status': 'pending',
    },
  ];

  /// Leave balance as flat object (matching real API format)
  static Map<String, dynamic> _leaveBalances() => <String, dynamic>{
        'employee_id': 'emp_001',
        'annual_total': 30.0,
        'annual_used': 18.0,
        'annual_remaining': 12.0,
        'sick_total': 10.0,
        'sick_used': 4.0,
        'casual_total': 5.0,
        'casual_remaining': 3.0,
      };

  static Map<String, dynamic> _todayAttendance = _defaultToday();
  static List<Map<String, dynamic>> _attendanceHistory = _seedHistory();

  static final List<Map<String, dynamic>> _payslips = <Map<String, dynamic>>[
    {
      'id': 'pay_2025_01',
      'fiche_paie_number': 'FP-2025-001',
      'period_end': DateTime(2025, 1, 31).toIso8601String(),
      'net_salary': 3125.45,
    },
    {
      'id': 'pay_2024_12',
      'fiche_paie_number': 'FP-2024-012',
      'period_end': DateTime(2024, 12, 31).toIso8601String(),
      'net_salary': 3052.10,
    },
  ];

  static final List<Map<String, dynamic>> _supportTickets = <Map<String, dynamic>>[
    {
      'id': 'tkt_001',
      'subject': 'Unable to update bank details',
      'status': 'open',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'replies': [
        {
          'id': 'r_001',
          'message': 'Hi! Can you share a screenshot of the error you see?',
          'created_at': DateTime.now().subtract(const Duration(days: 2, hours: 1)).toIso8601String(),
          'from_staff': true,
        },
      ],
    },
    {
      'id': 'tkt_002',
      'subject': 'Payslip for last month missing',
      'status': 'resolved',
      'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      'replies': [
        {
          'id': 'r_002',
          'message': 'We\'ve re-generated your payslip. Please check again.',
          'created_at': DateTime.now().subtract(const Duration(days: 11, hours: 20)).toIso8601String(),
          'from_staff': true,
        },
      ],
    },
  ];

  static Map<String, dynamic> _defaultToday() {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return <String, dynamic>{
      'date': dateOnly.toIso8601String(),
      'status': 'Not clocked in',
      'clock_in': null,
      'clock_out': null,
    };
  }

  static List<Map<String, dynamic>> _seedHistory() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> days = [];
    for (var i = 1; i <= 10; i++) {
      final d = now.subtract(Duration(days: i));
      final dateOnly = DateTime(d.year, d.month, d.day);
      final present = i % 4 != 0;
      days.add({
        'date': dateOnly.toIso8601String(),
        'status': present ? 'Present' : 'Absent',
        'clock_in': present ? DateTime(d.year, d.month, d.day, 9, 10 + (i % 12)).toIso8601String() : null,
        'clock_out': present ? DateTime(d.year, d.month, d.day, 18, 0 + (i % 20)).toIso8601String() : null,
      });
    }
    return days;
  }

  static String _newId(String prefix) => '${prefix}_${_rng.nextInt(899999) + 100000}';

  static Map<String, dynamic> handle(String method, String path, {Object? body}) {
    final normalized = _normalizePath(path);
    debugPrint('MockApiServer: $method $normalized');

    // Auth - login returns snake_case tokens
    if (method == 'POST' && normalized == '/auth/login') {
      final email = _readBodyMap(body)['email']?.toString();
      final password = _readBodyMap(body)['password']?.toString();
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        throw const MockApiException('Invalid credentials', statusCode: 400);
      }
      _user = <String, dynamic>{..._user, 'email': email, 'full_name': _user['full_name'] ?? 'Demo User'};
      return <String, dynamic>{
        'access_token': 'mock_access_token',
        'refresh_token': 'mock_refresh_token',
        'user': _user,
      };
    }

    // Auth profile endpoint (real API uses /auth/profile, not /me)
    if (method == 'GET' && normalized == '/auth/profile') return <String, dynamic>{'user': _user};

    // Attendance - real API uses /attendance/today/:employee_id
    final todayMatch = RegExp(r'^/attendance/today/(.+)$').firstMatch(normalized);
    if (method == 'GET' && todayMatch != null) {
      return <String, dynamic>{'data': _todayAttendance};
    }
    // Attendance history - API returns {attendances: [...]}
    if (method == 'GET' && normalized == '/attendance') {
      return <String, dynamic>{'attendances': _attendanceHistory};
    }

    if (method == 'POST' && normalized == '/attendance/clock-in') {
      final now = DateTime.now();
      if (_todayAttendance['clock_in'] == null) {
        _todayAttendance = <String, dynamic>{
          ..._todayAttendance,
          'status': 'Present',
          'clock_in': now.toIso8601String(),
        };
      }
      return <String, dynamic>{'ok': true};
    }

    if (method == 'POST' && normalized == '/attendance/clock-out') {
      final now = DateTime.now();
      if (_todayAttendance['clock_in'] != null) {
        _todayAttendance = <String, dynamic>{..._todayAttendance, 'clock_out': now.toIso8601String()};
      }
      return <String, dynamic>{'ok': true};
    }

    // Leave - real API uses /leaves/balance/:employee_id and /leaves
    final leaveBalanceMatch = RegExp(r'^/leaves/balance/(.+)$').firstMatch(normalized);
    if (method == 'GET' && leaveBalanceMatch != null) {
      // Return flat object matching real API format
      return _leaveBalances();
    }
    // Leave requests - API returns {leaves: [...]}
    if (method == 'GET' && normalized == '/leaves') {
      return <String, dynamic>{'leaves': _leaveRequests};
    }

    if (method == 'POST' && normalized == '/leaves') {
      final m = _readBodyMap(body);
      final type = (m['leave_type'] ?? m['type'] ?? 'Leave').toString();
      final start = DateTime.tryParse(m['start_date']?.toString() ?? m['start']?.toString() ?? '');
      final end = DateTime.tryParse(m['end_date']?.toString() ?? m['end']?.toString() ?? '');
      if (start == null || end == null) throw const MockApiException('Invalid dates', statusCode: 400);
      final req = <String, dynamic>{
        'id': _newId('lv'),
        'leave_type': type,
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'status': 'pending',
      };
      _leaveRequests.insert(0, req);
      return <String, dynamic>{'data': req};
    }

    final leaveDeleteMatch = RegExp(r'^/leaves/(.+)$').firstMatch(normalized);
    if (method == 'DELETE' && leaveDeleteMatch != null) {
      final id = leaveDeleteMatch.group(1)!;
      _leaveRequests.removeWhere((r) => r['id']?.toString() == id);
      return <String, dynamic>{'ok': true};
    }

    // Notifications - API returns {notifications: [...]} with is_read field
    if (method == 'GET' && normalized == '/notifications') {
      return <String, dynamic>{'notifications': _notifications};
    }

    if ((method == 'PUT' || method == 'POST') && normalized.startsWith('/notifications/') && normalized.endsWith('/read')) {
      final parts = normalized.split('/');
      if (parts.length >= 3) {
        final id = parts[2];
        final idx = _notifications.indexWhere((n) => n['id']?.toString() == id);
        if (idx != -1) _notifications[idx] = <String, dynamic>{..._notifications[idx], 'is_read': true, 'read': true};
      }
      return <String, dynamic>{'ok': true};
    }

    // Payroll - API returns {approved: [...]}
    if (method == 'GET' && normalized == '/payroll/approved') {
      return <String, dynamic>{'approved': _payslips};
    }

    final payslipMatch = RegExp(r'^/payroll/approved/(.+)$').firstMatch(normalized);
    if (method == 'GET' && payslipMatch != null) {
      final id = payslipMatch.group(1)!;
      final p = _payslips.cast<Map<String, dynamic>?>().firstWhere((e) => e?['id']?.toString() == id, orElse: () => null);
      if (p == null) throw const MockApiException('Payslip not found', statusCode: 404);
      final baseNet = (p['net_salary'] is num) ? (p['net_salary'] as num).toDouble() : 0.0;
      return <String, dynamic>{
        'data': {
          ...p,
          'earnings': [
            {'label': 'Basic', 'amount': (baseNet + 900).roundToDouble()},
            {'label': 'Allowance', 'amount': 320.00},
          ],
          'deductions': [
            {'label': 'Tax', 'amount': 240.00},
            {'label': 'Pension', 'amount': 110.00},
          ],
        },
      };
    }

    // Support - API returns {tickets: [...]}
    if (method == 'GET' && normalized == '/support/tickets') {
      final list = _supportTickets.map((t) => {...t}..remove('replies')).toList(growable: false);
      return <String, dynamic>{'tickets': list};
    }

    final ticketDetailMatch = RegExp(r'^/support/tickets/([^/]+)$').firstMatch(normalized);
    if (method == 'GET' && ticketDetailMatch != null) {
      final id = ticketDetailMatch.group(1)!;
      final t = _supportTickets.cast<Map<String, dynamic>?>().firstWhere((e) => e?['id']?.toString() == id, orElse: () => null);
      if (t == null) throw const MockApiException('Ticket not found', statusCode: 404);
      return <String, dynamic>{'data': t};
    }

    if (method == 'POST' && normalized == '/support/tickets') {
      final m = _readBodyMap(body);
      final subject = (m['subject'] ?? '').toString().trim();
      final message = (m['description'] ?? m['message'] ?? '').toString().trim();
      if (subject.isEmpty || message.isEmpty) throw const MockApiException('Subject and message required', statusCode: 400);
      final ticket = <String, dynamic>{
        'id': _newId('tkt'),
        'subject': subject,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
        'replies': [
          {
            'id': _newId('r'),
            'message': message,
            'created_at': DateTime.now().toIso8601String(),
            'from_staff': false,
          },
        ],
      };
      _supportTickets.insert(0, ticket);
      return <String, dynamic>{'data': ticket};
    }

    // Support reply endpoint (singular "reply" not "replies")
    final ticketReplyMatch = RegExp(r'^/support/tickets/([^/]+)/reply$').firstMatch(normalized);
    if (method == 'POST' && ticketReplyMatch != null) {
      final ticketId = ticketReplyMatch.group(1)!;
      final idx = _supportTickets.indexWhere((t) => t['id']?.toString() == ticketId);
      if (idx == -1) throw const MockApiException('Ticket not found', statusCode: 404);
      final msg = (_readBodyMap(body)['message'] ?? '').toString().trim();
      if (msg.isEmpty) throw const MockApiException('Message required', statusCode: 400);
      final ticket = _supportTickets[idx];
      final replies = (ticket['replies'] is List) ? (ticket['replies'] as List).whereType<Map>().toList() : <Map>[];
      replies.add({
        'id': _newId('r'),
        'message': msg,
        'created_at': DateTime.now().toIso8601String(),
        'from_staff': false,
      });
      _supportTickets[idx] = <String, dynamic>{...ticket, 'replies': replies};
      return <String, dynamic>{'ok': true};
    }

    // Also support old /replies endpoint for backwards compatibility
    if (method == 'POST' && normalized.contains('/support/tickets/') && normalized.endsWith('/replies')) {
      final parts = normalized.split('/');
      final ticketId = parts.length >= 4 ? parts[3] : null;
      if (ticketId == null) throw const MockApiException('Invalid ticket id', statusCode: 400);
      final idx = _supportTickets.indexWhere((t) => t['id']?.toString() == ticketId);
      if (idx == -1) throw const MockApiException('Ticket not found', statusCode: 404);
      final msg = (_readBodyMap(body)['message'] ?? '').toString().trim();
      if (msg.isEmpty) throw const MockApiException('Message required', statusCode: 400);
      final ticket = _supportTickets[idx];
      final replies = (ticket['replies'] is List) ? (ticket['replies'] as List).whereType<Map>().toList() : <Map>[];
      replies.add({
        'id': _newId('r'),
        'message': msg,
        'created_at': DateTime.now().toIso8601String(),
        'from_staff': false,
      });
      _supportTickets[idx] = <String, dynamic>{...ticket, 'replies': replies};
      return <String, dynamic>{'ok': true};
    }

    throw MockApiException('No mock handler for $method $normalized', statusCode: 404);
  }

  static String _normalizePath(String raw) {
    // ApiClient passes leading '/', keep it.
    if (!raw.startsWith('/')) return '/$raw';
    return raw;
  }

  static Map<String, dynamic> _readBodyMap(Object? body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }
}

class MockApiException implements Exception {
  final int? statusCode;
  final String message;
  const MockApiException(this.message, {this.statusCode});

  @override
  String toString() => 'MockApiException(statusCode: $statusCode, message: $message)';
}