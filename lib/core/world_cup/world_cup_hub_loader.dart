import 'package:flutter/foundation.dart';



import '../../core/constants/world_cup_config.dart';

import '../../data/models/match_model.dart';

import '../../data/models/news_article_model.dart';

import '../../data/models/player_model.dart';

import '../../data/models/standing_group_model.dart';

import '../../data/models/team_model.dart';

import '../../data/repositories/football_repository.dart';

import 'world_cup_debug_log.dart';



/// Lazy-loaded data for [WorldCupHubScreen] — no work until hub opens.

class WorldCupHubLoader extends ChangeNotifier {

  WorldCupHubLoader(this._repo);



  final FootballRepository _repo;

  final int competitionId = WorldCupConfig.competitionId;



  bool overviewLoading = false;

  bool scheduleLoading = false;

  bool groupsLoading = false;

  bool teamsLoading = false;

  bool scorersLoading = false;

  bool newsLoading = false;



  bool overviewLoaded = false;

  bool scheduleLoaded = false;

  bool groupsLoaded = false;

  bool teamsLoaded = false;

  bool scorersLoaded = false;

  bool newsLoaded = false;



  List<MatchModel> matches = [];

  List<StandingGroupModel> groups = [];

  List<TeamModel> teams = [];

  List<PlayerModel> scorers = [];

  WorldCupNewsResult newsResult = WorldCupNewsResult.notConfigured;

  String? newsError;

  DateTime? lastUpdated;



  MatchModel? get featuredMatch {

    for (final m in matches) {

      if (m.status == MatchStatus.live) return m;

    }

    final upcoming = matches

        .where((m) => m.status == MatchStatus.upcoming)

        .toList()

      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcoming.isNotEmpty) return upcoming.first;

    final finished = matches

        .where((m) => m.status == MatchStatus.finished)

        .toList()

      ..sort((a, b) => b.date.compareTo(a.date));

    if (finished.isNotEmpty) return finished.first;

    return null;

  }



  /// Overview reads fixtures already loaded by [loadSchedule] — no extra API calls.

  Future<void> loadOverview() async {

    if (overviewLoaded || overviewLoading) return;

    overviewLoading = true;

    notifyListeners();

    try {

      await _repo.ensureWorldCupReady();

      if (!scheduleLoaded && !scheduleLoading) {

        await loadSchedule();

      }

      overviewLoaded = true;

      lastUpdated = DateTime.now();

    } finally {

      overviewLoading = false;

      notifyListeners();

    }

  }



  /// One competition-level fixtures call (cached 15m backend / memory).

  Future<void> loadSchedule({bool forceRefresh = false}) async {

    if (!forceRefresh && (scheduleLoaded || scheduleLoading)) return;

    scheduleLoading = true;

    notifyListeners();

    try {

      await _repo.ensureWorldCupReady();

      final state = await _repo.getCompetitionMatches(

        competitionId,

        season: WorldCupConfig.season,

        forceRefresh: forceRefresh,

      );

      if (!state.hasError && state.data != null) {

        matches = _mergeMatches([...matches, ...state.data!]);

      }

      WorldCupDebugLog.fixtureRounds(matches);

      scheduleLoaded = true;

      lastUpdated = DateTime.now();

    } finally {

      scheduleLoading = false;

      notifyListeners();

    }

  }



  Future<void> loadGroups() async {

    if (groupsLoaded || groupsLoading) return;

    groupsLoading = true;

    notifyListeners();

    try {

      final state = await _repo.getStandingGroups(leagueId: competitionId);

      groups = state.data ?? [];

      groupsLoaded = true;

    } finally {

      groupsLoading = false;

      notifyListeners();

    }

  }



  Future<void> loadTeams() async {

    if (teamsLoaded || teamsLoading) return;

    teamsLoading = true;

    notifyListeners();

    try {

      await _repo.ensureWorldCupReady();

      if (matches.isEmpty && !scheduleLoaded) {

        await loadSchedule();

      }

      if (groups.isEmpty && !groupsLoaded) {

        await loadGroups();

      }

      final state = await _repo.getCompetitionTeams(competitionId);

      teams = state.data ?? [];

      if (teams.isEmpty) {

        teams = _teamsFromGroupsAndMatches();

      }

      teamsLoaded = true;

    } finally {

      teamsLoading = false;

      notifyListeners();

    }

  }



  Future<void> loadNews({bool force = false}) async {

    if (!force && (newsLoaded || newsLoading)) return;

    newsLoading = true;

    newsError = null;

    notifyListeners();

    try {

      final state = await _repo.getWorldCupNews(forceRefresh: force);

      if (state.hasError) {

        newsError = state.errorMessage;

        newsResult = WorldCupNewsResult.notConfigured;

      } else {

        newsResult = state.data ?? WorldCupNewsResult.notConfigured;

      }

      newsLoaded = true;

    } finally {

      newsLoading = false;

      notifyListeners();

    }

  }



  Future<void> refreshNews() async {

    newsLoaded = false;

    await loadNews(force: true);

  }



  Future<void> loadScorers() async {

    if (scorersLoaded || scorersLoading) return;

    scorersLoading = true;

    notifyListeners();

    try {

      await _repo.ensureWorldCupReady();

      final state = await _repo.getTopScorers(competitionId);

      scorers = state.data ?? [];

      scorersLoaded = true;

    } finally {

      scorersLoading = false;

      notifyListeners();

    }

  }



  List<TeamModel> _teamsFromGroupsAndMatches() {

    final byId = <int, TeamModel>{};

    for (final g in groups) {

      for (final row in g.rows) {

        byId[row.team.id] = row.team;

      }

    }

    for (final m in matches) {

      byId[m.homeTeam.id] = m.homeTeam;

      byId[m.awayTeam.id] = m.awayTeam;

    }

    final list = byId.values.toList()

      ..sort((a, b) => a.name.compareTo(b.name));

    return list;

  }



  String? groupNameForTeam(int teamId) {

    for (final g in groups) {

      if (g.rows.any((r) => r.team.id == teamId)) return g.name;

    }

    return null;

  }



  Future<void> refreshAll() async {

    overviewLoaded = false;

    scheduleLoaded = false;

    groupsLoaded = false;

    teamsLoaded = false;

    scorersLoaded = false;

    newsLoaded = false;

    matches = [];

    groups = [];

    teams = [];

    scorers = [];

    newsResult = WorldCupNewsResult.notConfigured;

    newsError = null;

    await loadSchedule(forceRefresh: true);

    overviewLoaded = true;

  }



  List<MatchModel> matchesForTeam(int teamId) {

    return matches

        .where((m) => m.homeTeam.id == teamId || m.awayTeam.id == teamId)

        .toList()

      ..sort((a, b) => a.date.compareTo(b.date));

  }



  StandingGroupModel? groupForTeam(int teamId) {

    for (final g in groups) {

      if (g.rows.any((r) => r.team.id == teamId)) return g;

    }

    return null;

  }



  static List<MatchModel> _mergeMatches(List<MatchModel> raw) {

    final byId = <int, MatchModel>{};

    for (final m in raw) {

      byId[m.id] = m;

    }

    final merged = byId.values.toList()

      ..sort((a, b) {

        final aw = a.status == MatchStatus.live

            ? 0

            : a.status == MatchStatus.upcoming

                ? 1

                : 2;

        final bw = b.status == MatchStatus.live

            ? 0

            : b.status == MatchStatus.upcoming

                ? 1

                : 2;

        if (aw != bw) return aw.compareTo(bw);

        return a.date.compareTo(b.date);

      });

    return merged;

  }

}


