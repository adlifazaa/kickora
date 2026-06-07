import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/app/app_scope.dart';
import 'package:kickora/app/theme.dart';
import 'package:kickora/screens/settings_screen.dart';
import 'package:kickora/data/providers/mock_football_data_provider.dart';
import 'package:kickora/data/repositories/football_repository.dart';
import 'package:kickora/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _switchForTitle(String title) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(title),
      matching: find.byType(Row),
    ),
    matching: find.byType(Switch),
  );
}

bool _switchValue(WidgetTester tester, String title) {
  return tester.widget<Switch>(_switchForTitle(title)).value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification and favorite toggles update switch value', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppController(
      prefs,
      footballRepository:
          FootballRepository(dataProvider: MockFootballDataProvider()),
    );
    await controller.load();
    await controller.setLocale(const Locale('en'));

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_switchValue(tester, 'Enable notifications'), isFalse);

    await tester.tap(_switchForTitle('Enable notifications'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.notificationsEnabled, isTrue);
    expect(_switchValue(tester, 'Enable notifications'), isTrue);

    expect(_switchValue(tester, 'Favorite team updates'), isTrue);

    await tester.tap(_switchForTitle('Favorite team updates'));
    await tester.pumpAndSettle();

    expect(controller.notifyFavoriteTeamUpdatesEnabled, isFalse);
    expect(_switchValue(tester, 'Favorite team updates'), isFalse);

    await tester.tap(_switchForTitle('Enable notifications'));
    await tester.pumpAndSettle();

    expect(controller.notificationsEnabled, isFalse);
    expect(_switchValue(tester, 'Enable notifications'), isFalse);

    final controller2 = AppController(
      prefs,
      footballRepository:
          FootballRepository(dataProvider: MockFootballDataProvider()),
    );
    await controller2.load();
    expect(controller2.notificationsEnabled, isFalse);
    expect(controller2.notifyFavoriteTeamUpdatesEnabled, isFalse);
  });
}
