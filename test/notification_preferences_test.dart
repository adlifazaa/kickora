import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/notifications/models/notification_type.dart';
import 'package:kickora/notifications/notification_channels.dart';
import 'package:kickora/notifications/notification_preferences.dart';
import 'package:kickora/notifications/services/kickora_notification_service.dart';
import 'package:kickora/services/favorite_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('notification type prefs default true and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = NotificationPreferences(prefs);

    expect(settings.goalsEnabled, isTrue);
    await settings.setGoalsEnabled(false);
    expect(NotificationPreferences(prefs).goalsEnabled, isFalse);
    expect(
      NotificationPreferences(prefs).isMatchTypeEnabled(NotificationType.goalScored),
      isFalse,
    );
  });

  test('favorite team topics skipped when favorite team updates off', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPreferences.keyFavoriteTeam, false);

    final notifications = KickoraNotificationService.createMock(prefs);
    await notifications.initialize();

    final manager = FavoriteManager(
      prefs,
      notificationService: notifications,
    );
    await manager.load();
    await manager.toggleTeam(7);

    await notifications.enable(
      favoriteTeamIds: manager.teamIds,
      favoriteMatchIds: manager.matchIds,
      favoriteCompetitionIds: manager.competitionIds,
    );

    expect(
      notifications.mockFirebase!.subscribedTopics,
      isNot(contains(NotificationTopics.team(7))),
    );
  });

  test('restoreAfterStartup respects saved preferences', () async {
    SharedPreferences.setMockInitialValues({
      KickoraNotificationService.enabledPreferenceKey: true,
      NotificationPreferences.keyFavoriteMatch: true,
      NotificationPreferences.keyFavoriteTeam: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final notifications = KickoraNotificationService.createMock(prefs);
    await notifications.initialize();

    final manager = FavoriteManager(
      prefs,
      notificationService: notifications,
    );
    await manager.load();
    await manager.toggleTeam(3);
    await manager.toggleMatch(99);

    final count = await notifications.restoreAfterStartup(
      teamIds: manager.teamIds,
      matchIds: manager.matchIds,
      competitionIds: manager.competitionIds,
    );

    expect(count, 1);
    expect(
      notifications.mockFirebase!.subscribedTopics,
      contains(NotificationTopics.match(99)),
    );
    expect(
      notifications.mockFirebase!.subscribedTopics,
      isNot(contains(NotificationTopics.team(3))),
    );
  });
}
