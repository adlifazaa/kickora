import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../meta/meta_app_events_service.dart';
import 'firebase_debug_log.dart';
import 'firebase_features.dart';

/// Safe Firebase Analytics facade (no-op until [FirebaseFeatures.analyticsEnabled]).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  bool get isEnabled => FirebaseFeatures.analyticsEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isEnabled) {
      FirebaseDebugLog.analytics(enabled: false);
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      FirebaseDebugLog.analytics(enabled: true);
    } catch (e) {
      _analytics = null;
      FirebaseDebugLog.analytics(enabled: false, message: 'init skipped');
      if (kDebugMode) {
        debugPrint('[Kickora Analytics] init error (swallowed): $e');
      }
    }
  }

  Future<void> logAppOpen() async {
    await _run('app_open', () async {
      await _analytics!.logAppOpen();
    });
    unawaited(MetaAppEventsService.instance.logAppActivate());
  }

  Future<void> logScreenView(String screenName) => _run('screen_view', () async {
        final name = screenName.trim();
        if (name.isEmpty) return;
        await _analytics!.logScreenView(screenName: name);
      });

  Future<void> logMatchOpened(int matchId) async {
    await _run('match_opened', () async {
      if (matchId <= 0) return;
      await _analytics!.logEvent(
        name: 'match_opened',
        parameters: {'match_id': matchId},
      );
    });
    unawaited(MetaAppEventsService.instance.logMatchOpened(matchId));
  }

  Future<void> logCompetitionOpened(int competitionId) =>
      _run('competition_opened', () async {
        if (competitionId <= 0) return;
        await _analytics!.logEvent(
          name: 'competition_opened',
          parameters: {'competition_id': competitionId},
        );
      });

  Future<void> logFavoriteAdded(String type, int id) async {
    await _run('favorite_added', () async {
      final kind = type.trim().toLowerCase();
      if (kind.isEmpty || id <= 0) return;
      await _analytics!.logEvent(
        name: 'favorite_added',
        parameters: {'favorite_type': kind, 'item_id': id},
      );
    });
    unawaited(MetaAppEventsService.instance.logFavoriteAdded(type, id));
  }

  /// Logs search activity using query length only (no query text — privacy safe).
  Future<void> logPremiumScreenOpened() =>
      _run('premium_screen_opened', () async {
        await _analytics!.logEvent(name: 'premium_screen_opened');
      });

  Future<void> logNotificationEnabled() async {
    await _run('notification_enabled', () async {
      await _analytics!.logEvent(name: 'notification_enabled');
    });
    unawaited(MetaAppEventsService.instance.logNotificationEnabled());
  }

  Future<void> logSearch(String query) async {
    final length = query.trim().length;
    await _run('search', () async {
      if (length == 0) return;
      await _analytics!.logEvent(
        name: 'search',
        parameters: {'query_length': length},
      );
    });
    unawaited(MetaAppEventsService.instance.logSearch(length));
  }

  Future<void> _run(String debugName, Future<void> Function() action) async {
    if (!isEnabled || _analytics == null) return;
    try {
      await action();
      FirebaseDebugLog.analyticsEvent(debugName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Analytics] $debugName skipped: $e');
      }
    }
  }
}
