class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.shortName,
    String? logo,
    String? logoUrl,
    this.countryName = '',
    this.countryCode = '',
    this.flagUrl = '',
    String? nationality,
  })  : logo = logoUrl ?? logo ?? '',
        nationality = nationality ?? countryName;

  final int id;
  final String name;
  final String shortName;

  /// Crest/logo URL from API-Football `team.logo` (or legacy mock initials).
  final String logo;

  final String countryName;
  final String countryCode;
  final String flagUrl;

  /// @deprecated Use [countryName].
  final String nationality;

  /// Preferred crest field (alias of [logo] when sourced from API).
  String get logoUrl => _isHttpUrl(logo) ? logo : '';

  /// Best image for [TeamLogo]: crest, then country flag, then initials.
  String? get displayImageUrl {
    if (logoUrl.isNotEmpty) return logoUrl;
    if (_isHttpUrl(flagUrl)) return flagUrl;
    return null;
  }

  static bool _isHttpUrl(String value) {
    final t = value.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  factory TeamModel.fromJson(Map<String, dynamic> json) {
      final countryName = (json['countryName'] ??
            json['country'] ??
            json['nationality'] ??
            '')
        .toString();
    final countryCode = (json['countryCode'] ?? '').toString();
    final flag = (json['flagUrl'] ?? json['flag'] ?? '').toString();
    final rawLogo = (json['logoUrl'] ?? json['logo'] ?? '').toString();

    return TeamModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: (json['code'] ?? json['shortName'] ?? '').toString(),
      logo: rawLogo,
      countryName: countryName,
      countryCode: countryCode,
      flagUrl: flag,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'code': shortName,
        'logo': logo,
        'logoUrl': logo,
        'countryName': countryName,
        'countryCode': countryCode,
        'flagUrl': flagUrl,
        'nationality': countryName,
      };
}
