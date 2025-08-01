# Android Setup Guide for Local Notifications

This guide provides the essential steps to set up local notifications on Android using the `app_notification_handler` package.

## Prerequisites

- Minimum Android SDK version 19 (Android 4.4)

## 1. Required Gradle Configuration

### Add to `android/app/build.gradle`

Add these lines to enable scheduled notifications:

```gradle
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

## 2. Required Permissions

### Add to `android/app/src/main/AndroidManifest.xml`

Add these permissions inside the `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Required for notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

    <application>
        <!-- Your existing activity code stays the same -->

        <!-- Add these receivers for scheduled notifications -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>

        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <!-- Add this receiver for notification actions -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"/>

    </application>
</manifest>
```

## 3. Notification Icons (Optional)

### Create custom notification icons

1. Create these folders and add icon files:

   - `android/app/src/main/res/drawable-hdpi/notification_icon.png` (72x72)
   - `android/app/src/main/res/drawable-mdpi/notification_icon.png` (48x48)
   - `android/app/src/main/res/drawable-xhdpi/notification_icon.png` (96x96)
   - `android/app/src/main/res/drawable-xxhdpi/notification_icon.png` (144x144)
   - `android/app/src/main/res/drawable-xxxhdpi/notification_icon.png` (192x192)

2. Use white/transparent PNG files only

3. In your code, use: `androidIcon: '@drawable/notification_icon'`

## 4. Custom Sounds (Optional)

### Add custom notification sounds

1. Create folder: `android/app/src/main/res/raw/`
2. Add sound files: `notification_sound.mp3`
3. Use in code: `soundFile: 'notification_sound'` (without extension)

## 5. Test Your Setup

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

// Test basic notification
await NotificationService.showSimpleNotification(
  title: 'Test',
  body: 'Android setup working!',
);

// Test scheduled notification
final scheduledTime = NotificationHelper.minutesFromNow(1);
await NotificationService.scheduleNotification(
  id: 1,
  title: 'Scheduled Test',
  body: 'This was scheduled 1 minute ago',
  scheduledTime: scheduledTime,
);
```

## That's It!

Your Android app is now configured for notifications. The package handles permissions automatically - users will be prompted when needed.

For issues, check that:

- You added the desugaring configuration
- You added all three receivers to AndroidManifest.xml
- Your notification icons are white/transparent PNG files
