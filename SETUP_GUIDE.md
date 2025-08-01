# Complete Setup Guide for App Notification Handler

This guide provides comprehensive instructions for setting up local notifications in your Flutter app using the `app_notification_handler` package.

## Quick Start

### 1. Add Dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  app_notification_handler:
    path: ../packages/app_notification_handler
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Platform Setup

Choose your platform for detailed setup:

- **[Android Setup Guide](./ANDROID_SETUP.md)** - Complete Android configuration
- **[iOS Setup Guide](./IOS_SETUP.md)** - Complete iOS configuration

## Basic Implementation

### Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:app_notification_handler/app_notification_handler.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone support
  await NotificationHelper.initializeTimezone();

  // Initialize notification handler
  await AppNotificationHandler.instance.initialize(
    config: NotificationConfig(
      androidIcon: '@mipmap/ic_launcher',
      onNotificationTap: _onNotificationTap,
      onBackgroundNotificationTap: _onBackgroundNotificationTap,
    ),
    navigatorKey: navigatorKey,
  );

  runApp(MyApp());
}

void _onNotificationTap(NotificationResponse response) {
  print('Foreground notification tapped: ${response.payload}');
  // Handle navigation or actions
  _handleNotificationPayload(response.payload);
}

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  print('Background notification tapped: ${response.payload}');
  // Handle background notification taps
  _handleNotificationPayload(response.payload);
}

void _handleNotificationPayload(String? payload) {
  if (payload == null) return;

  // Navigate based on payload
  switch (payload) {
    case 'home':
      navigatorKey.currentState?.pushNamed('/home');
      break;
    case 'profile':
      navigatorKey.currentState?.pushNamed('/profile');
      break;
    default:
      // Handle unknown payload
      break;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      navigatorKey: navigatorKey,
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
```

## Core Features

### 1. Simple Notifications

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

// Show immediate notification
await NotificationService.showSimpleNotification(
  title: 'Hello!',
  body: 'This is a simple notification',
  payload: 'simple_payload',
);
```

### 2. Scheduled Notifications

```dart
// Schedule for tomorrow at 9 AM
final scheduledTime = NotificationHelper.nextInstanceOf(9, 0, 0);

await NotificationService.scheduleNotification(
  id: 1,
  title: 'Good Morning!',
  body: 'Time to start your day',
  scheduledTime: scheduledTime,
  repeatDaily: true,
  payload: 'morning_reminder',
);
```

### 3. Weekly Recurring Notifications

```dart
// Schedule for Monday, Wednesday, Friday at 2 PM
final weeklyTimes = NotificationHelper.createWeeklySchedule(
  [1, 3, 5], // Days of week (1=Monday, 7=Sunday)
  14, // Hour (24-hour format)
  0,  // Minute
);

for (int i = 0; i < weeklyTimes.length; i++) {
  await NotificationService.scheduleNotification(
    id: 100 + i,
    title: 'Weekly Reminder',
    body: 'Time for your weekly task!',
    scheduledTime: weeklyTimes[i],
    repeatDaily: false,
  );
}
```

### 4. Actionable Notifications

```dart
await NotificationService.showActionNotification(
  title: 'Task Complete?',
  body: 'Did you finish your morning routine?',
  actions: [
    const AndroidNotificationAction('YES', 'Yes, Done!'),
    const AndroidNotificationAction('NO', 'Not Yet'),
    const AndroidNotificationAction('SNOOZE', 'Snooze 10min'),
  ],
  payload: 'task_check',
);
```

## Notification Helpers

### Time-based Scheduling

```dart
// 5 minutes from now
final fiveMinutes = NotificationHelper.minutesFromNow(5);

// Next occurrence of specific time (e.g., next 3 PM)
final nextThreePM = NotificationHelper.nextInstanceOf(15, 0, 0);

// Next Monday at 9 AM
final nextMonday = NotificationHelper.nextInstanceOfWeekday(1, 9, 0);

// Tomorrow at same time
final tomorrow = NotificationHelper.tomorrowAt(9, 30);
```

### Permission Management

```dart
// Check if notifications are enabled
final hasPermission = await AppNotificationHandler.instance.checkNotificationPermission();

if (!hasPermission) {
  // Package will automatically show permission dialog
  print('User needs to enable notifications');
}
```

### Notification Management

```dart
// Get all pending notifications
final pending = await NotificationService.getPendingNotifications();
print('Pending notifications: ${pending.length}');

// Cancel specific notification
await NotificationService.cancelNotification(1);

// Cancel all notifications
await NotificationService.cancelAllNotifications();
```

## Platform-Specific Features

### Android Only

```dart
// Progress notification
await NotificationService.showProgressNotification(
  title: 'Downloading...',
  body: 'Download in progress',
  maxProgress: 100,
  currentProgress: 45,
);

// Custom sound
await NotificationService.showNotificationWithCustomSound(
  title: 'Custom Sound',
  body: 'Android notification with custom sound',
  soundFile: 'notification_sound', // .mp3 file in res/raw/
);
```

### iOS Only

```dart
// iOS notification with subtitle and badge
const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  subtitle: 'Subtitle text',
  badgeNumber: 1,
  categoryIdentifier: 'task_category',
  threadIdentifier: 'task_thread',
);

const NotificationDetails platformDetails = NotificationDetails(
  iOS: iosDetails,
);

await flutterLocalNotificationsPlugin.show(
  0,
  'iOS Notification',
  'With iOS-specific features',
  platformDetails,
);
```

## Error Handling

```dart
try {
  await NotificationService.showSimpleNotification(
    title: 'Test',
    body: 'Testing notification',
  );
} catch (e) {
  print('Notification error: $e');
  // Handle error (show user-friendly message, log, etc.)
}
```

## Best Practices

### 1. Permission Timing

- Request permissions when users need notifications
- Explain why notifications are useful
- Don't spam permission requests

### 2. Notification Content

- Keep titles concise and descriptive
- Use actionable body text
- Include relevant payload for navigation

### 3. Scheduling

- Consider user's timezone
- Avoid scheduling too many notifications
- Provide easy cancellation options

### 4. Testing

- Test on both platforms
- Test different Android versions
- Test with app in foreground/background/terminated states
- Test permission denied scenarios

## Troubleshooting

### Common Issues

1. **Notifications not showing**

   - Check platform setup guides
   - Verify permissions are granted
   - Check device notification settings

2. **Scheduled notifications not firing**

   - Ensure timezone is initialized
   - Check battery optimization settings (Android)
   - Verify background app refresh (iOS)

3. **Custom sounds not playing**

   - Verify sound file format and location
   - Check device sound settings
   - Test with default system sound first

4. **Navigation not working from notifications**
   - Ensure navigator key is properly set
   - Check payload handling logic
   - Test both foreground and background scenarios

### Debug Mode

```dart
// Enable debug mode to see detailed logs
await NotificationService.showSimpleNotification(
  title: 'Debug Test',
  body: 'Check console for debug information',
);
```

## Complete Example App

See the `example/` folder for a complete working example that demonstrates:

- All notification types
- Platform-specific features
- Error handling
- Navigation from notifications
- Permission management

## Next Steps

1. Follow platform-specific setup guides:

   - [Android Setup](./ANDROID_SETUP.md)
   - [iOS Setup](./IOS_SETUP.md)

2. Customize notification appearance and behavior
3. Implement your app-specific notification logic
4. Test thoroughly on target devices
5. Submit to app stores with proper permission descriptions

## Support

For issues specific to this package, check:

- Platform setup guides
- Example app implementation
- [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications)

Remember to test notifications on real devices, as simulators have limitations for notification testing.
