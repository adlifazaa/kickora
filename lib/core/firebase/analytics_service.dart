import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> logAppOpen() => _run('app_open', () async {
        await _analytics!.logAppOpen();
      });

  Future<void> logScreenView(String screenName) => _run('screen_view', () async {
        final name = screenName.trim();
        if (name.isEmpty) return;
        await _analytics!.logScreenView(screenName: name);
      });

  Future<void> logMatchOpened(int matchId) => _run('match_opened', () async {
        if (matchId <= 0) return;
        await _analytics!.logEvent(
          name: 'match_opened',
          parameters: {'match_id': matchId},
        );
      });

  Future<void> logCompetitionOpened(int competitionId) =>
      _run('competition_opened', () async {
        if (competitionId <= 0) return;
        await _analytics!.logEvent(
          name: 'competition_opened',
          parameters: {'competition_id': competitionId},
        );
      });

  Future<void> logFavoriteAdded(String type, int id) =>
      _run('favorite_added', () async {
        final kind = type.trim().toLowerCase();
        if (kind.isEmpty || id <= 0) return;
        await _analytics!.logEvent(
          name: 'favorite_added',
          parameters: {'favorite_type': kind, 'item_id': id},
        );
      });

  /// Logs search activity using query length only (no query text — privacy safe).
  Future<void> logSearch(String query) => _run('search', () async {
        final length = query.trim().length;
        if (length == 0) return;
        await _analytics!.logEvent(
          name: 'search',
          parameters: {'query_length': length},
        );
      });

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
