import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/competition/competition_country_filter.dart';
import 'package:kickora/data/models/competition_model.dart';

void main() {
  test('domestic filters use exact normalized country names only', () {
    const england = CompetitionModel(
      id: 39,
      name: 'Premier League',
      region: 'England',
      logo: '',
    );
    const ukLeague = CompetitionModel(
      id: 40,
      name: 'Championship',
      region: 'United Kingdom',
      logo: '',
    );
    const spain = CompetitionModel(
      id: 140,
      name: 'La Liga',
      region: 'Spain',
      logo: '',
    );

    expect(CompetitionCountryFilter.matches(england, 'england'), isTrue);
    expect(CompetitionCountryFilter.matches(ukLeague, 'england'), isFalse);
    expect(CompetitionCountryFilter.matches(spain, 'england'), isFalse);
    expect(CompetitionCountryFilter.matches(spain, 'spain'), isTrue);
  });

  test('europe filter uses exact country or uefa/fifa name tokens', () {
    const ucl = CompetitionModel(
      id: 2,
      name: 'UEFA Champions League',
      region: 'World',
      logo: '',
    );
    const fifa = CompetitionModel(
      id: 1,
      name: 'FIFA World Cup',
      region: 'International',
      logo: '',
    );
    const england = CompetitionModel(
      id: 39,
      name: 'Premier League',
      region: 'England',
      logo: '',
    );

    expect(CompetitionCountryFilter.matches(ucl, 'europe'), isTrue);
    expect(CompetitionCountryFilter.matches(fifa, 'europe'), isTrue);
    expect(CompetitionCountryFilter.matches(england, 'europe'), isFalse);
  });
}
