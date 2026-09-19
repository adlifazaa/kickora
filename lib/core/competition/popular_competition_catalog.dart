import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import 'competition_name_normalizer.dart';

/// Popularity guidance for current club-football seasons.
///
/// Provider IDs are only those already verified in this repository's API-Football
/// tests and fixtures. Remaining competitions match by normalized aliases.
class PopularCompetitionCatalog {
  PopularCompetitionCatalog._();

  static const List<PopularCompetitionDefinition> ranked = [
    PopularCompetitionDefinition(
      rank: 1,
      key: 'uefa_champions_league',
      providerIds: {2},
      aliases: [
        'UEFA Champions League',
        'Champions League',
        'UCL',
        'دوري أبطال أوروبا',
        'دوري الابطال',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 2,
      key: 'premier_league',
      providerIds: {39},
      aliases: [
        'Premier League',
        'English Premier League',
        'EPL',
        'الدوري الإنجليزي',
        'الدوري الانجليزي الممتاز',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 3,
      key: 'la_liga',
      providerIds: {140},
      aliases: [
        'La Liga',
        'Primera Division',
        'Primera División',
        'Spanish La Liga',
        'الدوري الإسباني',
        'الليغا',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 4,
      key: 'saudi_pro_league',
      providerIds: {},
      aliases: [
        'Saudi Pro League',
        'Roshn Saudi League',
        'Saudi League',
        'الدوري السعودي',
        'دوري روشن',
        'دوري روشن السعودي',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 5,
      key: 'serie_a',
      providerIds: {},
      aliases: [
        'Serie A',
        'Italian Serie A',
        'الدوري الإيطالي',
        'سيري أ',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 6,
      key: 'bundesliga',
      providerIds: {},
      aliases: [
        'Bundesliga',
        'German Bundesliga',
        'الدوري الألماني',
        'بوندسليغا',
        'البوندسليجا',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 7,
      key: 'uefa_europa_league',
      providerIds: {},
      aliases: [
        'UEFA Europa League',
        'Europa League',
        'UEL',
        'الدوري الأوروبي',
        'يوروبا ليغ',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 8,
      key: 'ligue_1',
      providerIds: {},
      aliases: [
        'Ligue 1',
        'French Ligue 1',
        'الدوري الفرنسي',
        'ليغ 1',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 9,
      key: 'afc_champions_league_elite',
      providerIds: {},
      aliases: [
        'AFC Champions League Elite',
        'AFC Champions League',
        'Asian Champions League',
        'دوري أبطال آسيا',
        'دوري أبطال آسيا للنخبة',
      ],
    ),
    PopularCompetitionDefinition(
      rank: 10,
      key: 'uefa_conference_league',
      providerIds: {},
      aliases: [
        'UEFA Europa Conference League',
        'UEFA Conference League',
        'Conference League',
        'دوري المؤتمر الأوروبي',
        'دوري المؤتمر',
      ],
    ),
  ];

  static PopularCompetitionDefinition? matchCompetition(CompetitionModel competition) {
    return matchNameAndId(name: competition.name, id: competition.id);
  }

  static PopularCompetitionDefinition? matchMatch(MatchModel match) {
    return matchNameAndId(name: match.competition.name, id: match.competition.id);
  }

  static PopularCompetitionDefinition? matchNameAndId({
    required String name,
    int? id,
  }) {
    final normalized = CompetitionNameNormalizer.normalize(name);
    for (final definition in ranked) {
      if (definition.matchesNormalizedName(normalized)) {
        return definition;
      }
    }
    if (id != null && id > 0) {
      for (final definition in ranked) {
        if (definition.providerIds.contains(id)) {
          return definition;
        }
      }
    }
    return null;
  }

  static bool isPopular({required String name, int? id}) =>
      matchNameAndId(name: name, id: id) != null;

  static int popularityRank({required String name, int? id}) {
    return matchNameAndId(name: name, id: id)?.rank ?? 999;
  }

  static String dedupeKey(CompetitionModel competition) {
    final popular = matchCompetition(competition);
    if (popular != null) return popular.key;
    final normalized = CompetitionNameNormalizer.normalize(competition.name);
    if (normalized.isNotEmpty) return 'name:$normalized';
    if (competition.id > 0) return 'id:${competition.id}';
    return 'empty:${identityHashCode(competition)}';
  }
}

class PopularCompetitionDefinition {
  const PopularCompetitionDefinition({
    required this.rank,
    required this.key,
    required this.providerIds,
    required this.aliases,
  });

  final int rank;
  final String key;
  final Set<int> providerIds;
  final List<String> aliases;

  bool matchesNormalizedName(String normalizedName) {
    if (normalizedName.isEmpty) return false;
    for (final alias in aliases) {
      if (CompetitionNameNormalizer.normalize(alias) == normalizedName) {
        return true;
      }
    }
    return false;
  }
}
