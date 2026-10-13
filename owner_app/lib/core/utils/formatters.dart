import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String timeAgo(DateTime? date) {
    if (date == null) return 'No data';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM d, y').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('h:mm a').format(date);
  }

  static String formatDistance(num? km) {
    if (km == null) return '0.0 km';
    return '${km.toStringAsFixed(1)} km';
  }

  static String distance(num? km) => formatDistance(km);

  static String odometer(num? km) {
    if (km == null) return '0 km';
    return '${km.toStringAsFixed(0)} km';
  }

  static String durationMinutes(num? minutes) {
    if (minutes == null || minutes <= 0) return '0 min';
    final m = minutes.toInt();
    final hours = m ~/ 60;
    final mins = m % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '$mins min';
  }

  static String formatSpeed(num? speed) {
    if (speed == null) return '0 km/h';
    return '${speed.toInt()} km/h';
  }

  static String formatPercent(num? value) {
    if (value == null) return '0%';
    return '${value.toInt()}%';
  }
}
