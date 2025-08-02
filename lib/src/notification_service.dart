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
    NotificationChannelConfig? customChannel,
  }) async {
    final channel =
        customChannel ?? AppNotificationHandler.instance.simpleChannel;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channel.channelId,
          channel.channelName,
          channelDescription: channel.channelDescription,
          importance: channel.importance,
          priority: channel.priority,
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

  /// Schedule a notification for a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    bool repeatDaily = false,
    String? payload,
    NotificationChannelConfig? customChannel,
  }) async {
    final channel =
        customChannel ?? AppNotificationHandler.instance.scheduledChannel;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.channelId,
          channel.channelName,
          channelDescription: channel.channelDescription,
          importance: channel.importance,
          priority: channel.priority,
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
    NotificationChannelConfig? customChannel,
  }) async {
    final channel =
        customChannel ?? AppNotificationHandler.instance.actionChannel;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channel.channelId,
          channel.channelName,
          channelDescription: channel.channelDescription,
          importance: channel.importance,
          priority: channel.priority,
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
    NotificationChannelConfig? customChannel,
  }) async {
    final channel =
        customChannel ?? AppNotificationHandler.instance.customSoundChannel;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channel.channelId,
          channel.channelName,
          channelDescription: channel.channelDescription,
          importance: channel.importance,
          priority: channel.priority,
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
    NotificationChannelConfig? customChannel,
  }) async {
    final channel =
        customChannel ?? AppNotificationHandler.instance.progressChannel;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channel.channelId,
          channel.channelName,
          channelDescription: channel.channelDescription,
          importance: channel.importance,
          priority: channel.priority,
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
