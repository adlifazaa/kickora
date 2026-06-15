import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/widgets/world_cup_trophy_badge.dart';

void main() {
  testWidgets('WorldCupTrophyBadge renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorldCupTrophyBadge(size: 48),
        ),
      ),
    );
    expect(find.byType(WorldCupTrophyBadge), findsOneWidget);
  });
}
