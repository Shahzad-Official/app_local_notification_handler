import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;

/// Global instance of the Flutter Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Channel configuration for different notification types
class NotificationChannelConfig {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final Importance importance;
  final Priority priority;

  const NotificationChannelConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.importance = Importance.max,
    this.priority = Priority.high,
  });
}

/// Default channel configurations
class DefaultChannels {
  static const NotificationChannelConfig simple = NotificationChannelConfig(
    channelId: 'simple_channel_id',
    channelName: 'Simple Channel',
    channelDescription: 'Channel for simple notifications',
  );

  static const NotificationChannelConfig scheduled = NotificationChannelConfig(
    channelId: 'scheduled_channel_id',
    channelName: 'Scheduled Channel',
    channelDescription: 'Channel for scheduled notifications',
  );

  static const NotificationChannelConfig action = NotificationChannelConfig(
    channelId: 'action_channel_id',
    channelName: 'Action Channel',
    channelDescription: 'Channel with buttons',
  );

  static const NotificationChannelConfig progress = NotificationChannelConfig(
    channelId: 'progress_channel',
    channelName: 'Progress Channel',
    channelDescription: 'Channel for progress notifications',
    importance: Importance.low,
    priority: Priority.low,
  );

  static const NotificationChannelConfig customSound =
      NotificationChannelConfig(
        channelId: 'custom_sound_channel',
        channelName: 'Custom Sound Channel',
        channelDescription: 'Channel for notifications with custom sounds',
      );
}

/// Configuration class for notification settings
class NotificationConfig {
  final String androidIcon;
  final List<DarwinNotificationCategory>? iosCategories;
  final void Function(NotificationResponse)? onNotificationTap;
  final void Function(NotificationResponse)? onBackgroundNotificationTap;
  final NotificationChannelConfig? defaultSimpleChannel;
  final NotificationChannelConfig? defaultScheduledChannel;
  final NotificationChannelConfig? defaultActionChannel;
  final NotificationChannelConfig? defaultProgressChannel;
  final NotificationChannelConfig? defaultCustomSoundChannel;

  // Simplified channel ID setup
  final String? defaultChannelId;
  final String? defaultChannelName;
  final String? defaultChannelDescription;
  final Importance defaultImportance;
  final Priority defaultPriority;

  const NotificationConfig({
    this.androidIcon = '@mipmap/ic_launcher',
    this.iosCategories,
    this.onNotificationTap,
    this.onBackgroundNotificationTap,
    this.defaultSimpleChannel,
    this.defaultScheduledChannel,
    this.defaultActionChannel,
    this.defaultProgressChannel,
    this.defaultCustomSoundChannel,
    // Simplified channel setup
    this.defaultChannelId,
    this.defaultChannelName,
    this.defaultChannelDescription,
    this.defaultImportance = Importance.high,
    this.defaultPriority = Priority.high,
  });

  /// Create a simple channel config from the default settings
  NotificationChannelConfig get simpleChannelFromDefaults =>
      NotificationChannelConfig(
        channelId: defaultChannelId ?? 'app_default_channel',
        channelName: defaultChannelName ?? 'App Notifications',
        channelDescription:
            defaultChannelDescription ?? 'Default notification channel',
        importance: defaultImportance,
        priority: defaultPriority,
      );
}

/// Main notification handler class
class AppNotificationHandler {
  static AppNotificationHandler? _instance;
  static AppNotificationHandler get instance =>
      _instance ??= AppNotificationHandler._();

  AppNotificationHandler._();

  GlobalKey<NavigatorState>? _navigatorKey;
  NotificationChannelConfig? _simpleChannel;
  NotificationChannelConfig? _scheduledChannel;
  NotificationChannelConfig? _actionChannel;
  NotificationChannelConfig? _progressChannel;
  NotificationChannelConfig? _customSoundChannel;

  /// Get the configured simple channel or default
  NotificationChannelConfig get simpleChannel =>
      _simpleChannel ?? DefaultChannels.simple;

  /// Get the configured scheduled channel or default
  NotificationChannelConfig get scheduledChannel =>
      _scheduledChannel ?? DefaultChannels.scheduled;

  /// Get the configured action channel or default
  NotificationChannelConfig get actionChannel =>
      _actionChannel ?? DefaultChannels.action;

  /// Get the configured progress channel or default
  NotificationChannelConfig get progressChannel =>
      _progressChannel ?? DefaultChannels.progress;

  /// Get the configured custom sound channel or default
  NotificationChannelConfig get customSoundChannel =>
      _customSoundChannel ?? DefaultChannels.customSound;

  /// Initialize the notification handler
  Future<void> initialize({
    required NotificationConfig config,
    GlobalKey<NavigatorState>? navigatorKey,
    bool requestPermissionsOnInit = true,
  }) async {
    _navigatorKey = navigatorKey;

    // Store channel configurations - prioritize explicit channel configs,
    // fallback to simplified default settings
    _simpleChannel =
        config.defaultSimpleChannel ?? config.simpleChannelFromDefaults;
    _scheduledChannel =
        config.defaultScheduledChannel ??
        NotificationChannelConfig(
          channelId: '${config.defaultChannelId ?? 'app_default'}_scheduled',
          channelName: '${config.defaultChannelName ?? 'App'} Scheduled',
          channelDescription:
              'Scheduled ${config.defaultChannelDescription ?? 'notifications'}',
          importance: config.defaultImportance,
          priority: config.defaultPriority,
        );
    _actionChannel =
        config.defaultActionChannel ??
        NotificationChannelConfig(
          channelId: '${config.defaultChannelId ?? 'app_default'}_actions',
          channelName: '${config.defaultChannelName ?? 'App'} Actions',
          channelDescription:
              'Action ${config.defaultChannelDescription ?? 'notifications'}',
          importance: config.defaultImportance,
          priority: config.defaultPriority,
        );
    _progressChannel =
        config.defaultProgressChannel ??
        NotificationChannelConfig(
          channelId: '${config.defaultChannelId ?? 'app_default'}_progress',
          channelName: '${config.defaultChannelName ?? 'App'} Progress',
          channelDescription:
              'Progress ${config.defaultChannelDescription ?? 'notifications'}',
          importance: Importance.low,
          priority: Priority.low,
        );
    _customSoundChannel =
        config.defaultCustomSoundChannel ??
        NotificationChannelConfig(
          channelId: '${config.defaultChannelId ?? 'app_default'}_sound',
          channelName: '${config.defaultChannelName ?? 'App'} Custom Sound',
          channelDescription:
              'Custom sound ${config.defaultChannelDescription ?? 'notifications'}',
          importance: config.defaultImportance,
          priority: config.defaultPriority,
        );

    // Initialize time zones for scheduling
    tz.initializeTimeZones();

    // Android initialization
    final androidInit = AndroidInitializationSettings(config.androidIcon);

    // iOS initialization with categories - request permissions immediately
    final iosInit = DarwinInitializationSettings(
      notificationCategories: config.iosCategories ?? _defaultIOSCategories,
      requestAlertPermission: requestPermissionsOnInit,
      requestBadgePermission: requestPermissionsOnInit,
      requestSoundPermission: requestPermissionsOnInit,
    );

    // Combine both platforms
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // Initialize plugin with handlers
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          config.onNotificationTap ?? _defaultNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          config.onBackgroundNotificationTap ?? notificationTapBackground,
    );

    // Request permissions automatically on initialization
    if (requestPermissionsOnInit) {
      await _requestInitialPermissions();
    }
  }

  /// Default iOS notification categories
  List<DarwinNotificationCategory> get _defaultIOSCategories => [
    DarwinNotificationCategory(
      'habit_category',
      options: const {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
    ),
  ];

  /// Default notification tap handler
  void _defaultNotificationTap(NotificationResponse response) {
    // Override this in your app implementation
  }

  /// Request initial permissions during initialization
  Future<bool> _requestInitialPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API level 33+), request notification permission
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        return granted ?? false;
      }
      return true; // For older Android versions, permissions are granted by default
    } else if (Platform.isIOS) {
      // For iOS, request permissions explicitly
      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  /// Check notification permissions (simplified since permissions are requested on init)
  Future<bool> checkNotificationPermission({bool showDialog = false}) async {
    bool? isAllowed;

    if (Platform.isAndroid) {
      isAllowed = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    } else if (Platform.isIOS) {
      // For iOS, we can check the current permission status
      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        isAllowed = await iosImplementation.requestPermissions(
          alert: false, // Don't show dialog, just check status
          badge: false,
          sound: false,
        );
      }
    }

    // Only show dialog if explicitly requested and permission is denied
    if (isAllowed == false &&
        showDialog &&
        _navigatorKey?.currentContext != null) {
      _showPermissionDialog();
    }

    return isAllowed ?? false;
  }

  /// Get current notification permission status without requesting
  Future<bool> getPermissionStatus() async {
    if (Platform.isAndroid) {
      final isAllowed = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return isAllowed ?? false;
    } else if (Platform.isIOS) {
      // For iOS, checking permission status requires a permission request
      // So we'll use a different approach - check if we can schedule notifications
      return true; // Assume permissions are granted since we requested them on init
    }
    return false;
  }

  /// Show permission dialog to user
  void _showPermissionDialog() {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Notification Permission Required'),
        content: Text(
          'This app requires notification permissions to function properly.',
        ),
        actions: [
          TextButton(
            child: Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Required for background isolate callbacks (for action buttons)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Handle background notification taps here
}
