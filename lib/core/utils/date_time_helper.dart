import 'package:intl/intl.dart';

class DateTimeHelper {
  DateTimeHelper._();

  /// Format DateTime to string
  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Format DateTime with time
  static String formatDateTime(DateTime date, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  /// Parse string to DateTime
  static DateTime? parseDate(String dateString, {String pattern = 'dd/MM/yyyy'}) {
    try {
      return DateFormat(pattern).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get time ago string (e.g., "2 hours ago")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

