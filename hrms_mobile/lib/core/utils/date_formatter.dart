import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatTime(dynamic val) {
    if (val == null) return '--:--';
    try {
      final dt = val is DateTime ? val : DateTime.parse(val.toString());
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return val.toString();
    }
  }

  static String formatDate(dynamic val) {
    if (val == null) return '--';
    try {
      final dt = val is DateTime ? val : DateTime.parse(val.toString());
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return val.toString();
    }
  }

  static String formatFullDate(DateTime dt) {
    return DateFormat('EEEE, MMM dd, yyyy').format(dt);
  }

  static String formatMinutesToHours(int? minutes) {
    if (minutes == null || minutes <= 0) return '0h';
    final hours = (minutes / 60).toStringAsFixed(1);
    return '${hours}h';
  }
}
