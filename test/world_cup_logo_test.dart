import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/widgets/world_cup_logo.dart';

void main() {
  testWidgets('WorldCupLogo renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorldCupLogo(size: 48),
        ),
      ),
    );
    expect(find.byType(WorldCupLogo), findsOneWidget);
  });
}
