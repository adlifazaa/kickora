/// Tactical formation metadata (e.g. 4-3-3, 3-5-2).
class FormationModel {
  const FormationModel({
    required this.name,
    this.lines = const [],
  });

  final String name;
  final List<int> lines;

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List?;
    return FormationModel(
      name: (json['name'] ?? json['formation'] ?? '').toString(),
      lines: rawLines == null
          ? const []
          : rawLines.map((e) => (e as num).toInt()).toList(),
    );
  }

  factory FormationModel.fromName(String name) => FormationModel(name: name);

  Map<String, dynamic> toJson() => {
        'name': name,
        'lines': lines,
      };
}
