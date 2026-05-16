import '../../data/models/player_model.dart';

/// Builds tactical rows for the pitch from formation strings (4-3-3, 3-5-2, …).
class FormationLineupLayout {
  FormationLineupLayout._();

  static List<List<PlayerModel>> resolveLines({
    required List<List<PlayerModel>> lines,
    required String formation,
  }) {
    final count = lines.fold<int>(0, (sum, row) => sum + row.length);
    if (count == 0) return const [];

    if (lines.length >= 2 && count >= 7) return lines;

    final flat = <PlayerModel>[];
    for (final row in lines) {
      flat.addAll(row);
    }
    if (flat.length >= 7) {
      final split = splitByFormation(flat, formation);
      if (split.length >= 2) return split;
    }
    return lines;
  }

  static List<List<PlayerModel>> splitByFormation(
    List<PlayerModel> starters,
    String formation,
  ) {
    if (starters.isEmpty) return const [];

    final parts = formation
        .split('-')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();

    if (parts.isEmpty) {
      return [starters];
    }

    final out = <List<PlayerModel>>[];
    var index = 0;
    for (final count in parts) {
      final line = <PlayerModel>[];
      for (var c = 0; c < count && index < starters.length; c++) {
        line.add(starters[index++]);
      }
      if (line.isNotEmpty) out.add(line);
    }
    if (index < starters.length) {
      out.add(starters.sublist(index));
    }
    return out;
  }
}
