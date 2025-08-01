import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Helper class for notification scheduling and timezone operations
class NotificationHelper {
  /// Initialize timezone data and set local timezone
  static Future<void> initializeTimezone() async {
    tz_data.initializeTimeZones();

    final String localTimeZone = await FlutterTimezone.getLocalTimezone();

    // Set the local timezone
    final location = tz.getLocation(localTimeZone);
    tz.setLocalLocation(location);
  }

  /// Schedule for a specific hour, minute, second (next occurrence)
  static tz.TZDateTime nextInstanceOf(int hour, int minute, int second) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      second,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedule X seconds from now (good for testing)
  static tz.TZDateTime secondsFromNow(int seconds) {
    return tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
  }

  /// Schedule X minutes from now
  static tz.TZDateTime minutesFromNow(int minutes) {
    return tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
  }

  /// Schedule X hours from now
  static tz.TZDateTime hoursFromNow(int hours) {
    return tz.TZDateTime.now(tz.local).add(Duration(hours: hours));
  }

  /// Schedule X days from now at specific time
  static tz.TZDateTime daysFromNow(int days, {int hour = 9, int minute = 0}) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + days,
      hour,
      minute,
    );
  }

  /// Convert a standard DateTime to TZDateTime
  static tz.TZDateTime fromDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Get next occurrence of a specific time on specific weekdays
  static tz.TZDateTime nextInstanceOfWeekday(
    int weekday, // 1-7 (Monday to Sunday)
    int hour,
    int minute, [
    int second = 0,
  ]) {
    tz.TZDateTime scheduledDate = nextInstanceOf(hour, minute, second);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get next occurrence for multiple weekdays
  static List<tz.TZDateTime> nextInstanceOfWeekdays(
    List<int> weekdays, // List of weekdays (1-7)
    int hour,
    int minute, [
    int second = 0,
  ]) {
    return weekdays
        .map((weekday) => nextInstanceOfWeekday(weekday, hour, minute, second))
        .toList();
  }

  /// Create a weekly recurring notification schedule
  static List<tz.TZDateTime> createWeeklySchedule(
    List<int> weekdays,
    int hour,
    int minute, {
    int weeksAhead = 4, // How many weeks to schedule ahead
  }) {
    final List<tz.TZDateTime> schedule = [];

    for (int week = 0; week < weeksAhead; week++) {
      for (int weekday in weekdays) {
        final baseDate = nextInstanceOfWeekday(weekday, hour, minute);
        final scheduledDate = baseDate.add(Duration(days: 7 * week));
        schedule.add(scheduledDate);
      }
    }

    return schedule;
  }

  /// Format TZDateTime for display
  static String formatScheduledTime(tz.TZDateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Check if a scheduled time is in the past
  static bool isInPast(tz.TZDateTime dateTime) {
    return dateTime.isBefore(tz.TZDateTime.now(tz.local));
  }

  /// Get time until scheduled notification
  static Duration timeUntilNotification(tz.TZDateTime scheduledTime) {
    final now = tz.TZDateTime.now(tz.local);
    return scheduledTime.difference(now);
  }
}
