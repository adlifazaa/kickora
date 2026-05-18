import 'dart:async';

import 'package:flutter/material.dart';

import '../notifications/models/notification_tap_intent.dart';
import '../notifications/notification_router.dart';
import '../notifications/services/kickora_notification_service.dart';
import '../services/app_controller.dart';

/// Listens for notification taps and routes without changing app navigation.
class NotificationTapListener extends StatefulWidget {
  const NotificationTapListener({
    super.key,
    required this.controller,
    required this.router,
    required this.child,
  });

  final AppController controller;
  final NotificationRouter router;
  final Widget child;

  @override
  State<NotificationTapListener> createState() =>
      _NotificationTapListenerState();
}

class _NotificationTapListenerState extends State<NotificationTapListener> {
  StreamSubscription<NotificationTapIntent>? _sub;

  @override
  void initState() {
    super.initState();
    final service = widget.controller.notificationService;
    _sub = service.onNotificationTap.listen(_onTap);
    _consumePending(service);
  }

  Future<void> _consumePending(KickoraNotificationService service) async {
    final pending = service.pendingTapIntent;
    if (pending == null) return;
    service.pendingTapIntent = null;
    await widget.router.handleTap(pending);
  }

  Future<void> _onTap(NotificationTapIntent intent) async {
    await widget.router.handleTap(intent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
