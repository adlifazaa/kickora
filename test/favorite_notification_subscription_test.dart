import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/notifications/notification_channels.dart';
import 'package:kickora/notifications/services/kickora_notification_service.dart';
import 'package:kickora/services/favorite_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notifications disabled by default — favorites do not subscribe', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = KickoraNotificationService.createMock(prefs);
    await notifications.initialize();
    expect(notifications.isEnabled, isFalse);

    final manager = FavoriteManager(
      prefs,
      notificationService: notifications,
    );
    await manager.load();
    await manager.toggleTeam(7);
    expect(manager.isTeamFavorite(7), isTrue);
    expect(notifications.mockFirebase?.subscribedTopics ?? {}, isEmpty);
  });

  test('when enabled, favorites subscribe and unsubscribe by type', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = KickoraNotificationService.createMock(prefs);
    await notifications.initialize();

    final manager = FavoriteManager(
      prefs,
      notificationService: notifications,
    );
    await manager.load();

    await notifications.enable(
      favoriteTeamIds: const {},
      favoriteMatchIds: const {},
      favoriteCompetitionIds: const {},
    );

    await manager.toggleTeam(7);
    await manager.toggleCompetition(39);
    await manager.toggleMatch(1001);

    final topics = notifications.mockFirebase!.subscribedTopics;
    expect(topics, contains(NotificationTopics.team(7)));
    expect(topics, contains(NotificationTopics.competition(39)));
    expect(topics, contains(NotificationTopics.match(1001)));

    await manager.toggleTeam(7);
    expect(
      notifications.mockFirebase!.subscribedTopics,
      isNot(contains(NotificationTopics.team(7))),
    );
  });

  test('restore subscriptions after simulated app restart', () async {
    SharedPreferences.setMockInitialValues({});
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

    await notifications.enable(
      favoriteTeamIds: manager.teamIds,
      favoriteMatchIds: manager.matchIds,
      favoriteCompetitionIds: manager.competitionIds,
    );

    await notifications.disable();
    expect(notifications.mockFirebase!.subscribedTopics, isEmpty);

    await prefs.setBool(KickoraNotificationService.enabledPreferenceKey, true);

    final manager2 = FavoriteManager(
      prefs,
      notificationService: notifications,
    );
    await manager2.load();

    final count = await manager2.restoreSubscriptions();
    expect(count, 2);
    expect(
      notifications.mockFirebase!.subscribedTopics,
      containsAll([NotificationTopics.team(3), NotificationTopics.match(99)]),
    );
  });
}
