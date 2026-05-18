import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kickora/services/favorite_manager.dart';
import 'package:kickora/services/favorites_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesService', () {
    test('persists teams, competitions, and matches across reload', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FavoritesService(prefs);
      await service.load();

      await service.addFavorite(FavoriteType.team, 7);
      await service.addFavorite(FavoriteType.competition, 39);
      await service.addFavorite(FavoriteType.match, 1001);

      expect(service.isFavorite(FavoriteType.team, 7), isTrue);
      expect(service.isFavorite(FavoriteType.competition, 39), isTrue);
      expect(service.isFavorite(FavoriteType.match, 1001), isTrue);
      expect(service.getFavorites(FavoriteType.team), {7});
      expect(service.getFavorites(FavoriteType.competition), {39});
      expect(service.getFavorites(FavoriteType.match), {1001});

      final reloaded = FavoritesService(prefs);
      await reloaded.load();
      expect(reloaded.isFavorite(FavoriteType.team, 7), isTrue);
      expect(reloaded.isFavorite(FavoriteType.competition, 39), isTrue);
      expect(reloaded.isFavorite(FavoriteType.match, 1001), isTrue);
    });

    test('toggleFavorite adds and removes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FavoritesService(prefs);
      await service.load();

      expect(await service.toggleFavorite(FavoriteType.team, 42), isTrue);
      expect(service.isFavorite(FavoriteType.team, 42), isTrue);

      expect(await service.toggleFavorite(FavoriteType.team, 42), isTrue);
      expect(service.isFavorite(FavoriteType.team, 42), isFalse);
    });

    test('subscription hooks fire on add and remove', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final added = <String>[];
      final removed = <String>[];
      final service = FavoritesService(
        prefs,
        hooks: FavoriteSubscriptionHooks(
          onFavoriteAdded: (type, id) async {
            added.add('${type.name}:$id');
          },
          onFavoriteRemoved: (type, id) async {
            removed.add('${type.name}:$id');
          },
        ),
      );
      await service.load();
      await service.addFavorite(FavoriteType.match, 55);
      await service.removeFavorite(FavoriteType.match, 55);

      expect(added, ['match:55']);
      expect(removed, ['match:55']);
    });

    test('FavoriteTopicNames match future FCM topics', () {
      expect(FavoriteTopicNames.team(7), 'team_7');
      expect(FavoriteTopicNames.competition(39), 'competition_39');
      expect(FavoriteTopicNames.match(1001), 'match_1001');
      expect(
        FavoriteTopicNames.forType(FavoriteType.competition, 2),
        'competition_2',
      );
    });
  });

  group('FavoriteManager', () {
    test('notifies listeners when favorite toggled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = FavoriteManager(prefs);
      var notifications = 0;
      manager.addListener(() => notifications++);

      await manager.load();
      await manager.toggleTeam(3);
      expect(manager.isTeamFavorite(3), isTrue);
      expect(notifications, greaterThan(0));

      final manager2 = FavoriteManager(prefs);
      await manager2.load();
      expect(manager2.isTeamFavorite(3), isTrue);
    });
  });
}
