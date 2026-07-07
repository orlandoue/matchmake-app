import 'package:intl/intl.dart';

class DateHelper {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDisplayFormat = DateFormat('M/d/yyyy');

  // Convert string date to DateTime
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        return _dateFormat.parse(dateString);
      } catch (e) {
        return null;
      }
    }
  }

  // Format DateTime to display string
  static String formatForDisplay(DateTime? date) {
    if (date == null) return 'N/A';
    return _displayFormat.format(date);
  }

  // Format DateTime to short display string
  static String formatForShortDisplay(DateTime? date) {
    if (date == null) return 'N/A';
    return _shortDisplayFormat.format(date);
  }

  // Format DateTime to database string
  static String formatForDatabase(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  // Check if date is expired
  static bool isExpired(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  // Check if date is expiring soon (within 30 days)
  static bool isExpiringSoon(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(Duration(days: 30));
    return date.isAfter(now) && date.isBefore(thirtyDaysFromNow);
  }

  // Get days until expiry
  static int daysUntilExpiry(DateTime? date) {
    if (date == null) return -1;
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  // Get expiry status
  static String getExpiryStatus(DateTime? date) {
    if (date == null) return 'Unknown';

    final days = daysUntilExpiry(date);

    if (days < 0) {
      return 'Expired';
    } else if (days <= 30) {
      return 'Expiring Soon';
    } else {
      return 'Valid';
    }
  }
}
