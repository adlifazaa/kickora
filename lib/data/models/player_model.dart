class PlayerRecentMatch {
  const PlayerRecentMatch({
    required this.opponent,
    required this.rating,
    required this.goals,
    required this.assists,
  });

  final String opponent;
  final String rating;
  final int goals;
  final int assists;

  factory PlayerRecentMatch.fromJson(Map<String, dynamic> json) =>
      PlayerRecentMatch(
        opponent: (json['opponent'] ?? '').toString(),
        rating: (json['rating'] ?? '').toString(),
        goals: (json['goals'] ?? 0) as int,
        assists: (json['assists'] ?? 0) as int,
      );
}

class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.number,
    required this.nationality,
    required this.age,
    required this.height,
    this.weight = 0,
    required this.position,
    required this.team,
    this.teamLogoShort = '',
    this.teamLogoUrl = '',
    required this.appearances,
    this.minutesPlayed = 0,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    this.isCaptain = false,
    this.preferredFoot = 'Right',
    this.matchRating = 0.0,
    this.seasonRating = '',
    this.career = const <String>[],
    this.recentMatches = const [],
    this.photoUrl = '',
  });

  final int id;
  final String name;
  final String shortName;
  final int number;
  final String nationality;
  final int age;
  final int height;
  final int weight;
  final String position;
  final String team;
  final String teamLogoShort;
  final String teamLogoUrl;
  final int appearances;
  final int minutesPlayed;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final bool isCaptain;
  final String preferredFoot;
  final double matchRating;
  final String seasonRating;
  final List<String> career;
  final List<PlayerRecentMatch> recentMatches;
  final String photoUrl;

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: (json['shortName'] ?? '').toString(),
      number: (json['number'] ?? 0) as int,
      nationality: (json['nationality'] ?? '').toString(),
      age: (json['age'] ?? 0) as int,
      height: (json['height'] ?? 0) as int,
      weight: (json['weight'] ?? 0) as int,
      position: (json['position'] ?? '').toString(),
      team: (json['team'] ?? '').toString(),
      teamLogoShort: (json['teamLogoShort'] ?? '').toString(),
      teamLogoUrl: (json['teamLogoUrl'] ?? '').toString(),
      appearances: (json['appearances'] ?? 0) as int,
      minutesPlayed: (json['minutesPlayed'] ?? 0) as int,
      goals: (json['goals'] ?? 0) as int,
      assists: (json['assists'] ?? 0) as int,
      yellowCards: (json['yellowCards'] ?? 0) as int,
      redCards: (json['redCards'] ?? 0) as int,
      isCaptain: json['isCaptain'] as bool? ?? false,
      preferredFoot: (json['preferredFoot'] ?? 'Right').toString(),
      matchRating: ((json['matchRating'] ?? 0) as num).toDouble(),
      seasonRating: (json['seasonRating'] ?? '').toString(),
      career: ((json['career'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      recentMatches: ((json['recentMatches'] as List?) ?? const [])
          .map((e) => PlayerRecentMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      photoUrl: (json['photoUrl'] ?? json['photo'] ?? '').toString(),
    );
  }
}
