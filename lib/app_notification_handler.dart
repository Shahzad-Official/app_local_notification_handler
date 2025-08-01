// Export the main classes and functions
export 'src/notification_config.dart';
export 'src/notification_service.dart';
export 'src/notification_helper.dart';

// Re-export commonly used classes from flutter_local_notifications
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        NotificationResponse,
        AndroidNotificationAction,
        DarwinNotificationCategory,
        DarwinNotificationAction,
        DarwinNotificationCategoryOption,
        PendingNotificationRequest,
        Importance,
        Priority;
