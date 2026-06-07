import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_cache_policy.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_production_guidance.dart';
import 'package:kickora/core/network/api_request_coordinator.dart';

void main() {
  group('ApiCachePolicy TTLs', () {
    test('live matches 30–60 seconds', () {
      expect(ApiCachePolicy.liveMatches.inSeconds, inInclusiveRange(30, 60));
    });

    test('today and upcoming five minutes', () {
      expect(ApiCachePolicy.todayMatches, const Duration(minutes: 5));
      expect(ApiCachePolicy.fixturesUpcoming, const Duration(minutes: 5));
    });

    test('finished ten minutes', () {
      expect(ApiCachePolicy.fixturesFinished, const Duration(minutes: 10));
    });

    test('stable data twenty-four hours', () {
      expect(ApiCachePolicy.competitions, const Duration(hours: 24));
      expect(ApiCachePolicy.teams, const Duration(hours: 24));
      expect(ApiCachePolicy.playerProfile, const Duration(hours: 24));
    });

    test('standings ten–thirty minutes', () {
      expect(ApiCachePolicy.standings.inMinutes, inInclusiveRange(10, 30));
    });

    test('match details and sub-resources two minutes', () {
      expect(ApiCachePolicy.matchDetails, const Duration(minutes: 2));
      expect(ApiCachePolicy.matchEvents, const Duration(minutes: 2));
      expect(ApiCachePolicy.matchStatistics, const Duration(minutes: 2));
      expect(ApiCachePolicy.matchLineups, const Duration(minutes: 2));
    });
  });

  group('ApiProductionGuidance', () {
    test('directApi dev-only warning text', () {
      expect(
        ApiProductionGuidance.directApiDevOnlyWarning,
        contains('backendProxy'),
      );
      expect(
        ApiProductionGuidance.directApiDevOnlyWarning,
        contains('development only'),
      );
    });

    test('backend proxy remains default production mode', () {
      expect(ApiConstants.isMock, isFalse);
      expect(ApiConstants.isBackendProxy, isTrue);
      expect(ApiConstants.isDirectApi, isFalse);
      expect(ApiConstants.backendBaseUrl, ApiConstants.productionBackendUrl);
    });
  });

  group('ApiRequestCoordinator', () {
    test('deduplicates concurrent identical keys', () async {
      var calls = 0;
      final coordinator = ApiRequestCoordinator.instance;
      final futures = List.generate(
        3,
        (_) => coordinator.run('test-dedupe-key', () async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 42;
        }),
      );
      final results = await Future.wait(futures);
      expect(results, everyElement(42));
      expect(calls, 1);
    });
  });

  group('lazy loading', () {
    test('match list screens do not fetch events, stats, or lineups', () {
      final libDir = Directory('lib/screens');
      final forbidden = RegExp(
        r'getMatchEvents|getMatchStatistics|getMatchLineups|fetchMatchEvents|fetchMatchStatistics|fetchLineups',
      );
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('match_details_screen.dart')) continue;
        final content = entity.readAsStringSync();
        expect(
          forbidden.hasMatch(content),
          isFalse,
          reason: '${entity.path} must not load match detail sub-resources',
        );
      }
    });
  });
}
