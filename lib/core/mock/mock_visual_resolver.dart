import 'mock_competition_key.dart';
import 'mock_flag_key.dart';

/// Resolves mock/demo teams and competitions to local flag or badge visuals.
class MockVisualResolver {
  MockVisualResolver._();

  static const String assetPrefix = 'asset:';

  static bool isBundledAssetPath(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith(assetPrefix) ||
        value.startsWith('assets/mock/');
  }

  static String? bundledAssetPath(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith(assetPrefix)) {
      return value.substring(assetPrefix.length);
    }
    if (value.startsWith('assets/mock/')) return value;
    return null;
  }

  static MockFlagKey? flagKeyForTeam({
    String? shortName,
    String? countryName,
    String? countryCode,
    int? teamId,
  }) {
    final code = _normalize(
      countryCode ?? shortName ?? '',
    );
    if (code.isNotEmpty) {
      final byCode = _flagByIso(code);
      if (byCode != null) return byCode;
    }

    final nameKey = _normalize(countryName ?? '');
    if (nameKey.isNotEmpty) {
      final byName = _flagByCountryName(nameKey);
      if (byName != null) return byName;
    }

    return _flagByTeamId(teamId);
  }

  static MockCompetitionKey? competitionKey(String? logoOrCode) {
    final code = _normalize(logoOrCode ?? '');
    return _competitionKeyFromCode(code);
  }

  /// Mock league badge when [logo] is not a network URL (demo / APK without API key).
  static MockCompetitionKey? competitionKeyFor({
    required String logo,
    String? name,
    int? id,
  }) {
    if (_isHttpUrl(logo)) return null;

    final fromLogo = competitionKey(logo);
    if (fromLogo != null) return fromLogo;

    final fromName = competitionKeyByName(name);
    if (fromName != null) return fromName;

    return competitionKeyById(id);
  }

  static MockCompetitionKey? competitionKeyByName(String? name) {
    final n = _normalize(name ?? '');
    if (n.isEmpty) return null;
    if (n.contains('WORLDCUP') || n == 'WC' || n.contains('FIFA')) {
      return MockCompetitionKey.worldCup;
    }
    if (n.contains('PREMIER') || n.contains('EPL')) {
      return MockCompetitionKey.premierLeague;
    }
    if (n.contains('LALIGA') || n.contains('SPANISH')) {
      return MockCompetitionKey.laLiga;
    }
    if (n.contains('SERIE') || n.contains('SERIA')) {
      return MockCompetitionKey.serieA;
    }
    if (n.contains('BUNDES')) {
      return MockCompetitionKey.bundesliga;
    }
    return null;
  }

  static MockCompetitionKey? competitionKeyById(int? id) {
    return switch (id) {
      1 => MockCompetitionKey.worldCup,
      2 => MockCompetitionKey.premierLeague,
      3 => MockCompetitionKey.laLiga,
      4 => MockCompetitionKey.serieA,
      5 => MockCompetitionKey.bundesliga,
      _ => null,
    };
  }

  static MockCompetitionKey? _competitionKeyFromCode(String code) {
    if (code.isEmpty) return null;
    return switch (code) {
      'WC' || 'WORLD' || 'WORLDCUP' || 'INT' => MockCompetitionKey.worldCup,
      'PL' || 'EPL' || 'PREMIER' || 'PREMIERLEAGUE' => MockCompetitionKey.premierLeague,
      'LL' || 'LALIGA' => MockCompetitionKey.laLiga,
      'SA' || 'SERIE' || 'SERIEA' => MockCompetitionKey.serieA,
      'BL' || 'BUNDES' || 'BUNDESLIGA' => MockCompetitionKey.bundesliga,
      _ => null,
    };
  }

  static bool _isHttpUrl(String value) {
    final t = value.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static MockFlagKey? _flagByIso(String code) {
    if (code.length == 2) {
      return switch (code) {
        'AR' => MockFlagKey.argentina,
        'BR' => MockFlagKey.brazil,
        'FR' => MockFlagKey.france,
        'ES' => MockFlagKey.spain,
        'MA' => MockFlagKey.morocco,
        'DE' => MockFlagKey.germany,
        'EN' || 'GB' => MockFlagKey.england,
        'IT' => MockFlagKey.italy,
        _ => null,
      };
    }
    return switch (code) {
      'ARG' => MockFlagKey.argentina,
      'BRA' => MockFlagKey.brazil,
      'FRA' => MockFlagKey.france,
      'ESP' => MockFlagKey.spain,
      'MAR' => MockFlagKey.morocco,
      'GER' => MockFlagKey.germany,
      'ENG' => MockFlagKey.england,
      'ITA' => MockFlagKey.italy,
      _ => null,
    };
  }

  static MockFlagKey? _flagByCountryName(String key) {
    if (key.contains('ARGENT')) return MockFlagKey.argentina;
    if (key.contains('BRAZIL')) return MockFlagKey.brazil;
    if (key.contains('FRANCE')) return MockFlagKey.france;
    if (key.contains('SPAIN')) return MockFlagKey.spain;
    if (key.contains('MOROCC')) return MockFlagKey.morocco;
    if (key.contains('GERMAN')) return MockFlagKey.germany;
    if (key.contains('ENGLAND')) return MockFlagKey.england;
    if (key.contains('ITALY')) return MockFlagKey.italy;
    return null;
  }

  static MockFlagKey? _flagByTeamId(int? id) {
    return switch (id) {
      1 => MockFlagKey.argentina,
      2 => MockFlagKey.brazil,
      3 => MockFlagKey.france,
      4 => MockFlagKey.spain,
      5 => MockFlagKey.morocco,
      6 => MockFlagKey.germany,
      _ => null,
    };
  }
}
