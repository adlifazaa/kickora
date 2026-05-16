import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../mock_data.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';

/// Remote football data access. When no API key is configured, methods throw
/// [ApiException.notConfigured] so [FootballRepository] can fall back to mock data.
class FootballApiService {
  FootballApiService({
    ApiClient? client,
    this.provider = ApiProvider.mock,
    String? apiKey,
  }) : _client = client ??
            ApiClient(
              apiKey: apiKey ?? ApiConstants.apiKey,
            );

  final ApiClient _client;
  final ApiProvider provider;

  bool get isLive => _client.isConfigured && provider != ApiProvider.mock;

  // --- Matches ---

  Future<List<MatchModel>> fetchLiveMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _fetchMatchesByStatus(MatchStatus.live, date: date, competitionId: competitionId);

  Future<List<MatchModel>> fetchUpcomingMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _fetchMatchesByStatus(
        MatchStatus.upcoming,
        date: date,
        competitionId: competitionId,
      );

  Future<List<MatchModel>> fetchFinishedMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _fetchMatchesByStatus(
        MatchStatus.finished,
        date: date,
        competitionId: competitionId,
      );

  Future<List<MatchModel>> fetchMatches({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
  }) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): Map query params to provider (live/upcoming/finished/date/league).
    final response = await _client.get(
      ApiConstants.matches,
      queryParameters: {
        if (date != null) 'date': _formatDate(date),
        if (competitionId != null) 'league': '$competitionId',
        if (status != null) 'status': status.name,
      },
    );
    return _parseMatchList(response);
  }

  Future<MatchModel?> fetchMatchById(int id) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /fixtures/{id}
    final response = await _client.get(
      ApiConstants.fill(ApiConstants.matchById, {'id': id}),
    );
    final list = _parseMatchList(response);
    return list.isEmpty ? null : list.first;
  }

  Future<List<MatchEventModel>> fetchMatchEvents(int matchId) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /fixtures/events?fixture={matchId}
    final response = await _client.get(
      ApiConstants.matchEvents,
      queryParameters: {'fixture': '$matchId'},
    );
    final raw = response['response'] as List? ?? response['events'] as List? ?? [];
    return raw
        .map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /fixtures/statistics?fixture={matchId}
    final response = await _client.get(
      ApiConstants.matchStatistics,
      queryParameters: {'fixture': '$matchId'},
    );
    final raw = response['response'] as List? ?? response['stats'] as List? ?? [];
    return raw
        .map((e) => MatchStatisticModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({LineupModel? home, LineupModel? away})> fetchMatchLineups(
    int matchId,
  ) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /fixtures/lineups?fixture={matchId}
    await _client.get(
      ApiConstants.matchLineups,
      queryParameters: {'fixture': '$matchId'},
    );
    return (home: null, away: null);
  }

  Future<FormationModel?> fetchFormation(int matchId, {required bool isHome}) async {
    final lineups = await fetchMatchLineups(matchId);
    final lineup = isHome ? lineups.home : lineups.away;
    return lineup?.resolvedFormation;
  }

  // --- Competitions / teams / standings ---

  Future<List<CompetitionModel>> fetchCompetitions() async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /leagues?season=...
    final response = await _client.get(ApiConstants.competitions);
    final raw = response['response'] as List? ?? [];
    return raw
        .map((e) => CompetitionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CompetitionModel?> fetchCompetitionById(int id) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    final response = await _client.get(
      ApiConstants.fill(ApiConstants.competitionById, {'id': id}),
    );
    final raw = response['response'] as Map<String, dynamic>?;
    return raw == null ? null : CompetitionModel.fromJson(raw);
  }

  Future<List<TeamModel>> fetchTeams({int? competitionId}) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    final response = await _client.get(
      ApiConstants.teams,
      queryParameters: {
        if (competitionId != null) 'league': '$competitionId',
      },
    );
    final raw = response['response'] as List? ?? [];
    return raw
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StandingModel>> fetchStandings({int? leagueId}) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    final response = await _client.get(
      ApiConstants.standings,
      queryParameters: {
        if (leagueId != null) 'league': '$leagueId',
      },
    );
    final raw = response['response'] as List? ?? [];
    return raw
        .map((e) => StandingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlayerModel>> fetchTopScorers(int competitionId) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /players/topscorers?league={competitionId}
    throw const ApiException(
      'Top scorers endpoint not mapped yet.',
      code: 'not_implemented',
    );
  }

  Future<PlayerModel?> fetchPlayerById(int id) async {
    await _simulateLatency();
    if (!isLive) throw const ApiException.notConfigured();

    // TODO(api): GET /players?id={id}
    throw const ApiException(
      'Player endpoint not mapped yet.',
      code: 'not_implemented',
    );
  }

  /// Hook to flip provider at runtime once credentials are available.
  Future<void> configureRealProvider({
    String? baseUrl,
    String? apiKey,
    ApiProvider? provider,
  }) async {
    // TODO(api): Rebuild ApiClient with new baseUrl/apiKey and set provider.
  }

  Future<List<MatchModel>> _fetchMatchesByStatus(
    MatchStatus status, {
    DateTime? date,
    int? competitionId,
  }) async {
    final all = await fetchMatches(
      date: date,
      competitionId: competitionId,
      status: status,
    );
    return all.where((m) => m.status == status).toList();
  }

  List<MatchModel> _parseMatchList(Map<String, dynamic> response) {
    final raw = response['response'] as List? ?? response['matches'] as List? ?? [];
    return raw
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 120));

  /// Dev helper: returns mock slice when service is in mock mode (tests).
  List<MatchModel> debugMockMatches() => MockData.matches();
}
