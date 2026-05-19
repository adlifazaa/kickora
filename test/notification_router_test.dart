import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/notifications/models/notification_tap_intent.dart';
import 'package:kickora/notifications/models/notification_type.dart';
import 'package:kickora/notifications/notification_router.dart';
import 'package:kickora/data/repositories/football_repository.dart';

void main() {
  test('routes match notifications to match details', () {
    final router = NotificationRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      footballRepository: FootballRepository(),
    );
    final target = router.resolveTarget(
      const NotificationTapIntent(
        type: NotificationType.goalScored,
        matchId: 42,
      ),
    );
    expect(target, NotificationRoutingTarget.matchDetails);
  });

  test('routes competition updates to competition details', () {
    final router = NotificationRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      footballRepository: FootballRepository(),
    );
    final target = router.resolveTarget(
      const NotificationTapIntent(
        type: NotificationType.favoriteCompetitionUpdate,
        competitionId: 39,
      ),
    );
    expect(target, NotificationRoutingTarget.competitionDetails);
  });

  test('routes team updates to favorites when no team screen', () {
    final router = NotificationRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      footballRepository: FootballRepository(),
    );
    final target = router.resolveTarget(
      const NotificationTapIntent(
        type: NotificationType.favoriteTeamUpdate,
        teamId: 7,
      ),
    );
    expect(target, NotificationRoutingTarget.favorites);
  });

  test('falls back to home without ids', () {
    final router = NotificationRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      footballRepository: FootballRepository(),
    );
    final target = router.resolveTarget(
      const NotificationTapIntent(type: NotificationType.matchStarted),
    );
    expect(target, NotificationRoutingTarget.home);
  });
}
