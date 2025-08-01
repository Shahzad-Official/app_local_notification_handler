# App Notification Handler

A comprehensive Flutter package for handling local notifications with scheduling, permissions, and timezone support. This package provides a clean and easy-to-use API for managing notifications in your Flutter applications.

## Features

- **Easy Setup**: Simple initialization with customizable configuration
- **Permission Handling**: Automatic permission checking with user-friendly dialogs
- **Timezone Support**: Full timezone support for accurate scheduling
- **Multiple Notification Types**: Support for simple, scheduled, actionable, and progress notifications
- **Cross-Platform**: Works on both Android and iOS
- **Flexible Scheduling**: Various scheduling options including daily repeats and custom intervals

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  app_notification_handler:
    git:
      url: https://github.com/Shahzad-Official/app_local_notification_handler.git
```

## Setup Guides

For complete platform setup instructions, follow these guides:

- **[📖 Complete Setup Guide](./SETUP_GUIDE.md)** - Start here for full implementation
- **[🤖 Android Setup](./ANDROID_SETUP.md)** - Detailed Android configuration
- **[🍎 iOS Setup](./IOS_SETUP.md)** - Detailed iOS configuration
- **[🔧 Troubleshooting](./TROUBLESHOOTING.md)** - Common issues and solutions

## Usage

### 1. Initialize the Notification Handler

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  await NotificationHelper.initializeTimezone();

  // Initialize notification handler
  await AppNotificationHandler.instance.initialize(
    config: const NotificationConfig(
      androidIcon: '@mipmap/ic_launcher',
      onNotificationTap: _onNotificationTap,
      onBackgroundNotificationTap: notificationTapBackground,
    ),
    navigatorKey: navigatorKey, // Your global navigator key
  );

  runApp(MyApp());
}

void _onNotificationTap(NotificationResponse response) {
  // Handle notification tap
  print('Notification tapped: ${response.payload}');
}
```

### 2. Show Simple Notification

```dart
await NotificationService.showSimpleNotification(
  title: 'Hello!',
  body: 'This is a simple notification',
  payload: 'simple_payload',
);
```

### 3. Schedule Notification

```dart
// Schedule for tomorrow at 9 AM
final scheduledTime = NotificationHelper.nextInstanceOf(9, 0, 0);

await NotificationService.scheduleNotification(
  id: 1,
  title: 'Good Morning!',
  body: 'Time to start your day',
  scheduledTime: scheduledTime,
  repeatDaily: true,
);
```

### 4. Show Actionable Notification

```dart
await NotificationService.showActionNotification(
  title: 'Do you accept?',
  body: 'Please choose an option',
  actions: [
    const AndroidNotificationAction('ACCEPT', 'Accept'),
    const AndroidNotificationAction('DECLINE', 'Decline'),
  ],
);
```

### 5. Helper Functions

```dart
// Schedule 5 minutes from now
final fiveMinutesLater = NotificationHelper.minutesFromNow(5);

// Schedule for next Monday at 2 PM
final nextMonday = NotificationHelper.nextInstanceOfWeekday(1, 14, 0);

// Create weekly schedule for multiple days
final weeklySchedule = NotificationHelper.createWeeklySchedule(
  [1, 3, 5], // Monday, Wednesday, Friday
  9, // 9 AM
  0, // 0 minutes
);
```

## Configuration Options

### NotificationConfig

```dart
const NotificationConfig(
  androidIcon: '@mipmap/ic_launcher', // Android notification icon
  iosCategories: [...], // iOS notification categories
  onNotificationTap: _onNotificationTap, // Foreground tap handler
  onBackgroundNotificationTap: notificationTapBackground, // Background tap handler
)
```

### Custom iOS Categories

```dart
final iosCategories = [
  DarwinNotificationCategory(
    'habit_category',
    actions: [
      DarwinNotificationAction.plain('complete', 'Mark Complete'),
      DarwinNotificationAction.plain('snooze', 'Snooze'),
    ],
    options: const {
      DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
    },
  ),
];
```

## Permission Handling

The package automatically handles permission requests. When a notification method is called, it will:

1. Check if notifications are enabled
2. Request permissions if needed (iOS)
3. Show a dialog prompting user to enable notifications in settings if disabled

You can also manually check permissions:

```dart
final hasPermission = await AppNotificationHandler.instance.checkNotificationPermission();
```

## Advanced Features

### Progress Notifications (Android)

```dart
await NotificationService.showProgressNotification(
  title: 'Downloading...',
  body: 'Download in progress',
  maxProgress: 100,
  currentProgress: 45,
);
```

### Custom Sound Notifications

```dart
await NotificationService.showNotificationWithCustomSound(
  title: 'Custom Sound',
  body: 'This notification has a custom sound',
  soundFile: 'notification_sound', // File in android/app/src/main/res/raw/
);
```

### Cancel Notifications

```dart
// Cancel specific notification
await NotificationService.cancelNotification(1);

// Cancel all notifications
await NotificationService.cancelAllNotifications();
```

### Get Pending Notifications

```dart
final pending = await NotificationService.getPendingNotifications();
print('Pending notifications: ${pending.length}');
```

## Platform Setup

### Android

**Essential Requirements:**

1. Add desugaring to `android/app/build.gradle`
2. Add 3 permissions to `AndroidManifest.xml`
3. Add 3 receivers to `AndroidManifest.xml`

**⚠️ Important:** Follow the [Android Setup Guide](./ANDROID_SETUP.md) for the essential 5-minute configuration.

### iOS

**Essential Requirements:**

1. Set iOS deployment target to 12.0+ in `ios/Podfile`
2. Add UIBackgroundModes to `ios/Runner/Info.plist`
3. Add delegate line to `ios/Runner/AppDelegate.swift`

**⚠️ Important:** Follow the [iOS Setup Guide](./IOS_SETUP.md) for the essential 3-minute configuration.

## Example

See the `/example` folder for a complete example application demonstrating all features of this package.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
