import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/repositories/football_repository.dart';
import 'models/notification_tap_intent.dart';
import 'models/notification_type.dart';
import 'notification_debug_log.dart';

/// Future-ready routing for notification taps (no navigation redesign).
class NotificationRouter {
  NotificationRouter({
    required this.navigatorKey,
    required this.footballRepository,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final FootballRepository footballRepository;

  Future<void> handleTap(NotificationTapIntent intent) async {
    final target = resolveTarget(intent);
    NotificationDebugLog.routing(
      type: intent.type.wireValue,
      target: target.name,
      matchId: intent.matchId,
      teamId: intent.teamId,
      competitionId: intent.competitionId,
      topic: intent.topic,
    );

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (target) {
      case NotificationRoutingTarget.matchDetails:
        final matchId = intent.matchId;
        if (matchId == null || matchId <= 0) {
          _openHome(nav);
          return;
        }
        final state = await footballRepository.getMatchById(matchId);
        final match = state.data;
        if (match != null) {
          nav.pushNamed(AppRoutes.matchDetails, arguments: match);
        } else {
          _openHome(nav);
        }
      case NotificationRoutingTarget.competitionDetails:
        final competitionId = intent.competitionId;
        if (competitionId == null || competitionId <= 0) {
          _openHome(nav);
          return;
        }
        final state = await footballRepository.getCompetitionById(competitionId);
        final competition = state.data;
        if (competition != null) {
          nav.pushNamed(AppRoutes.competitionDetails, arguments: competition);
        } else {
          _openHome(nav);
        }
      case NotificationRoutingTarget.favorites:
        nav.pushNamedAndRemoveUntil(
          AppRoutes.mainNavigation,
          (route) => false,
        );
      case NotificationRoutingTarget.home:
        _openHome(nav);
    }
  }

  NotificationRoutingTarget resolveTarget(NotificationTapIntent intent) {
    switch (intent.type.canonical) {
      case NotificationType.goalScored:
      case NotificationType.matchStarted:
      case NotificationType.redCard:
      case NotificationType.matchFinished:
      case NotificationType.favoriteMatchUpdate:
        if (intent.hasMatchTarget) {
          return NotificationRoutingTarget.matchDetails;
        }
        return NotificationRoutingTarget.home;
      case NotificationType.favoriteTeamUpdate:
        if (intent.hasTeamTarget) {
          return NotificationRoutingTarget.favorites;
        }
        return NotificationRoutingTarget.home;
      case NotificationType.favoriteCompetitionUpdate:
        if (intent.hasCompetitionTarget) {
          return NotificationRoutingTarget.competitionDetails;
        }
        return NotificationRoutingTarget.home;
      default:
        return NotificationRoutingTarget.home;
    }
  }

  void _openHome(NavigatorState nav) {
    nav.pushNamedAndRemoveUntil(
      AppRoutes.mainNavigation,
      (route) => false,
    );
  }
}

enum NotificationRoutingTarget {
  home,
  matchDetails,
  competitionDetails,
  favorites,
}
