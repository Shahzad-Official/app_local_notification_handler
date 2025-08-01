import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_config.dart';

/// Service class for handling different types of notifications
class NotificationService {
  /// Show basic instant notification
  static Future<void> showSimpleNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String channelId = 'simple_channel_id',
    String channelName = 'Simple Channel',
    String channelDescription = 'Channel for simple notifications',
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'simple_channel_id',
          'Simple Channel',
          channelDescription: 'Channel for simple notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Schedule a notification for a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    bool repeatDaily = false,
    String? payload,
    String channelId = 'scheduled_channel_id',
    String channelName = 'Scheduled Channel',
    String channelDescription = 'Channel for scheduled notifications',
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      payload: payload,
    );
  }

  /// Show actionable notification with buttons
  static Future<void> showActionNotification({
    int id = 1,
    required String title,
    required String body,
    List<AndroidNotificationAction>? actions,
    String? payload,
    String channelId = 'action_channel_id',
    String channelName = 'Action Channel',
    String channelDescription = 'Channel with buttons',
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          actions:
              actions ??
              [
                const AndroidNotificationAction('ACCEPT_ACTION', 'Accept'),
                const AndroidNotificationAction('DECLINE_ACTION', 'Decline'),
              ],
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Show notification with custom sound
  static Future<void> showNotificationWithCustomSound({
    int id = 0,
    required String title,
    required String body,
    required String soundFile,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'custom_sound_channel',
          'Custom Sound Channel',
          channelDescription: 'Channel for notifications with custom sounds',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundFile),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Show progress notification (Android only)
  static Future<void> showProgressNotification({
    int id = 0,
    required String title,
    required String body,
    int maxProgress = 100,
    int currentProgress = 0,
    bool indeterminate = false,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'progress_channel',
          'Progress Channel',
          channelDescription: 'Channel for progress notifications',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: maxProgress,
          progress: currentProgress,
          indeterminate: indeterminate,
          ongoing: true,
          autoCancel: false,
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
