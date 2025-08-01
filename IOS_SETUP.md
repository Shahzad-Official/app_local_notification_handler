# iOS Setup Guide for Local Notifications

This guide provides step-by-step instructions for setting up local notifications on iOS using the `app_notification_handler` package.

## Prerequisites

- Flutter SDK
- Xcode (latest stable version recommended)
- iOS deployment target 12.0+
- Apple Developer Account (for device testing)

## 1. iOS Deployment Target

### Update `ios/Podfile`

Ensure your iOS deployment target is at least 12.0:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# If you're using Flutter 3.19+, add this
pod 'FMDB', '~> 2.7.5'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Add this to fix potential build issues
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

### Update `ios/Runner.xcodeproj`

1. Open `ios/Runner.xcodeproj` in Xcode
2. Select the "Runner" project in the navigator
3. Under "Deployment Info", set "iOS Deployment Target" to 12.0

## 2. Info.plist Configuration

### Update `ios/Runner/Info.plist`

Add notification-related keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->

    <!-- Allow notification sounds in background -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>background-fetch</string>
        <string>background-processing</string>
    </array>

    <!-- Required for local notifications -->
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER).notification</string>
    </array>

    <!-- App Transport Security (if needed for custom sounds from web) -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>

    <!-- Notification permission description (optional) -->
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>

    <!-- Your existing keys continue here... -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Your App Name</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>your_app_name</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
</dict>
</plist>
```

## 3. Notification Capabilities

### Enable Capabilities in Xcode

1. Open `ios/Runner.xcodeproj` in Xcode
2. Select the "Runner" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" and add:
   - **Push Notifications** (if using remote notifications later)
   - **Background Modes** (select "Background App Refresh" and "Audio, AirPlay, and Picture in Picture")

### Alternative: Manual entitlements

Create `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.usernotifications.time-sensitive</key>
    <true/>
    <key>com.apple.developer.usernotifications.critical-alerts</key>
    <true/>
</dict>
</plist>
```

## 4. Notification Categories (For Actionable Notifications)

### Define notification categories in your Flutter app:

```dart
import 'package:app_notification_handler/app_notification_handler.dart';

final List<DarwinNotificationCategory> iosCategories = [
  DarwinNotificationCategory(
    'task_category',
    actions: [
      DarwinNotificationAction.plain(
        'complete_action',
        'Mark Complete',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        'snooze_action',
        'Snooze 10min',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.destructive,
        },
      ),
    ],
    options: <DarwinNotificationCategoryOption>{
      DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
    },
  ),
  DarwinNotificationCategory(
    'reminder_category',
    actions: [
      DarwinNotificationAction.plain(
        'view_action',
        'View',
      ),
      DarwinNotificationAction.plain(
        'dismiss_action',
        'Dismiss',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.destructive,
        },
      ),
    ],
  ),
];
```

## 5. Custom Notification Sounds

### Add custom sounds to iOS

1. Create directory: `ios/Runner/Sounds/`
2. Add sound files in supported formats:

   - `.aiff`
   - `.wav`
   - `.caf` (recommended)
   - `.m4a`

3. Add sound files to Xcode project:

   - Right-click on "Runner" in Xcode
   - Select "Add Files to Runner"
   - Choose your sound files
   - Ensure "Add to target: Runner" is checked

4. Use in your code:

```dart
await NotificationService.showNotificationWithCustomSound(
  title: 'Custom Sound',
  body: 'iOS notification with custom sound',
  soundFile: 'notification_sound.caf',
);
```

### Convert sounds to iOS-compatible format:

```bash
# Convert MP3 to CAF (Core Audio Format)
afconvert input.mp3 output.caf -d ima4 -f caff -v
```

## 6. Notification Permission Handling

### The package automatically handles permissions, but you can customize:

```dart
Future<void> initializeNotifications() async {
  await AppNotificationHandler.instance.initialize(
    config: NotificationConfig(
      androidIcon: '@mipmap/ic_launcher',
      iosCategories: iosCategories,
      onNotificationTap: (NotificationResponse response) {
        print('Foreground notification tapped: ${response.payload}');
      },
      onBackgroundNotificationTap: (NotificationResponse response) {
        print('Background notification tapped: ${response.payload}');
      },
    ),
    navigatorKey: navigatorKey,
  );
}
```

## 7. Testing iOS Setup

### Test basic notification:

```dart
await NotificationService.showSimpleNotification(
  title: 'iOS Test',
  body: 'Local notification working on iOS!',
);
```

### Test with iOS-specific features:

```dart
const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  categoryIdentifier: 'task_category',
  threadIdentifier: 'task_thread',
  subtitle: 'Task Management',
  sound: 'notification_sound.caf',
  badgeNumber: 1,
);

const NotificationDetails platformDetails = NotificationDetails(
  iOS: iosDetails,
);

await flutterLocalNotificationsPlugin.show(
  0,
  'iOS Specific Test',
  'This notification uses iOS-specific features',
  platformDetails,
);
```

## 8. Background App Refresh

### Enable in device settings:

1. Settings → General → Background App Refresh
2. Enable for your app

### Handle app lifecycle in Flutter:

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        break;
      case AppLifecycleState.paused:
        // App is in background
        break;
      case AppLifecycleState.detached:
        // App is terminated
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
}
```

## 9. Common iOS Issues and Solutions

### Issue: Notifications not showing in foreground

**Solution**: Configure presentation options:

```dart
const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);
```

### Issue: Scheduled notifications not working after device restart

**Solution**: iOS handles this automatically, but ensure proper timezone initialization:

```dart
await NotificationHelper.initializeTimezone();
```

### Issue: Custom sounds not playing

**Solution**:

- Verify sound file is added to Xcode project
- Check sound file format (use .caf when possible)
- Ensure sound duration is between 0.5-30 seconds

### Issue: Badge count not updating

**Solution**: Manually update badge when app opens:

```dart
void resetBadgeCount() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}
```

### Issue: Permissions denied

**Solution**: Guide users to settings:

```dart
Future<void> openNotificationSettings() async {
  await openAppSettings(); // From permission_handler package
}
```

## 10. iOS Simulator vs Device Testing

### Simulator Limitations:

- No push notifications
- Limited background processing
- Some notification features may not work

### Device Testing:

- Real notification delivery timing
- Background app refresh behavior
- Actual notification sounds and vibrations

### Testing Matrix:

- iOS 12.0+ (minimum supported)
- iPhone and iPad
- Different notification permission states
- App in foreground/background/terminated states

## 11. App Store Considerations

### Privacy Manifest (iOS 17+)

Create `ios/Runner/PrivacyInfo.xcprivacy` if required:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### App Store Guidelines:

- Request permissions with clear context
- Don't spam users with notifications
- Provide value with each notification
- Allow users to customize notification settings

## 12. Debugging iOS Notifications

### Console.app (macOS):

1. Connect iOS device
2. Open Console.app
3. Filter by your app's bundle identifier
4. Look for notification-related logs

### Xcode Debugging:

```bash
# Enable notification debugging
po [[UNUserNotificationCenter currentNotificationCenter] getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
    NSLog(@"Pending notifications: %@", requests);
}]
```

### Common log messages to monitor:

- `UserNotifications` framework logs
- `flutter_local_notifications` plugin logs
- App lifecycle events

## Conclusion

Following this guide ensures your iOS app is properly configured for local notifications. The `app_notification_handler` package abstracts most complexity, but proper iOS platform setup is essential for reliable notification delivery.

For additional troubleshooting, refer to:

- [flutter_local_notifications iOS setup](https://pub.dev/packages/flutter_local_notifications#-ios-setup)
- [Apple's UserNotifications framework documentation](https://developer.apple.com/documentation/usernotifications)
- [iOS Human Interface Guidelines for Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
