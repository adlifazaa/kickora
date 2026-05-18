class CompetitionModel {
  const CompetitionModel({
    required this.id,
    required this.name,
    required this.region,
    required this.logo,
    this.countryCode = '',
    this.countryFlagUrl = '',
    this.season,
    this.competitionType = '',
    this.isFeatured = false,
    this.teamCount = 0,
    this.matchesToday = 0,
  });

  final int id;
  final String name;

  /// Country display name from API-Football `country.name`.
  final String region;

  /// League crest URL or legacy mock token.
  final String logo;

  /// ISO country code from API-Football `country.code` (e.g. GB, ES).
  final String countryCode;

  /// Country flag URL from API-Football `country.flag` when available.
  final String countryFlagUrl;

  /// Active season year when known.
  final int? season;

  /// League type from API-Football `league.type` (League, Cup, etc.).
  final String competitionType;

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

  /// Best image for badges: league logo, then country flag.
  String get displayLogoUrl {
    if (logoUrl.isNotEmpty) return logoUrl;
    final flag = countryFlagUrl.trim();
    if (flag.startsWith('http://') || flag.startsWith('https://')) {
      return flag;
    }
    return '';
  }

  bool get hasRemoteLogo => displayLogoUrl.isNotEmpty;

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      region: (json['country'] ?? json['region'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      countryCode: (json['countryCode'] ?? '').toString(),
      countryFlagUrl: (json['countryFlagUrl'] ?? json['countryFlag'] ?? '')
          .toString(),
      season: (json['season'] as num?)?.toInt(),
      competitionType:
          (json['competitionType'] ?? json['type'] ?? '').toString(),
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
        'countryCode': countryCode,
        'countryFlagUrl': countryFlagUrl,
        if (season != null) 'season': season,
        'competitionType': competitionType,
        'featured': isFeatured,
        'teamCount': teamCount,
        'matchesToday': matchesToday,
      };
}
