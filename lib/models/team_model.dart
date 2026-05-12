class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logo,
    required this.nationality,
  });

  final int id;
  final String name;
  final String shortName;
  final String logo;
  final String nationality;

  /// Future API parser. Adjust keys to match the real provider when wired.
  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: (json['code'] ?? json['shortName'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      nationality: (json['country'] ?? json['nationality'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'logo': logo,
        'nationality': nationality,
      };
}
