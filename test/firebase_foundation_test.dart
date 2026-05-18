import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/firebase/analytics_service.dart';
import 'package:kickora/core/firebase/crashlytics_service.dart';
import 'package:kickora/core/firebase/firebase_features.dart';
import 'package:kickora/core/firebase/firebase_service.dart';

void main() {
  test('Firebase features off until core initializes', () {
    expect(FirebaseService.isInitialized, isFalse);
    expect(FirebaseFeatures.isConfigured, isFalse);
    expect(FirebaseFeatures.analyticsEnabled, isFalse);
    expect(FirebaseFeatures.crashlyticsEnabled, isFalse);
  });

  test('AnalyticsService is disabled without Firebase init', () async {
    final analytics = AnalyticsService.instance;
    expect(analytics.isEnabled, isFalse);

    await analytics.initialize();
    await analytics.logAppOpen();
    await analytics.logScreenView('home');
    await analytics.logMatchOpened(100);
    await analytics.logCompetitionOpened(1);
    await analytics.logFavoriteAdded('team', 7);
    await analytics.logSearch('secret query');

    expect(analytics.isEnabled, isFalse);
  });

  test('CrashlyticsService is disabled without Firebase init', () async {
    final crashlytics = CrashlyticsService.instance;
    expect(crashlytics.isEnabled, isFalse);

    await crashlytics.initialize();
    await crashlytics.recordError(Exception('test'), StackTrace.current);

    expect(crashlytics.isEnabled, isFalse);
  });
}
