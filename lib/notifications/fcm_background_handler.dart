import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'fcm_local_display.dart';
import 'fcm_message_parser.dart';

/// Top-level FCM background handler (app terminated or background).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[Kickora Notifications] background handler invoked');
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final payload = FcmMessageParser.parse(message);
    await FcmLocalDisplay.showFromPayload(
      payload,
      deliveryPhase: 'background',
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Kickora Notifications] background handler error: $e');
    }
  }
}
