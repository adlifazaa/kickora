import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/repositories/football_repository.dart';
import 'match_refresh_category.dart';
import 'match_refresh_config.dart';

/// Background polling for match feeds with lifecycle pause/resume.
///
/// Screens listen via [addListener] and reload quietly (no full-screen spinner).
class MatchRefreshService extends ChangeNotifier with WidgetsBindingObserver {
  MatchRefreshService(
    this._repository, {
    MatchRefreshConfig config = const MatchRefreshConfig(),
  }) : _config = config;

  final FootballRepository _repository;
  final MatchRefreshConfig _config;

  final Map<MatchRefreshCategory, Timer?> _timers = {};
  final Map<MatchRefreshCategory, Future<void>> _inFlight = {};
  final Map<MatchRefreshCategory, DateTime> _lastCompleted = {};

  bool _started = false;
  bool _paused = false;
  DateTime? _selectedDate;

  /// Last category refreshed (for listeners to filter work).
  MatchRefreshCategory? lastRefreshCategory;

  bool get isPaused => _paused;
  bool get isRunning => _started && !_paused;

  /// Optional date context from Matches tab.
  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    if (!_repository.usesLiveApi) {
      if (kDebugMode) {
        debugPrint('[Kickora Refresh] timers off (mock data mode)');
      }
      return;
    }
    _scheduleAll();
    unawaited(refresh(MatchRefreshCategory.live, reason: 'startup'));
  }

  void stop() {
    _cancelAllTimers();
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _paused = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        pause();
    }
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _cancelAllTimers();
    if (kDebugMode) {
      debugPrint('[Kickora Refresh] paused (background)');
    }
  }

  void resume() {
    if (!_started) return;
    if (!_paused) return;
    _paused = false;
    if (!_repository.usesLiveApi) return;
    _scheduleAll();
    unawaited(refresh(MatchRefreshCategory.live, reason: 'resume'));
    if (kDebugMode) {
      debugPrint('[Kickora Refresh] resumed (foreground)');
    }
  }

  /// Manual pull-to-refresh should call this with [force] true.
  Future<void> refresh(
    MatchRefreshCategory category, {
    bool force = false,
    String reason = 'manual',
  }) async {
    if (_paused && !force) return;
    if (!_repository.usesLiveApi) return;

    if (!force && !_canRefresh(category)) return;

    final existing = _inFlight[category];
    if (existing != null) return existing;

    final task = _runRefresh(category, reason: reason);
    _inFlight[category] = task;
    try {
      await task;
    } finally {
      _inFlight.remove(category);
    }
  }

  Future<void> refreshAll({bool force = false}) async {
    await Future.wait([
      refresh(MatchRefreshCategory.live, force: force),
      refresh(MatchRefreshCategory.upcoming, force: force),
      refresh(MatchRefreshCategory.finished, force: force),
      refresh(MatchRefreshCategory.all, force: force),
    ]);
  }

  bool _canRefresh(MatchRefreshCategory category) {
    final last = _lastCompleted[category];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _config.minGapBetweenSameCategory;
  }

  Future<void> _runRefresh(MatchRefreshCategory category, {required String reason}) async {
    final date = _selectedDate;
    try {
      switch (category) {
        case MatchRefreshCategory.live:
          await _repository.getLiveMatches(
            date: date,
            forceRefresh: true,
          );
        case MatchRefreshCategory.upcoming:
          await _repository.getUpcomingMatches(
            date: date,
            forceRefresh: true,
          );
        case MatchRefreshCategory.finished:
          await _repository.getFinishedMatches(
            date: date,
            forceRefresh: true,
          );
        case MatchRefreshCategory.all:
          await _repository.getMatches(
            date: date,
            forceRefresh: true,
          );
      }
      _lastCompleted[category] = DateTime.now();
      lastRefreshCategory = category;
      if (kDebugMode) {
        debugPrint('[Kickora Refresh] $category ($reason)');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Refresh] $category failed: $e');
      }
    }
  }

  void _scheduleAll() {
    _cancelAllTimers();
    for (final category in MatchRefreshCategory.values) {
      _timers[category] = Timer.periodic(
        _config.intervalFor(category),
        (_) => unawaited(refresh(category, reason: 'timer')),
      );
    }
  }

  void _cancelAllTimers() {
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
