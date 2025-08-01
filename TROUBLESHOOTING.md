# Troubleshooting Guide - App Notification Handler

This guide helps you resolve common issues when implementing local notifications with the `app_notification_handler` package.

## Quick Diagnostic Steps

### 1. Basic Check

```dart
// Test if basic notification works
await NotificationService.showSimpleNotification(
  title: 'Test',
  body: 'Basic notification test',
);
```

### 2. Permission Check

```dart
final hasPermission = await AppNotificationHandler.instance.checkNotificationPermission();
print('Has notification permission: $hasPermission');
```

### 3. Pending Notifications

```dart
final pending = await NotificationService.getPendingNotifications();
print('Pending notifications: ${pending.length}');
```

## Android Issues

### Issue: Notifications not showing on Android 13+

**Symptoms:**

- Notifications work on older Android versions
- No notifications appear on Android 13+ devices

**Cause:** Android 13+ requires runtime notification permission

**Solution:**

1. Add permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

2. The package handles permission requests automatically, but verify:

```dart
final hasPermission = await AppNotificationHandler.instance.checkNotificationPermission();
if (!hasPermission) {
  // Package will show permission dialog
}
```

### Issue: Scheduled notifications disappear after device restart

**Symptoms:**

- Scheduled notifications work initially
- Stop working after device reboot

**Cause:** Missing boot receiver configuration

**Solution:**
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### Issue: Notifications not showing when app is in foreground

**Symptoms:**

- Notifications appear when app is in background
- No notifications when app is active

**Cause:** Incorrect channel configuration

**Solution:**

```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'your_channel_id',
  'Your Channel Name',
  channelDescription: 'Channel description',
  importance: Importance.max,
  priority: Priority.high,
  showWhen: true,
  enableVibration: true,
  playSound: true,
);
```

### Issue: Custom notification icons not appearing

**Symptoms:**

- Default Android icon shows instead of custom icon
- Icon appears corrupted or blank

**Solutions:**

1. **Check icon format:**

   - Use white/transparent PNG files
   - Don't use colored icons
   - Create multiple resolutions

2. **Correct file structure:**

```
android/app/src/main/res/
├── drawable-hdpi/notification_icon.png (72x72)
├── drawable-mdpi/notification_icon.png (48x48)
├── drawable-xhdpi/notification_icon.png (96x96)
├── drawable-xxhdpi/notification_icon.png (144x144)
└── drawable-xxxhdpi/notification_icon.png (192x192)
```

3. **Use in code:**

```dart
androidIcon: '@drawable/notification_icon', // Not @mipmap
```

### Issue: Exact alarms not working on Android 12+

**Symptoms:**

- Scheduled notifications are delayed
- Not firing at exact times

**Cause:** Android 12+ requires explicit exact alarm permission

**Solution:**

1. Add permission:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

2. Check and request permission:

```dart
// Check if exact alarms are allowed (Android 12+)
if (Platform.isAndroid) {
  // Handle exact alarm permission if needed
}
```

### Issue: Battery optimization preventing notifications

**Symptoms:**

- Notifications work initially but stop after some time
- Issues on specific OEM devices (Huawei, Xiaomi, etc.)

**Solutions:**

1. **Guide users to whitelist your app:**

```dart
Future<void> openBatteryOptimizationSettings() async {
  if (Platform.isAndroid) {
    await openAppSettings();
  }
}
```

2. **Check for background restrictions:**

   - Settings → Apps → [Your App] → Battery → Allow background activity

3. **OEM-specific settings:**
   - **Huawei:** Settings → Battery → App launch → [Your App] → Manage manually
   - **Xiaomi:** Settings → Battery & performance → Manage apps' battery usage
   - **OnePlus:** Settings → Battery → Battery optimization → [Your App] → Don't optimize

## iOS Issues

### Issue: Notifications not showing on iOS

**Symptoms:**

- No notifications appear at all on iOS
- Works on Android but not iOS

**Cause:** Permission not granted or incorrect setup

**Solutions:**

1. **Check iOS deployment target:**

```ruby
# ios/Podfile
platform :ios, '12.0'
```

2. **Verify Info.plist configuration:**

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>background-processing</string>
</array>
```

3. **Check permission status:**

```dart
final settings = await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
    ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
```

### Issue: iOS notifications not showing in foreground

**Symptoms:**

- Notifications only appear when app is in background
- No banner/alert when app is active

**Cause:** Missing presentation options

**Solution:**

```dart
const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);

const NotificationDetails platformDetails = NotificationDetails(
  iOS: iosDetails,
);
```

### Issue: Custom sounds not playing on iOS

**Symptoms:**

- Default system sound plays instead of custom sound
- No sound at all

**Solutions:**

1. **Check sound file format:**

   - Use `.caf`, `.aiff`, or `.wav` formats
   - Avoid `.mp3` for iOS

2. **Convert sound file:**

```bash
afconvert input.mp3 output.caf -d ima4 -f caff -v
```

3. **Add to Xcode project:**

   - Right-click Runner in Xcode
   - Add Files to Runner
   - Select sound file
   - Ensure it's added to target

4. **Use correct filename:**

```dart
soundFile: 'notification_sound.caf', // Include extension for iOS
```

### Issue: Badge count not updating

**Symptoms:**

- Badge shows wrong number
- Badge doesn't clear when app is opened

**Solution:**

```dart
// Clear badge when app opens
void clearBadge() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.setIconBadgeNumber(0);
}

// Set specific badge count
void setBadgeCount(int count) async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.setIconBadgeNumber(count);
}
```

## Cross-Platform Issues

### Issue: Timezone-related scheduling problems

**Symptoms:**

- Notifications scheduled for wrong time
- Time shifts with daylight saving changes

**Solutions:**

1. **Initialize timezone properly:**

```dart
await NotificationHelper.initializeTimezone();
```

2. **Use timezone-aware scheduling:**

```dart
// Good - uses timezone
final scheduledTime = NotificationHelper.nextInstanceOf(9, 0, 0);

// Bad - uses local time without timezone
final badTime = DateTime.now().add(Duration(hours: 1));
```

3. **Handle timezone changes:**

```dart
// Reschedule notifications when timezone changes
void handleTimezoneChange() async {
  await NotificationService.cancelAllNotifications();
  // Re-schedule with new timezone
  await scheduleAllNotifications();
}
```

### Issue: Navigation not working from notifications

**Symptoms:**

- Tapping notification doesn't navigate
- App opens but stays on current screen

**Solutions:**

1. **Ensure navigator key is set:**

```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// In MaterialApp
MaterialApp(
  navigatorKey: navigatorKey,
  // ...
)

// In notification initialization
await AppNotificationHandler.instance.initialize(
  config: NotificationConfig(
    // ...
  ),
  navigatorKey: navigatorKey,
);
```

2. **Handle both foreground and background taps:**

```dart
void _onNotificationTap(NotificationResponse response) {
  _handleNotificationPayload(response.payload);
}

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  _handleNotificationPayload(response.payload);
}
```

3. **Check payload handling:**

```dart
void _handleNotificationPayload(String? payload) {
  if (payload == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushNamed('/target-screen');
  });
}
```

### Issue: App crashes when showing notifications

**Symptoms:**

- App crashes immediately when notification method is called
- Error in console about missing dependencies

**Solutions:**

1. **Check initialization:**

```dart
// Must be called before any notification operations
await NotificationHelper.initializeTimezone();
await AppNotificationHandler.instance.initialize(config: config);
```

2. **Verify dependencies:**

```yaml
dependencies:
  flutter_local_notifications: ^19.3.1
  permission_handler: ^12.0.1
  timezone: ^0.10.1
  flutter_timezone: ^4.1.1
```

3. **Check platform setup:**
   - Verify Android manifest configuration
   - Verify iOS Info.plist configuration

## Performance Issues

### Issue: App startup delay

**Symptoms:**

- App takes longer to start after adding notifications
- Freezes during initialization

**Solutions:**

1. **Initialize asynchronously:**

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show splash screen immediately
  runApp(SplashApp());

  // Initialize notifications in background
  _initializeNotifications();
}

Future<void> _initializeNotifications() async {
  await NotificationHelper.initializeTimezone();
  await AppNotificationHandler.instance.initialize(config: config);

  // Navigate to main app after initialization
  navigatorKey.currentState?.pushReplacement(
    MaterialPageRoute(builder: (context) => MainApp()),
  );
}
```

2. **Lazy initialization:**

```dart
class NotificationManager {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    await NotificationHelper.initializeTimezone();
    await AppNotificationHandler.instance.initialize(config: config);
    _initialized = true;
  }
}
```

## Debugging Tools

### Enable Debug Logging

```dart
// Add debug prints to track notification flow
void debugNotificationFlow() async {
  print('1. Checking permissions...');
  final hasPermission = await AppNotificationHandler.instance.checkNotificationPermission();
  print('Permission granted: $hasPermission');

  print('2. Showing test notification...');
  await NotificationService.showSimpleNotification(
    title: 'Debug Test',
    body: 'Notification debugging',
  );

  print('3. Checking pending notifications...');
  final pending = await NotificationService.getPendingNotifications();
  print('Pending: ${pending.length}');
}
```

### Platform-Specific Debugging

**Android:**

```bash
# Monitor logs
adb logcat | grep -i "flutter\|notification"

# Check notification channels
adb shell dumpsys notification
```

**iOS:**

```bash
# Use Xcode console or device logs
# Look for UserNotifications framework messages
```

## Getting Help

### Before Asking for Help

1. **Check platform setup guides**
2. **Test on real devices, not simulators**
3. **Try the debug methods above**
4. **Check that you're using the latest package version**

### When Reporting Issues

Include:

- Platform (Android/iOS) and version
- Device model and OS version
- Flutter version
- Package version
- Minimal code example
- Error logs/screenshots
- Steps to reproduce

### Additional Resources

- [Flutter Local Notifications Documentation](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Documentation](https://developer.android.com/guide/topics/ui/notifiers/notifications)
- [iOS UserNotifications Documentation](https://developer.apple.com/documentation/usernotifications)
- Package-specific setup guides:
  - [Android Setup](./ANDROID_SETUP.md)
  - [iOS Setup](./IOS_SETUP.md)
