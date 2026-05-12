class CompetitionModel {
  const CompetitionModel({
    required this.id,
    required this.name,
    required this.region,
    required this.logo,
    this.isFeatured = false,
  });

  final int id;
  final String name;
  final String region;
  final String logo;
  final bool isFeatured;

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      region: (json['country'] ?? json['region'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      isFeatured: json['featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'region': region,
        'logo': logo,
        'featured': isFeatured,
      };
}
