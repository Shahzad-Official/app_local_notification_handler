# iOS Setup Guide for Local Notifications

This guide provides the essential steps to set up local notifications on iOS using the `app_notification_handler` package.

## Prerequisites

- iOS deployment target 12.0+

## 1. Required iOS Configuration

### Update `ios/Podfile`

Set the iOS deployment target:

```ruby
platform :ios, '12.0'
```

### Update `ios/Runner/Info.plist`

Add these keys inside the `<dict>` tag:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>background-processing</string>
</array>
```

## 2. Required AppDelegate Configuration

### Update `ios/Runner/AppDelegate.swift`

Add this line to the `application` method:

```swift
import UIKit
import Flutter
// This is required for calling FlutterLocalNotificationsPlugin.setPluginRegistrantCallback method.
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Set delegate for UNUserNotificationCenter (required for foreground notifications)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // ✅ Enable background isolate to handle action taps (optional but recommended)
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 3. Custom Sounds (Optional)

### Add custom notification sounds

1. In Xcode, right-click on "Runner" → "Add Files to Runner"
2. Add sound files (`.caf`, `.aiff`, `.wav` formats recommended)
3. Ensure "Add to target: Runner" is checked
4. Use in code: `soundFile: 'notification_sound.caf'`

### Convert sounds to iOS format:

```bash
afconvert input.mp3 output.caf -d ima4 -f caff -v
```

## 4. Test Your Setup

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

// Test basic notification
await NotificationService.showSimpleNotification(
  title: 'iOS Test',
  body: 'iOS setup working!',
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

Your iOS app is now configured for notifications. The package handles permission requests automatically when notifications are first used.

For issues, check that:

- iOS deployment target is 12.0+
- You added the UIBackgroundModes to Info.plist
- You added the delegate line to AppDelegate.swift
- Custom sounds are in supported formats and added to Xcode project
