import '../../data/models/competition_model.dart';

/// Country chips on the competitions screen — exact normalized token matching only.
class CompetitionCountryFilter {
  CompetitionCountryFilter._();

  static const Set<String> _europeCountries = {
    'europe',
    'world',
    'international',
  };

  static const Set<String> _europeNameTokens = {
    'uefa',
    'fifa',
  };

  static bool matches(CompetitionModel competition, String category) {
    switch (category) {
      case 'all':
      case 'favorites':
        return true;
      case 'europe':
        return _isEuropean(competition);
      case 'england':
        return _isEngland(competition);
      case 'spain':
        return _isSpain(competition);
      case 'italy':
        return _isItaly(competition);
      case 'germany':
        return _isGermany(competition);
      default:
        return _normalize(competition.region) == _normalize(category);
    }
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static List<String> _nameTokens(String name) => name
      .trim()
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  static bool _isEngland(CompetitionModel c) =>
      _normalize(c.region) == 'england';

  static bool _isSpain(CompetitionModel c) => _normalize(c.region) == 'spain';

  static bool _isItaly(CompetitionModel c) => _normalize(c.region) == 'italy';

  static bool _isGermany(CompetitionModel c) =>
      _normalize(c.region) == 'germany';

  static bool _isEuropean(CompetitionModel c) {
    if (_isEngland(c) || _isSpain(c) || _isItaly(c) || _isGermany(c)) {
      return false;
    }
    final country = _normalize(c.region);
    if (_europeCountries.contains(country)) return true;
    return _nameTokens(c.name).any(_europeNameTokens.contains);
  }
}
