# Android Setup Guide for Local Notifications

This guide provides step-by-step instructions for setting up local notifications on Android using the `app_notification_handler` package.

## Prerequisites

- Flutter SDK
- Android development environment
- Minimum Android SDK version 19 (Android 4.4)

## 1. Gradle Configuration

### Update `android/app/build.gradle`

Ensure your `minSdkVersion` is at least 19:

```gradle
android {
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "your.package.name"
        minSdkVersion 19  // Minimum required for notifications
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
}
```

## 2. Permissions

### Add to `android/app/src/main/AndroidManifest.xml`

Add these permissions inside the `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="your.package.name">

    <!-- Required for notifications -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <!-- For Android 13+ (API 33+) - Request notification permission -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <!-- For exact alarms (Android 12+) -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

    <application
        android:label="Your App Name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Your main activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Intent filters for your main activity -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Notification receiver for boot completed -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <!-- Notification receiver -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
    </application>
</manifest>
```

## 3. Notification Icons

### Create notification icons

1. Create notification icons in different resolutions:

   - `android/app/src/main/res/drawable-hdpi/notification_icon.png` (72x72)
   - `android/app/src/main/res/drawable-mdpi/notification_icon.png` (48x48)
   - `android/app/src/main/res/drawable-xhdpi/notification_icon.png` (96x96)
   - `android/app/src/main/res/drawable-xxhdpi/notification_icon.png` (144x144)
   - `android/app/src/main/res/drawable-xxxhdpi/notification_icon.png` (192x192)

2. **Important**: Use white/transparent PNG files for notification icons. Android will automatically tint them.

3. Alternatively, you can use your app icon: `@mipmap/ic_launcher`

### Icon Guidelines

- Use vector drawable when possible
- Keep icons simple and recognizable
- Follow Material Design guidelines
- Icons should work well when tinted by the system

## 4. Custom Notification Sounds (Optional)

### Add custom sound files

1. Create directory: `android/app/src/main/res/raw/`
2. Add sound files (`.mp3`, `.wav`, `.ogg` formats)
3. Use filename without extension in your code:

```dart
await NotificationService.showNotificationWithCustomSound(
  title: 'Custom Sound',
  body: 'This notification has a custom sound',
  soundFile: 'notification_sound', // For notification_sound.mp3
);
```

## 5. ProGuard Configuration (If using ProGuard)

### Add to `android/app/proguard-rules.pro`

```proguard
# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.** { *; }

# Timezone
-keep class io.flutter.plugins.timezone.** { *; }
```

## 6. Testing Android Setup

### Test basic notification:

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

// Test simple notification
await NotificationService.showSimpleNotification(
  title: 'Test Notification',
  body: 'Android setup is working!',
);
```

### Test scheduled notification:

```dart
// Schedule notification for 5 minutes from now
final scheduledTime = NotificationHelper.minutesFromNow(5);

await NotificationService.scheduleNotification(
  id: 1,
  title: 'Scheduled Test',
  body: 'This was scheduled 5 minutes ago',
  scheduledTime: scheduledTime,
);
```

## 7. Common Android Issues and Solutions

### Issue: Notifications not showing on Android 13+

**Solution**: Ensure you request `POST_NOTIFICATIONS` permission:

```dart
final hasPermission = await AppNotificationHandler.instance.checkNotificationPermission();
if (!hasPermission) {
  // The package will automatically show permission dialog
}
```

### Issue: Scheduled notifications not working after app restart

**Solution**: Ensure you have the boot receiver in your manifest (step 2).

### Issue: Custom icons not showing

**Solution**:

- Verify icon files are in correct drawable folders
- Use white/transparent PNG files
- Check icon naming (no spaces, lowercase, underscores only)

### Issue: Notifications not showing in foreground

**Solution**: Configure notification channels properly:

```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'your_channel_id',
  'Your Channel Name',
  channelDescription: 'Channel description',
  importance: Importance.max,
  priority: Priority.high,
  showWhen: true,
);
```

### Issue: Sound not playing

**Solution**:

- Verify sound file is in `android/app/src/main/res/raw/`
- Use correct filename (without extension)
- Check device notification settings

## 8. Android 12+ Considerations

### Exact Alarms

For Android 12+, exact alarms require special permission. Add to your manifest:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### Notification Runtime Permission

Android 13+ requires runtime permission for notifications. The package handles this automatically.

## 9. Testing on Different Android Versions

### Test Matrix:

- Android 6.0 (API 23) - Doze mode behavior
- Android 8.0 (API 26) - Notification channels
- Android 10 (API 29) - Background activity restrictions
- Android 12 (API 31) - Exact alarm permissions
- Android 13 (API 33) - Notification runtime permissions

### Device Settings to Check:

1. App notifications enabled
2. Do Not Disturb settings
3. Battery optimization settings
4. Auto-start permissions (some OEMs)

## 10. Debugging

### Enable debug logging:

```dart
// Add this to see notification plugin logs
await NotificationService.showSimpleNotification(
  title: 'Debug',
  body: 'Check logcat for plugin messages',
);
```

### Check logcat:

```bash
adb logcat | grep flutter
```

### Common log tags to monitor:

- `FlutterLocalNotifications`
- `NotificationService`
- `ScheduledNotificationBootReceiver`

## Conclusion

Following this guide ensures your Android app is properly configured for local notifications. The `app_notification_handler` package handles most of the complexity, but proper platform setup is crucial for reliable notification delivery.

For additional troubleshooting, refer to the [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications) and Android's official [notification documentation](https://developer.android.com/guide/topics/ui/notifiers/notifications).
