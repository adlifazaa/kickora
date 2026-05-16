class CompetitionModel {
  const CompetitionModel({
    required this.id,
    required this.name,
    required this.region,
    required this.logo,
    this.isFeatured = false,
    this.teamCount = 0,
    this.matchesToday = 0,
  });

  final int id;
  final String name;
  final String region;
  final String logo;
  final bool isFeatured;
  final int teamCount;
  final int matchesToday;

  /// HTTP league crest when sourced from API-Football `league.logo`.
  String get logoUrl {
    final value = logo.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '';
  }

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      region: (json['country'] ?? json['region'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      isFeatured: json['featured'] as bool? ?? false,
      teamCount: (json['teamCount'] as num?)?.toInt() ?? 0,
      matchesToday: (json['matchesToday'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'region': region,
        'logo': logo,
        'featured': isFeatured,
        'teamCount': teamCount,
        'matchesToday': matchesToday,
      };
}
