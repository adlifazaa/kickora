class MatchStatisticModel {
  const MatchStatisticModel({
    required this.title,
    required this.home,
    required this.away,
    required this.homeValue,
    required this.awayValue,
  });

  final String title;
  final double home;
  final double away;
  final String homeValue;
  final String awayValue;

  factory MatchStatisticModel.fromJson(Map<String, dynamic> json) {
    return MatchStatisticModel(
      title: (json['title'] ?? json['type'] ?? '').toString(),
      home: ((json['home'] ?? json['homeValue'] ?? 0) as num).toDouble(),
      away: ((json['away'] ?? json['awayValue'] ?? 0) as num).toDouble(),
      homeValue: (json['homeDisplay'] ?? json['homeValue'] ?? '').toString(),
      awayValue: (json['awayDisplay'] ?? json['awayValue'] ?? '').toString(),
    );
  }
}

/// Backward-compatible alias used across the UI.
typedef MatchStat = MatchStatisticModel;
