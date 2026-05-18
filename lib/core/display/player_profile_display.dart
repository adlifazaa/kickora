import '../../data/models/player_model.dart';

/// Formats player profile fields when API data is null, missing, or zero placeholders.
class PlayerProfileDisplay {
  PlayerProfileDisplay._();

  static const int missing = -1;

  /// Parser sentinel or API placeholder zero (mock never uses 0 for these).
  static bool isMissingProfileStat(int value) => value < 0 || value == 0;

  /// Counts where zero is valid (goals, cards).
  static bool isMissingCountStat(int value) => value < 0;

  static String dash({bool isArabic = false}) => '—';

  static String unknownText({bool isArabic = false}) =>
      isArabic ? 'غير معروف' : 'Unknown';

  static String notAvailable({bool isArabic = false}) =>
      isArabic ? 'غير متوفر' : 'Not available';

  static String text(String? value, {bool isArabic = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return unknownText(isArabic: isArabic);
    return v;
  }

  static String profileInteger(
    int value, {
    bool isArabic = false,
    String? suffix,
  }) {
    if (isMissingProfileStat(value)) return dash(isArabic: isArabic);
    final base = '$value';
    if (suffix == null || suffix.isEmpty) return base;
    return '$base$suffix';
  }

  static String countInteger(int value, {bool isArabic = false}) {
    if (isMissingCountStat(value)) return dash(isArabic: isArabic);
    return '$value';
  }

  static String age(int value, {bool isArabic = false}) {
    if (isMissingProfileStat(value)) return dash(isArabic: isArabic);
    return isArabic ? '$value سنة' : '$value yrs';
  }

  static String heightCm(int value, {bool isArabic = false}) {
    if (isMissingProfileStat(value)) return dash(isArabic: isArabic);
    return '$value cm';
  }

  static String weightKg(int value, {bool isArabic = false}) {
    if (isMissingProfileStat(value)) return dash(isArabic: isArabic);
    return '$value kg';
  }

  static String rating(double matchRating, String seasonRating,
      {bool isArabic = false}) {
    if (matchRating > 0) return matchRating.toStringAsFixed(1);
    final parsed = double.tryParse(seasonRating.trim());
    if (parsed != null && parsed > 0) return seasonRating.trim();
    return dash(isArabic: isArabic);
  }

  static String recentMatchRating(String rating, {bool isArabic = false}) {
    final v = rating.trim();
    if (v.isEmpty) return dash(isArabic: isArabic);
    final parsed = double.tryParse(v);
    if (parsed != null && parsed <= 0) return dash(isArabic: isArabic);
    return v;
  }

  static double? ratingValue(PlayerModel player) {
    if (player.matchRating > 0) return player.matchRating;
    final parsed = double.tryParse(player.seasonRating.trim());
    if (parsed != null && parsed > 0) return parsed;
    return null;
  }

  static String achievementValue(
    int source,
    int divisor, {
    bool isArabic = false,
    bool allowZero = false,
  }) {
    final missing =
        allowZero ? isMissingCountStat(source) : isMissingProfileStat(source);
    if (missing) return dash(isArabic: isArabic);
    return '${(source ~/ divisor).clamp(0, 120)}';
  }
}

extension PlayerModelProfileDisplay on PlayerModel {
  String displayNationality({bool isArabic = false}) =>
      PlayerProfileDisplay.text(nationality, isArabic: isArabic);

  String displayPosition({bool isArabic = false}) =>
      PlayerProfileDisplay.text(position, isArabic: isArabic);

  String displayTeam({bool isArabic = false}) =>
      PlayerProfileDisplay.text(team, isArabic: isArabic);

  String displayPreferredFoot({bool isArabic = false}) {
    final foot = preferredFoot.trim();
    if (foot.isEmpty) {
      return PlayerProfileDisplay.unknownText(isArabic: isArabic);
    }
    return foot;
  }

  String displayAge({bool isArabic = false}) =>
      PlayerProfileDisplay.age(age, isArabic: isArabic);

  String displayHeight({bool isArabic = false}) =>
      PlayerProfileDisplay.heightCm(height, isArabic: isArabic);

  String displayWeight({bool isArabic = false}) =>
      PlayerProfileDisplay.weightKg(weight, isArabic: isArabic);

  String displayShirtNumber({bool isArabic = false}) =>
      PlayerProfileDisplay.profileInteger(number, isArabic: isArabic);

  String displayAppearances({bool isArabic = false}) =>
      PlayerProfileDisplay.profileInteger(appearances, isArabic: isArabic);

  String displayMinutes({bool isArabic = false}) =>
      PlayerProfileDisplay.profileInteger(minutesPlayed, isArabic: isArabic);

  String displayGoals({bool isArabic = false}) =>
      PlayerProfileDisplay.countInteger(goals, isArabic: isArabic);

  String displayAssists({bool isArabic = false}) =>
      PlayerProfileDisplay.countInteger(assists, isArabic: isArabic);

  String displayYellowCards({bool isArabic = false}) =>
      PlayerProfileDisplay.countInteger(yellowCards, isArabic: isArabic);

  String displayRedCards({bool isArabic = false}) =>
      PlayerProfileDisplay.countInteger(redCards, isArabic: isArabic);

  String displaySeasonRating({bool isArabic = false}) =>
      PlayerProfileDisplay.rating(matchRating, seasonRating, isArabic: isArabic);
}
