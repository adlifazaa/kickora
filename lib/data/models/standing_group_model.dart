import 'standing_model.dart';

/// One World Cup group table (Group A, Group B, …).
class StandingGroupModel {
  const StandingGroupModel({
    required this.name,
    required this.rows,
  });

  final String name;
  final List<StandingModel> rows;
}
