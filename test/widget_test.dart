import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kickora/services/app_controller.dart';

void main() {
  test('AppController loads defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(preferences);
    await controller.load();

    expect(controller.locale.languageCode, 'ar');
    expect(controller.themeMode, ThemeMode.dark);
  });
}
