import 'package:flutter/foundation.dart';

import '../models/kickora_notification.dart';
import '../models/notification_type.dart';
import '../notification_channels.dart';

/// Displays alerts on-device (mock: in-memory + debug log until plugin is wired).
abstract class LocalNotificationHelper {
  Future<void> initialize();

  Future<void> show(KickoraNotification notification);

  Future<void> cancel(String id);

  Future<void> cancelAll();
}

class MockLocalNotificationHelper implements LocalNotificationHelper {
  final List<KickoraNotification> delivered = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(KickoraNotification notification) async {
    delivered.add(notification);
    if (kDebugMode) {
      final channel = NotificationChannels.forType(notification.type.wireValue);
      debugPrint(
        '[Kickora Notifications] local → '
        'channel=$channel title=${notification.title}',
      );
    }
  }

  @override
  Future<void> cancel(String id) async {
    delivered.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> cancelAll() async {
    delivered.clear();
  }
}
