# SETUP Guide for app_local_notification_handler

This guide explains how to add and use the `app_local_notification_handler` package from GitHub in your Flutter project, including using a specific tag version.

## 1. Add the Package from GitHub

In your `pubspec.yaml`, add the following under `dependencies:`:

```yaml
dependencies:
  app_local_notification_handler:
    git:
      url: https://github.com/Shahzad-Official/app_notification_handler.git
      ref: v1.2.3 # Replace with the latest tag or desired version
```

- To use a specific release, change `v1.2.3` to the tag you want (see [Releases](https://github.com/Shahzad-Official/app_local_notification_handler/releases)).

Then run:

```sh
flutter pub get
```

## 2. Import and Use in Your App

In your Dart code, import the package:

```dart
import 'package:app_local_notification_handler/app_notification_handler.dart';
```

## 3. Example Usage in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:app_local_notification_handler/app_notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotificationHandler.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Notification Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              AppNotificationHandler.showNotification(
                title: 'Hello',
                body: 'This is a test notification',
              );
            },
            child: Text('Show Notification'),
          ),
        ),
      ),
    );
  }
}
```

## 4. Using in Other Apps

Repeat the above steps in any Flutter app where you want to use this package. Just add the dependency from GitHub and import as shown.

## 5. For Contributors

If you change `release.sh`, please ensure you update this `SETUP.md` file with any relevant setup or usage changes.

---

For more details, see the [README.md](./README.md) and [Releases](https://github.com/Shahzad-Official/app_local_notification_handler/releases).
