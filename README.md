# Firebase FCM Platform Setup Guide

This document provides detailed platform-specific setup instructions for Firebase Cloud Messaging (FCM) with Flutter.

## Prerequisites

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your Android/iOS app to the Firebase project
3. Download configuration files:
   - Android: `google-services.json`
   - iOS: `GoogleService-Info.plist`
4. Place the files in the appropriate directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

---

## Android Setup for Notifications

### Required Configuration

#### 1. Update `android/app/build.gradle`:

```gradle
android {
    compileSdk 35

    defaultConfig {
        minSdkVersion 23
        // ... other configurations
    }

    compileOptions {
        coreLibraryDesugaringEnabled true
        // ... other options
    }
}

plugins {
    id 'com.google.gms.google-services'
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
    // ... other dependencies
}
```

#### 2. Add to project-level `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
        // ... other dependencies
    }
}
```

#### 3. Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- FCM Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application>
        <!-- Your app content -->
    </application>
</manifest>
```

### Optional Configuration

Add these meta-data tags inside the `<application>` tag in `AndroidManifest.xml`:

```xml
<application>
    <!-- Default notification icon and color -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@mipmap/ic_launcher" />
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@android:color/white" />

    <!-- Default notification channel -->
    <!-- ⚠️ IMPORTANT: This value must match your Flutter channelId -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="street_channel_id" />

    <!-- Your other app content -->
</application>
```

> **⚠️ IMPORTANT - Channel ID Consistency:**
>
> The `channel_id` value specified in the `AndroidManifest.xml` file **MUST match** the `channelId` used in your Flutter notification initialization code.
>
> For example, if you use `"street_channel_id"` in the manifest (as shown above), you must use the same value when initializing your notification channels in Flutter:
>
> ```dart
> await AppNotificationHandler.initialize(
>   NotificationConfig(
>     defaultChannelId: 'street_channel_id', // Same as in AndroidManifest.xml
>     defaultChannelName: 'Street Notifications',
>     defaultChannelDescription: 'Important street app notifications',
>   ),
> );
> ```
>
> **Why this matters:**
>
> - Firebase uses the manifest channel ID for background notifications
> - Your app uses the Flutter channel ID for foreground notifications
> - Mismatched IDs can cause notifications to not display properly or appear in separate channels

---

## iOS Setup

### Required Configuration

#### 1. Add background modes to `ios/Runner/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <!-- Other Info.plist content -->

    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
        <string>background-processing</string>
        <string>fetch</string>
        <string>processing</string>
    </array>

    <!-- Other Info.plist content -->
</dict>
</plist>
```

#### 2. Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import flutter_local_notifications // ✅ Required for notification plugin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ✅ Set delegate for UNUserNotificationCenter (required for foreground notifications)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // ✅ Enable background isolate to handle action taps (optional but recommended)
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## App Store Connect Setup for Firebase Push Notifications

### For iOS Production Notifications

#### Step 1: Create APNs Key in Apple Developer Account

1. Go to [Apple Developer Console](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Keys** from the sidebar
4. Click the **"+"** button to create a new key
5. Give your key a name (e.g., "Firebase Push Notifications")
6. Select **Apple Push Notifications service (APNs)** checkbox
7. Configure push notifications:
   - Select both **sandbox** and **production** environments to work on both
   - Select your team as default
8. Click **Continue** and then **Register**
9. **Download the `.p8` key file** (you can only download this once!)
10. **Note down the Key ID** (displayed after creation)
11. **Note down your Team ID** (found in the top-right corner of the developer portal)

#### Step 2: Configure Firebase with APNs Key

1. Go to your [Firebase Console](https://console.firebase.google.com/)
2. Select your project and go to **Project Settings** (gear icon)
3. Navigate to the **Cloud Messaging** tab
4. Scroll down to the **iOS app configuration** section
5. In the **APNs certificates** section, click **Upload**
6. Choose **APNs auth key** option (recommended over certificates)
7. Upload your downloaded `.p8` file
8. Enter the following information:
   - **Key ID**: The Key ID you noted from Step 1
   - **Team ID**: Your Apple Developer Team ID
9. Click **Upload** to save the configuration

#### Step 3: Verify Configuration

1. **Test with Firebase Console:**

   - Go to **Cloud Messaging** in Firebase Console
   - Click **Send your first message**
   - Select your iOS app as the target
   - Send a test notification

2. **Check both environments:**

   - Test in **debug mode** (sandbox environment)
   - Test in **release/production mode** (production environment)

3. **Common verification steps:**
   - Ensure your app's Bundle ID matches the one in Firebase and Apple Developer Console
   - Verify the `.p8` key is correctly uploaded with the right Key ID and Team ID
   - Check that your iOS app has the correct provisioning profile

---

## Troubleshooting Platform Setup

### Android Issues

1. **Build errors:**

   - Ensure `google-services.json` is in the correct location: `android/app/`
   - Check that Google Services plugin is applied: `apply plugin: 'com.google.gms.google-services'`
   - Verify compileSdk and minSdk versions meet requirements

2. **Notifications not showing:**
   - Check if app has notification permissions
   - Verify FCM permissions are added to AndroidManifest.xml
   - Ensure notification channels are properly configured
   - **Verify channel_id consistency**: Make sure the `default_notification_channel_id` in AndroidManifest.xml matches the `channelId` used in Flutter notification initialization

### iOS Issues

1. **Build errors:**

   - Ensure `GoogleService-Info.plist` is added to the iOS project in Xcode
   - Check that the bundle identifier matches Firebase configuration
   - Verify Info.plist has correct background modes

2. **Notifications not working:**

   - Check APNs key configuration in Firebase Console
   - Ensure notification permissions are granted
   - Verify AppDelegate.swift is properly configured
   - Test with both debug and release builds

3. **APNs Key Issues:**
   - Double-check Key ID and Team ID in Firebase Console
   - Ensure the `.p8` file was uploaded correctly
   - Verify the key has APNs service enabled

### General Tips

- Always test notifications in different app states: foreground, background, and terminated
- Use Firebase Console's messaging tool for initial testing
- Check device logs for detailed error messages
- Ensure your app is properly signed for distribution when testing production notifications

### Channel ID Configuration Issues

**Problem**: Notifications appear in different channels or some don't show at all.

**Solution**: Ensure channel ID consistency between AndroidManifest.xml and Flutter code:

1. **Check AndroidManifest.xml**:

   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_channel_id"
       android:value="your_channel_id" />
   ```

2. **Check Flutter initialization**:

   ```dart
   await AppNotificationHandler.instance.initialize(
     config: NotificationConfig(
       defaultChannelId: 'your_channel_id', // Must match manifest
       // ... other settings
     ),
   );
   ```

3. **Verify on device**: Go to device Settings > Apps > [Your App] > Notifications to see if multiple channels exist.

**Additional checks**:

- Clear app data and reinstall to reset notification channels
- Test with a fresh Firebase Console message
- Check if background and foreground notifications use different channels

---

## Next Steps

After completing the platform setup:

1. Return to the main [Firebase FCM Integration Guide](FIREBASE_README.md)
2. Follow the Flutter implementation examples
3. Configure callbacks and message handling
4. Test your implementation thoroughly

For Flutter-specific implementation details, see the [main Firebase README](FIREBASE_README.md).
