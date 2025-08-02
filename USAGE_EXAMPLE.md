# App Notification Handler - Usage Example

## Updated Configuration with Automatic Permission Request

The notification handler has been updated to automatically request permissions during initialization, eliminating the need to request permissions on other pages.

## Setup in main.dart

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone (if using scheduled notifications)
  await NotificationHelper.initializeTimezone();

  // Initialize notification handler with automatic permission request
  await AppNotificationHandler.instance.initialize(
    config: const NotificationConfig(
      androidIcon: '@mipmap/ic_launcher', // Optional: custom icon
      onNotificationTap: _handleNotificationTap, // Optional: custom tap handler
      // Optional: Configure default notification channels
      defaultSimpleChannel: NotificationChannelConfig(
        channelId: 'my_app_simple',
        channelName: 'My App Simple',
        channelDescription: 'Simple notifications for my app',
        importance: Importance.high,
        priority: Priority.high,
      ),
      defaultScheduledChannel: NotificationChannelConfig(
        channelId: 'my_app_scheduled',
        channelName: 'My App Scheduled',
        channelDescription: 'Scheduled notifications for my app',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    navigatorKey: yourNavigatorKey, // For permission dialogs
    requestPermissionsOnInit: true, // This automatically requests permissions
  );

  runApp(MyApp());
}

// Optional: Custom notification tap handler
void _handleNotificationTap(NotificationResponse response) {
  // Handle notification tap
  print('Notification tapped: ${response.payload}');
}
```

## Key Changes

1. **Automatic Permission Request**: Permissions are now requested automatically during app initialization
2. **No Permission Dialogs on Other Pages**: You no longer need to call `checkNotificationPermission()` elsewhere
3. **Simplified Permission Checking**: Use `getPermissionStatus()` to check current status without requesting
4. **Channel Configuration**: Configure notification channels once during initialization instead of in each method call

## Usage in Other Parts of Your App

### Showing Notifications (Streamlined)

With channel configuration set during initialization, showing notifications is now much simpler:

```dart
// Simple notification - uses configured simple channel
await NotificationService.showSimpleNotification(
  id: 1,
  title: 'Hello World',
  body: 'This uses your configured channel!',
  payload: 'simple_notification',
);

// Scheduled notification - uses configured scheduled channel
await NotificationService.scheduleNotification(
  id: 2,
  title: 'Scheduled Notification',
  body: 'This will appear in 5 minutes',
  scheduledTime: NotificationHelper.minutesFromNow(5),
  payload: 'scheduled_notification',
);

// Action notification - uses configured action channel
await NotificationService.showActionNotification(
  id: 3,
  title: 'Action Notification',
  body: 'This has buttons',
  payload: 'action_notification',
);

// Progress notification - uses configured progress channel
await NotificationService.showProgressNotification(
  id: 4,
  title: 'Download Progress',
  body: 'Downloading file...',
  currentProgress: 50,
  maxProgress: 100,
);
```

### Override Channel for Specific Notifications

If you need a different channel for a specific notification:

```dart
await NotificationService.showSimpleNotification(
  id: 5,
  title: 'Special Notification',
  body: 'This uses a custom channel',
  payload: 'special_notification',
  customChannel: NotificationChannelConfig(
    channelId: 'special_channel',
    channelName: 'Special Channel',
    channelDescription: 'A special channel for this notification',
    importance: Importance.max,
    priority: Priority.high,
  ),
);
```

### Check Permission Status (without requesting)

```dart
// Just check if permissions are granted
bool hasPermissions = await AppNotificationHandler.instance.getPermissionStatus();
```

### Check and Optionally Show Settings Dialog

```dart
// Check permissions and optionally show settings dialog if denied
bool hasPermissions = await AppNotificationHandler.instance.checkNotificationPermission(
  showDialog: true, // Set to true only if you want to show settings dialog
);
```

## Platform-Specific Behavior

### Android

- For Android 13+ (API 33+), runtime notification permission is requested
- For older Android versions, permissions are granted by default
- Permission request happens automatically during initialization

### iOS

- Alert, badge, and sound permissions are requested during initialization
- Uses the iOS notification settings defined in your configuration

## Configuration Options

```dart
NotificationConfig(
  androidIcon: '@mipmap/ic_launcher', // Android notification icon
  iosCategories: [
    DarwinNotificationCategory(
      'custom_category',
      options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
    ),
  ], // Custom iOS categories
  onNotificationTap: (response) {
    // Handle foreground notification taps
  },
  onBackgroundNotificationTap: (response) {
    // Handle background notification taps
  },
  // Channel configurations (NEW!)
  defaultSimpleChannel: NotificationChannelConfig(
    channelId: 'my_app_simple',
    channelName: 'My App Simple',
    channelDescription: 'Simple notifications for my app',
    importance: Importance.high,
    priority: Priority.high,
  ),
  defaultScheduledChannel: NotificationChannelConfig(
    channelId: 'my_app_scheduled',
    channelName: 'My App Scheduled',
    channelDescription: 'Scheduled notifications for my app',
    importance: Importance.max,
    priority: Priority.high,
  ),
  defaultActionChannel: NotificationChannelConfig(
    channelId: 'my_app_actions',
    channelName: 'My App Actions',
    channelDescription: 'Action notifications for my app',
    importance: Importance.high,
    priority: Priority.high,
  ),
  defaultProgressChannel: NotificationChannelConfig(
    channelId: 'my_app_progress',
    channelName: 'My App Progress',
    channelDescription: 'Progress notifications for my app',
    importance: Importance.low,
    priority: Priority.low,
  ),
  defaultCustomSoundChannel: NotificationChannelConfig(
    channelId: 'my_app_custom_sound',
    channelName: 'My App Custom Sound',
    channelDescription: 'Custom sound notifications for my app',
    importance: Importance.max,
    priority: Priority.high,
  ),
)
```

## Benefits

1. **Better User Experience**: Permissions are requested early in the app lifecycle
2. **Simplified Code**: No need to handle permissions in multiple places
3. **Consistent Behavior**: Same permission handling across all platforms
4. **Error Prevention**: Reduces the chance of missing permission requests
5. **Centralized Channel Configuration**: Set up notification channels once during initialization
6. **Cleaner Notification Methods**: No need to specify channel details in every notification call
7. **Easy Maintenance**: Change channel configurations in one place
8. **Consistent Channel Usage**: All notifications of the same type use the same channel settings

## Migration from Previous Version

If you were previously calling `checkNotificationPermission()` in other parts of your app:

1. Remove those calls
2. Update your main.dart initialization as shown above
3. Use `getPermissionStatus()` if you need to check permission status
4. Only use `checkNotificationPermission(showDialog: true)` if you specifically want to show a settings dialog

The permissions will now be handled automatically during app startup!
