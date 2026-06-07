import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/data/mock_data.dart';
import 'package:kickora/data/providers/mock_football_data_provider.dart';
import 'package:kickora/data/repositories/football_repository.dart';
import 'package:kickora/services/favorites_resolver.dart';

void main() {
  group('FavoritesResolver', () {
    late FootballRepository repository;
    late FavoritesResolver resolver;

    setUp(() {
      repository = FootballRepository(dataProvider: MockFootballDataProvider());
      resolver = FavoritesResolver(repository);
    });

    test('mock mode resolves mock competitions and matches by id', () async {
      final snapshot = await resolver.resolve(
        teamIds: const {1, 99},
        competitionIds: const {2, 999},
        matchIds: const {101, 9999},
      );

      expect(snapshot.competitions.map((c) => c.id), [2]);
      expect(snapshot.competitions.single.name, 'Premier League');
      expect(snapshot.matches.map((m) => m.id), [101]);
      expect(snapshot.teams.map((t) => t.id), [1]);
    });

    test('returns empty snapshot when no favorite ids', () async {
      final snapshot = await resolver.resolve(
        teamIds: const {},
        competitionIds: const {},
        matchIds: const {},
      );

      expect(snapshot.isEmpty, isTrue);
    });

    test('mock mode ignores unknown ids without error', () async {
      final snapshot = await resolver.resolve(
        teamIds: const {424242},
        competitionIds: const {424242},
        matchIds: const {424242},
      );

      expect(snapshot.isEmpty, isTrue);
    });

    test('mock favorites align with MockData catalogs', () async {
      final snapshot = await resolver.resolve(
        teamIds: MockData.teams.map((t) => t.id).toSet(),
        competitionIds: MockData.competitions.map((c) => c.id).toSet(),
        matchIds: MockData.matches().map((m) => m.id).toSet(),
      );

      expect(snapshot.teams.length, MockData.teams.length);
      expect(snapshot.competitions.length, MockData.competitions.length);
      expect(snapshot.matches.length, MockData.matches().length);
    });
  });
}
