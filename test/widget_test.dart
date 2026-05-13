import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kickora/services/app_controller.dart';

void main() {
  test('AppController loads defaults and persists notifications & favorites', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(preferences);
    await controller.load();

    expect(controller.locale.languageCode, 'ar');
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.notificationsEnabled, false);

    await controller.setNotificationsEnabled(true);
    expect(controller.notificationsEnabled, true);

    await controller.toggleTeamFavorite(7);
    expect(controller.isTeamFavorite(7), true);

    final controller2 = AppController(preferences);
    await controller2.load();
    expect(controller2.notificationsEnabled, true);
    expect(controller2.isTeamFavorite(7), true);
  });
}
