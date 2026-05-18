import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/notifications/models/notification_permission_status.dart';
import 'package:kickora/notifications/models/notification_type.dart';
import 'package:kickora/notifications/notification_channels.dart';
import 'package:kickora/notifications/notification_manager.dart';
import 'package:kickora/notifications/models/notification_tap_intent.dart';
import 'package:kickora/notifications/services/kickora_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NotificationTopics use team_, match_, competition_ prefixes', () {
    expect(NotificationTopics.team(7), 'team_7');
    expect(NotificationTopics.match(100), 'match_100');
    expect(NotificationTopics.competition(1), 'competition_1');
  });

  test('NotificationType wire values for Phase 3 categories', () {
    expect(NotificationType.matchStarted.wireValue, 'match_started');
    expect(NotificationType.goalScored.wireValue, 'goal_scored');
    expect(NotificationType.redCard.wireValue, 'red_card');
    expect(NotificationType.matchFinished.wireValue, 'match_finished');
    expect(
      NotificationType.favoriteTeamUpdate.wireValue,
      'favorite_team_update',
    );
    expect(
      NotificationTypeX.fromWireValue('red_card'),
      NotificationType.redCard,
    );
  });

  test('notifications disabled by default — no permission on init', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = KickoraNotificationService.createMock(prefs);

    expect(service.isEnabled, isFalse);
    expect(
      await service.permissionStatus(),
      NotificationPermissionStatus.notDetermined,
    );

    await service.initialize();
    expect(service.isEnabled, isFalse);
    expect(service.usesMockFirebase, isTrue);

    final granted = await service.enable(favoriteTeamIds: {7});
    expect(granted, isTrue);
    expect(service.isEnabled, isTrue);
    expect(service.mockFirebase, isNotNull);

    await service.disable();
    expect(service.isEnabled, isFalse);
  });

  test('mock FCM tap publishes future-ready intent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = KickoraNotificationService.createMock(prefs);
    await service.initialize();
    await service.enable(favoriteTeamIds: {7});

    NotificationTapIntent? tapped;
    final sub = service.onNotificationTap.listen((intent) {
      tapped = intent;
    });

    service.mockFirebase!.simulateIncoming(
      {
        'type': 'match_finished',
        'matchId': '99',
        'topic': 'match_99',
      },
      openedApp: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(tapped, isNotNull);
    expect(tapped!.matchId, 99);
    expect(tapped!.type, NotificationType.matchFinished);
    expect(tapped!.topic, 'match_99');

    await sub.cancel();
    await service.dispose();
  });

  test('KickoraNotificationService.create defaults off without Firebase', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = KickoraNotificationService.create(prefs);
    expect(service.isEnabled, isFalse);
    await service.initialize();
    expect(service.isEnabled, isFalse);
    await service.dispose();
  });

  test('NotificationManager enabledPreferenceKey matches service', () {
    expect(
      KickoraNotificationService.enabledPreferenceKey,
      NotificationManager.enabledPreferenceKey,
    );
  });
}
