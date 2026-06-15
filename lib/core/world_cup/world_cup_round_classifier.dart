import '../constants/world_cup_config.dart';
import '../../data/models/match_model.dart';

/// Maps API-Football `league.round` strings to World Cup stages (robust matching).
class WorldCupRoundClassifier {
  WorldCupRoundClassifier._();

  static final _groupLetter = RegExp(r'group\s*[a-l]\b', caseSensitive: false);

  static bool isGroupStageMatch(MatchModel match) =>
      isGroupStageRound(match.round, matchDate: match.date);

  /// True when [round] or [matchDate] indicates a group-stage fixture.
  static bool isGroupStageRound(String round, {DateTime? matchDate}) {
    final normalized = _normalize(round);
    if (normalized.isNotEmpty) {
      if (_isKnockoutRound(normalized)) return false;
      if (_isExplicitGroupRound(normalized)) return true;
    }
    if (matchDate != null && _isGroupStageDate(matchDate)) {
      return true;
    }
    return false;
  }

  static String sectionIdForRound(String round, {DateTime? matchDate}) {
    final normalized = _normalize(round);
    if (normalized.isNotEmpty) {
      if (_isKnockoutRound(normalized)) {
        if (normalized.contains('round of 32') || normalized.contains('1/16')) {
          return 'r32';
        }
        if (normalized.contains('round of 16') || normalized.contains('1/8')) {
          return 'r16';
        }
        if (normalized.contains('quarter') || normalized.contains('ربع')) {
          return 'quarter';
        }
        if (normalized.contains('semi') || normalized.contains('نصف')) {
          return 'semi';
        }
        if (normalized.contains('3rd') ||
            normalized.contains('third') ||
            normalized.contains('third place')) {
          return 'third';
        }
        if (normalized.contains('final') || normalized.contains('نهائي')) {
          return 'final';
        }
      }
      if (_isExplicitGroupRound(normalized)) return 'group';
    }
    if (matchDate != null && _isGroupStageDate(matchDate)) return 'group';
    return 'other';
  }

  static String _normalize(String round) => round.trim().toLowerCase();

  static bool _isKnockoutRound(String normalized) {
    if (normalized.contains('round of 32') ||
        normalized.contains('1/16 final') ||
        normalized.contains('round of 16') ||
        normalized.contains('1/8 final') ||
        normalized.contains('quarter') ||
        normalized.contains('semi') ||
        normalized.contains('3rd place') ||
        normalized.contains('third place') ||
        normalized.contains('3rd') ||
        normalized.contains('third') ||
        normalized.contains('ربع') ||
        normalized.contains('نصف')) {
      return true;
    }
    if (normalized.contains('final') &&
        !normalized.contains('group') &&
        !normalized.contains('regular season')) {
      return true;
    }
    return false;
  }

  static bool _isExplicitGroupRound(String normalized) {
    if (normalized.contains('group stage') ||
        normalized.contains('group-stage') ||
        normalized.contains('groupstage') ||
        normalized.contains('regular season') ||
        normalized.contains('grupo') ||
        normalized.contains('مجموعات') ||
        normalized.contains('دور المجموعات')) {
      return true;
    }
    if (normalized.contains('group')) return true;
    if (_groupLetter.hasMatch(normalized)) return true;
    return false;
  }

  static bool _isGroupStageDate(DateTime date) {
    final utc = date.toUtc();
    final start = WorldCupConfig.tournamentStartUtc;
    final end = WorldCupConfig.groupStageEndUtc;
    return !utc.isBefore(start) && !utc.isAfter(end);
  }
}
