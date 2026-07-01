import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/widgets/world_cup_logo.dart';

void main() {
  testWidgets('WorldCupLogo renders approved badge asset at small size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorldCupLogo(size: 48),
        ),
      ),
    );
    expect(find.byType(WorldCupLogo), findsOneWidget);
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(WorldCupLogo),
        matching: find.byType(Image),
      ),
    );
    expect((image.image as AssetImage).assetName, WorldCupLogo.assetPath);
    expect(image.fit, BoxFit.contain);
    expect(find.byIcon(Icons.sports_soccer_rounded), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);

    final box = tester.getSize(find.byType(WorldCupLogo));
    expect(box.width, 48);
    expect(box.height, 48);
  });

  testWidgets('WorldCupLogo keeps square proportions at hub size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorldCupLogo(size: 72),
        ),
      ),
    );
    final box = tester.getSize(find.byType(WorldCupLogo));
    expect(box.width, box.height);
    expect(box.width, 72);
  });
}
