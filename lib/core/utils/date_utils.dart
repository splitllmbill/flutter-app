import 'package:intl/intl.dart';

/// Date formatting utilities ported from React State.tsx.
class AppDateUtils {
  AppDateUtils._();

  /// Format date as "01 Jan 2024"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date string as "01 Jan 2024"
  static String formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return formatDate(date);
    } catch (_) {
      return '--';
    }
  }

  /// Format date for transaction display: "01 Jan\n2024"
  static String formatDateForTransaction(DateTime date) {
    final day = date.day;
    final month = DateFormat('MMM').format(date);
    final year = date.year;
    return '$day $month\n$year';
  }

  /// Format date for transaction from string
  static String formatDateStringForTransaction(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return formatDateForTransaction(date);
    } catch (_) {
      return '--';
    }
  }

  /// Get relative time (e.g., "2 hours ago", "yesterday")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
