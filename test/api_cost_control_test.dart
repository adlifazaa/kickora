import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_cache_policy.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/core/refresh/match_refresh_config.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_production_guidance.dart';
import 'package:kickora/core/network/api_request_coordinator.dart';

void main() {
  group('ApiCachePolicy TTLs', () {
    test('live matches 30–60 seconds', () {
      expect(ApiCachePolicy.liveMatches.inSeconds, inInclusiveRange(30, 60));
    });

    test('today and upcoming 5–15 minutes', () {
      expect(ApiCachePolicy.todayMatches.inMinutes, inInclusiveRange(5, 15));
      expect(ApiCachePolicy.fixturesUpcoming.inMinutes, inInclusiveRange(5, 15));
    });

    test('finished six to twenty-four hours', () {
      expect(ApiCachePolicy.fixturesFinished.inHours, inInclusiveRange(6, 24));
    });

    test('stable data twenty-four hours', () {
      expect(ApiCachePolicy.competitions, const Duration(hours: 24));
      expect(ApiCachePolicy.teams, const Duration(hours: 24));
      expect(ApiCachePolicy.playerProfile, const Duration(hours: 24));
    });

    test('standings and scorers ten–thirty minutes', () {
      expect(ApiCachePolicy.standings.inMinutes, inInclusiveRange(10, 30));
      expect(ApiCachePolicy.topScorers.inMinutes, inInclusiveRange(10, 30));
    });

    test('competition fixtures cached fifteen minutes', () {
      expect(ApiCachePolicy.competitionFixtures, const Duration(minutes: 15));
    });

    test('match details and sub-resources 30–60 seconds live default', () {
      expect(ApiCachePolicy.matchDetails.inSeconds, inInclusiveRange(30, 60));
      expect(ApiCachePolicy.matchEvents.inSeconds, inInclusiveRange(30, 60));
      expect(ApiCachePolicy.matchStatistics.inSeconds, inInclusiveRange(30, 60));
      expect(ApiCachePolicy.matchLineups.inSeconds, inInclusiveRange(30, 60));
    });

    test('match detail resource TTL varies by fixture status', () {
      expect(
        ApiCachePolicy.matchDetailResourceTtl(MatchStatus.finished),
        const Duration(hours: 24),
      );
      expect(
        ApiCachePolicy.matchDetailResourceTtl(MatchStatus.upcoming),
        const Duration(hours: 1),
      );
      expect(
        ApiCachePolicy.matchDetailResourceTtl(MatchStatus.live).inSeconds,
        inInclusiveRange(30, 60),
      );
    });

    test('all matches refresh interval at least ten minutes', () {
      expect(
        const MatchRefreshConfig().allMatchesInterval.inMinutes,
        greaterThanOrEqualTo(10),
      );
    });
  });

  group('today matches cost control', () {
    test('home screen uses one global getMatches call (no per-competition today)', () {
      final home = File('lib/screens/home_screen.dart').readAsStringSync();
      expect(
        RegExp(r"getMatches\(\s*date:\s*today,\s*competitionId:").hasMatch(home),
        isFalse,
      );
      expect(
        RegExp(r'getMatches\(date:\s*today').allMatches(home).length,
        lessThanOrEqualTo(1),
      );
    });

    test('competition details does not call getMatches for today', () {
      final details =
          File('lib/screens/competition_details_screen.dart').readAsStringSync();
      expect(details.contains('getMatches(date: today'), isFalse);
    });

    test('backend proxy today fetch uses canonical unscoped route', () {
      final proxy =
          File('lib/data/services/backend_proxy/backend_proxy_service.dart')
              .readAsStringSync();
      expect(
        proxy.contains('BackendProxyRoutes.matchesToday(date: date)'),
        isTrue,
      );
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
