import 'dart:math';

import 'package:flutter/foundation.dart';

/// Lightweight in-memory mock backend.
///
/// This lets the app run in Dreamflow without depending on a localhost API.
/// The goal is to keep the response *shape* similar to the real API so we can
/// swap back later with minimal changes.
class MockApiServer {
  static final _rng = Random();

  static Map<String, dynamic> _user = <String, dynamic>{
    'id': 'usr_001',
    'email': 'demo@peopledesk.app',
    'name': 'Demo User',
  };

  static final List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[
    {
      'id': 'ntf_001',
      'title': 'Welcome to PeopleDesk',
      'body': 'Your account is ready. Clock in to start your day.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'read': false,
    },
    {
      'id': 'ntf_002',
      'title': 'Leave policy updated',
      'body': 'Annual leave carry-forward rules were updated this week.',
      'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      'read': true,
    },
  ];

  static final List<Map<String, dynamic>> _leaveRequests = <Map<String, dynamic>>[
    {
      'id': 'lv_001',
      'type': 'Annual',
      'start': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      'end': DateTime.now().subtract(const Duration(days: 13)).toIso8601String(),
      'status': 'approved',
    },
    {
      'id': 'lv_002',
      'type': 'Sick',
      'start': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'end': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'status': 'pending',
    },
  ];

  static List<Map<String, dynamic>> _leaveBalances() => <Map<String, dynamic>>[
        {'label': 'Annual', 'remaining': 12.0, 'total': 18.0},
        {'label': 'Sick', 'remaining': 6.0, 'total': 10.0},
        {'label': 'Casual', 'remaining': 3.0, 'total': 5.0},
      ];

  static Map<String, dynamic> _todayAttendance = _defaultToday();
  static List<Map<String, dynamic>> _attendanceHistory = _seedHistory();

  static final List<Map<String, dynamic>> _payslips = <Map<String, dynamic>>[
    {
      'id': 'pay_2025_01',
      'label': 'January 2025',
      'period': DateTime(2025, 1, 31).toIso8601String(),
      'net': 3125.45,
    },
    {
      'id': 'pay_2024_12',
      'label': 'December 2024',
      'period': DateTime(2024, 12, 31).toIso8601String(),
      'net': 3052.10,
    },
  ];

  static final List<Map<String, dynamic>> _supportTickets = <Map<String, dynamic>>[
    {
      'id': 'tkt_001',
      'subject': 'Unable to update bank details',
      'status': 'open',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'replies': [
        {
          'id': 'r_001',
          'message': 'Hi! Can you share a screenshot of the error you see?',
          'createdAt': DateTime.now().subtract(const Duration(days: 2, hours: 1)).toIso8601String(),
          'fromStaff': true,
        },
      ],
    },
    {
      'id': 'tkt_002',
      'subject': 'Payslip for last month missing',
      'status': 'resolved',
      'createdAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      'replies': [
        {
          'id': 'r_002',
          'message': 'We’ve re-generated your payslip. Please check again.',
          'createdAt': DateTime.now().subtract(const Duration(days: 11, hours: 20)).toIso8601String(),
          'fromStaff': true,
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
      'clockInAt': null,
      'clockOutAt': null,
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
        'clockInAt': present ? DateTime(d.year, d.month, d.day, 9, 10 + (i % 12)).toIso8601String() : null,
        'clockOutAt': present ? DateTime(d.year, d.month, d.day, 18, 0 + (i % 20)).toIso8601String() : null,
      });
    }
    return days;
  }

  static String _newId(String prefix) => '${prefix}_${_rng.nextInt(899999) + 100000}';

  static Map<String, dynamic> handle(String method, String path, {Object? body}) {
    final normalized = _normalizePath(path);
    debugPrint('MockApiServer: $method $normalized');

    // Auth
    if (method == 'POST' && normalized == '/auth/login') {
      final email = _readBodyMap(body)['email']?.toString();
      final password = _readBodyMap(body)['password']?.toString();
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        throw const MockApiException('Invalid credentials', statusCode: 400);
      }
      _user = <String, dynamic>{..._user, 'email': email, 'name': _user['name'] ?? 'Demo User'};
      return <String, dynamic>{
        'accessToken': 'mock_access_token',
        'refreshToken': 'mock_refresh_token',
        'user': _user,
      };
    }

    if (method == 'GET' && normalized == '/me') return <String, dynamic>{'user': _user};

    // Attendance
    if (method == 'GET' && normalized == '/attendance/today') return <String, dynamic>{'data': _todayAttendance};
    if (method == 'GET' && normalized == '/attendance') return <String, dynamic>{'data': _attendanceHistory};

    if (method == 'POST' && normalized == '/attendance/clock-in') {
      final now = DateTime.now();
      if (_todayAttendance['clockInAt'] == null) {
        _todayAttendance = <String, dynamic>{
          ..._todayAttendance,
          'status': 'Present',
          'clockInAt': now.toIso8601String(),
        };
      }
      return <String, dynamic>{'ok': true};
    }

    if (method == 'POST' && normalized == '/attendance/clock-out') {
      final now = DateTime.now();
      if (_todayAttendance['clockInAt'] != null) {
        _todayAttendance = <String, dynamic>{..._todayAttendance, 'clockOutAt': now.toIso8601String()};
      }
      return <String, dynamic>{'ok': true};
    }

    // Leave
    if (method == 'GET' && normalized == '/leave/balances') return <String, dynamic>{'data': _leaveBalances()};
    if (method == 'GET' && normalized == '/leave/requests') return <String, dynamic>{'data': _leaveRequests};

    if (method == 'POST' && normalized == '/leave/requests') {
      final m = _readBodyMap(body);
      final type = (m['type'] ?? 'Leave').toString();
      final start = DateTime.tryParse(m['start']?.toString() ?? '');
      final end = DateTime.tryParse(m['end']?.toString() ?? '');
      if (start == null || end == null) throw const MockApiException('Invalid dates', statusCode: 400);
      final req = <String, dynamic>{
        'id': _newId('lv'),
        'type': type,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'status': 'pending',
      };
      _leaveRequests.insert(0, req);
      return <String, dynamic>{'data': req};
    }

    if (method == 'DELETE' && normalized.startsWith('/leave/requests/')) {
      final id = normalized.split('/').last;
      _leaveRequests.removeWhere((r) => r['id']?.toString() == id);
      return <String, dynamic>{'ok': true};
    }

    // Notifications
    if (method == 'GET' && normalized == '/notifications') return <String, dynamic>{'data': _notifications};

    if (method == 'POST' && normalized.startsWith('/notifications/') && normalized.endsWith('/read')) {
      final parts = normalized.split('/');
      if (parts.length >= 3) {
        final id = parts[2];
        final idx = _notifications.indexWhere((n) => n['id']?.toString() == id);
        if (idx != -1) _notifications[idx] = <String, dynamic>{..._notifications[idx], 'read': true};
      }
      return <String, dynamic>{'ok': true};
    }

    // Payroll
    if (method == 'GET' && normalized == '/payslips') return <String, dynamic>{'data': _payslips};
    if (method == 'GET' && normalized.startsWith('/payslips/')) {
      final id = normalized.split('/').last;
      final p = _payslips.cast<Map<String, dynamic>?>().firstWhere((e) => e?['id']?.toString() == id, orElse: () => null);
      if (p == null) throw const MockApiException('Payslip not found', statusCode: 404);
      final baseNet = (p['net'] is num) ? (p['net'] as num).toDouble() : 0.0;
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

    // Support
    if (method == 'GET' && normalized == '/support/tickets') {
      final list = _supportTickets.map((t) => {...t}..remove('replies')).toList(growable: false);
      return <String, dynamic>{'data': list};
    }
    if (method == 'GET' && normalized.startsWith('/support/tickets/')) {
      final id = normalized.split('/').last;
      final t = _supportTickets.cast<Map<String, dynamic>?>().firstWhere((e) => e?['id']?.toString() == id, orElse: () => null);
      if (t == null) throw const MockApiException('Ticket not found', statusCode: 404);
      return <String, dynamic>{'data': t};
    }
    if (method == 'POST' && normalized == '/support/tickets') {
      final m = _readBodyMap(body);
      final subject = (m['subject'] ?? '').toString().trim();
      final message = (m['message'] ?? '').toString().trim();
      if (subject.isEmpty || message.isEmpty) throw const MockApiException('Subject and message required', statusCode: 400);
      final ticket = <String, dynamic>{
        'id': _newId('tkt'),
        'subject': subject,
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
        'replies': [
          {
            'id': _newId('r'),
            'message': message,
            'createdAt': DateTime.now().toIso8601String(),
            'fromStaff': false,
          },
        ],
      };
      _supportTickets.insert(0, ticket);
      return <String, dynamic>{'data': ticket};
    }
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
        'createdAt': DateTime.now().toIso8601String(),
        'fromStaff': false,
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
