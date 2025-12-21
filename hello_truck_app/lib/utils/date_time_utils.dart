import 'package:intl/intl.dart';

/// Utility functions for date and time formatting with IST (Indian Standard Time) support
class DateTimeUtils {
  // IST timezone offset is UTC+5:30
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  /// Converts a UTC DateTime to IST (Indian Standard Time)
  ///
  /// Example:
  /// ```dart
  /// final utcTime = DateTime.parse('2024-01-15T10:30:00Z');
  /// final istTime = DateTimeUtils.toIST(utcTime);
  /// // istTime will be 2024-01-15 16:00:00.000 (IST)
  /// ```
  static DateTime toIST(DateTime utcDateTime) {
    // If the datetime is already in local timezone, convert to UTC first
    if (!utcDateTime.isUtc) {
      utcDateTime = utcDateTime.toUtc();
    }
    return utcDateTime.add(_istOffset);
  }

  /// Formats a DateTime to IST and returns a formatted string
  ///
  /// Parameters:
  /// - [dateTime]: The DateTime to format (can be UTC or local)
  /// - [format]: Optional DateFormat pattern (defaults to 'MMM dd, yyyy • hh:mm a')
  ///
  /// Example:
  /// ```dart
  /// final formatted = DateTimeUtils.formatToIST(
  ///   DateTime.parse('2024-01-15T10:30:00Z'),
  ///   'dd/MM/yyyy HH:mm'
  /// );
  /// // Returns: "15/01/2024 16:00"
  /// ```
  static String formatToIST(DateTime dateTime, [String format = 'MMM dd, yyyy • hh:mm a']) {
    final istDateTime = toIST(dateTime);
    return DateFormat(format).format(istDateTime);
  }

  /// Formats a DateTime to IST with "IST" suffix
  ///
  /// Parameters:
  /// - [dateTime]: The DateTime to format (can be UTC or local)
  /// - [format]: Optional DateFormat pattern (defaults to 'MMM dd, yyyy • hh:mm a')
  ///
  /// Example:
  /// ```dart
  /// final formatted = DateTimeUtils.formatToISTWithLabel(
  ///   DateTime.parse('2024-01-15T10:30:00Z')
  /// );
  /// // Returns: "Jan 15, 2024 • 04:00 PM IST"
  /// ```
  static String formatToISTWithLabel(DateTime dateTime, [String format = 'MMM dd, yyyy • hh:mm a']) {
    return '${formatToIST(dateTime, format)} IST';
  }

  /// Formats a DateTime to a short date format in IST
  ///
  /// Example:
  /// ```dart
  /// final shortDate = DateTimeUtils.formatShortDateIST(DateTime.now());
  /// // Returns: "Jan 15, 2024"
  /// ```
  static String formatShortDateIST(DateTime dateTime) {
    return formatToIST(dateTime, 'MMM dd, yyyy');
  }

  /// Formats a DateTime to a short time format in IST
  ///
  /// Example:
  /// ```dart
  /// final shortTime = DateTimeUtils.formatShortTimeIST(DateTime.now());
  /// // Returns: "04:30 PM"
  /// ```
  static String formatShortTimeIST(DateTime dateTime) {
    return formatToIST(dateTime, 'hh:mm a');
  }

  /// Formats a DateTime to a full date-time format in IST
  ///
  /// Example:
  /// ```dart
  /// final fullDateTime = DateTimeUtils.formatFullDateTimeIST(DateTime.now());
  /// // Returns: "Monday, Jan 15, 2024 at 04:30 PM"
  /// ```
  static String formatFullDateTimeIST(DateTime dateTime) {
    return formatToIST(dateTime, 'EEEE, MMM dd, yyyy \'at\' hh:mm a');
  }

  /// Formats a DateTime to show relative time (e.g., "2 hours ago") or full date if older
  ///
  /// Parameters:
  /// - [dateTime]: The DateTime to format
  /// - [showIST]: Whether to show IST label (default: true)
  ///
  /// Example:
  /// ```dart
  /// final relative = DateTimeUtils.formatRelativeIST(
  ///   DateTime.now().subtract(Duration(hours: 2))
  /// );
  /// // Returns: "2 hours ago"
  ///
  /// final old = DateTimeUtils.formatRelativeIST(
  ///   DateTime.now().subtract(Duration(days: 5))
  /// );
  /// // Returns: "Jan 10, 2024 • 04:30 PM IST"
  /// ```
  static String formatRelativeIST(DateTime dateTime, {bool showIST = true}) {
    final istDateTime = toIST(dateTime);
    final now = toIST(DateTime.now().toUtc());
    final difference = now.difference(istDateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      // For older dates, show the full date
      return showIST
          ? formatToISTWithLabel(dateTime)
          : formatToIST(dateTime);
    }
  }

  /// Formats a DateTime for transaction/wallet logs (default format used in the app)
  ///
  /// Example:
  /// ```dart
  /// final logDate = DateTimeUtils.formatLogDateTime(DateTime.now());
  /// // Returns: "Jan 15, 2024 • 04:30 PM IST"
  /// ```
  static String formatLogDateTime(DateTime dateTime) {
    return formatToISTWithLabel(dateTime);
  }

  /// Formats a DateTime for compact display (date only)
  ///
  /// Example:
  /// ```dart
  /// final compactDate = DateTimeUtils.formatCompactDate(DateTime.now());
  /// // Returns: "15/01/2024"
  /// ```
  static String formatCompactDate(DateTime dateTime) {
    return formatToIST(dateTime, 'dd/MM/yyyy');
  }

  /// Formats a DateTime for compact display with time
  ///
  /// Example:
  /// ```dart
  /// final compact = DateTimeUtils.formatCompactDateTime(DateTime.now());
  /// // Returns: "15/01/24 04:30 PM"
  /// ```
  static String formatCompactDateTime(DateTime dateTime) {
    return formatToIST(dateTime, 'dd/MM/yy hh:mm a');
  }

  /// Checks if a DateTime is today (in IST)
  static bool isToday(DateTime dateTime) {
    final istDateTime = toIST(dateTime);
    final now = toIST(DateTime.now().toUtc());
    return istDateTime.year == now.year &&
        istDateTime.month == now.month &&
        istDateTime.day == now.day;
  }

  /// Checks if a DateTime is yesterday (in IST)
  static bool isYesterday(DateTime dateTime) {
    final istDateTime = toIST(dateTime);
    final yesterday = toIST(DateTime.now().toUtc()).subtract(const Duration(days: 1));
    return istDateTime.year == yesterday.year &&
        istDateTime.month == yesterday.month &&
        istDateTime.day == yesterday.day;
  }

  /// Formats a DateTime with "Today", "Yesterday", or date
  ///
  /// Example:
  /// ```dart
  /// final smart = DateTimeUtils.formatSmartDate(DateTime.now());
  /// // Returns: "Today, 04:30 PM IST"
  ///
  /// final yesterday = DateTimeUtils.formatSmartDate(
  ///   DateTime.now().subtract(Duration(days: 1))
  /// );
  /// // Returns: "Yesterday, 04:30 PM IST"
  /// ```
  static String formatSmartDate(DateTime dateTime) {
    if (isToday(dateTime)) {
      return 'Today, ${formatShortTimeIST(dateTime)} IST';
    } else if (isYesterday(dateTime)) {
      return 'Yesterday, ${formatShortTimeIST(dateTime)} IST';
    } else {
      return formatToISTWithLabel(dateTime);
    }
  }

  /// Parses an ISO 8601 string and converts to IST DateTime
  ///
  /// Example:
  /// ```dart
  /// final istDateTime = DateTimeUtils.parseToIST('2024-01-15T10:30:00Z');
  /// ```
  static DateTime parseToIST(String isoString) {
    final utcDateTime = DateTime.parse(isoString);
    return toIST(utcDateTime);
  }

  /// Gets the current time in IST
  static DateTime nowIST() {
    return toIST(DateTime.now().toUtc());
  }

  /// Formats a duration in a human-readable format
  ///
  /// Example:
  /// ```dart
  /// final duration = DateTimeUtils.formatDuration(Duration(hours: 2, minutes: 30));
  /// // Returns: "2h 30m"
  /// ```
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
