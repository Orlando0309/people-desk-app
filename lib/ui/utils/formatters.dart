import 'package:intl/intl.dart';

class AppFormatters {
  static final DateFormat _date = DateFormat.yMMMd();
  static final DateFormat _monthYear = DateFormat.yMMM();
  static final DateFormat _time = DateFormat.Hm();

  static String date(DateTime d) => _date.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String time(DateTime d) => _time.format(d);

  static String currency(num amount, {String symbol = '€'}) {
    final f = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return f.format(amount);
  }
}

// -----------------------------------------------------------------------------
// Backwards-compatible top-level helpers (used throughout the UI).
// -----------------------------------------------------------------------------

String formatDate(DateTime d) => AppFormatters.date(d);

String formatMonthYear(DateTime d) => AppFormatters.monthYear(d);

String formatMoney(num amount) => AppFormatters.currency(amount);

String formatTime(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  return AppFormatters.time(dt);
}

String formatRelativeTime(DateTime dt) {
  // Lightweight fallback (avoids extra deps).
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return AppFormatters.date(dt);
}
