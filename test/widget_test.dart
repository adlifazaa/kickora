import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kickora/app/app_locale.dart';
import 'package:kickora/data/providers/mock_football_data_provider.dart';
import 'package:kickora/data/repositories/football_repository.dart';
import 'package:kickora/services/app_controller.dart';
import 'package:kickora/subscription/premium_subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FootballRepository uses backend remote data by default', () {
    final repo = FootballRepository();
    expect(repo.usesLiveApi, true);
  });

  test('AppController loads defaults and persists notifications & favorites', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(
      preferences,
      footballRepository:
          FootballRepository(dataProvider: MockFootballDataProvider()),
    );
    await controller.load();

    expect(controller.locale, AppLocale.defaultLocale);
    expect(controller.isArabic, isTrue);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.notificationsEnabled, false);

    await controller.setNotificationsEnabled(true);
    expect(controller.notificationsEnabled, true);

    await controller.toggleTeamFavorite(7);
    expect(controller.isTeamFavorite(7), true);

    await controller.toggleCompetitionFavorite(39);
    expect(controller.isCompetitionFavorite(39), true);

    await controller.toggleMatchFavorite(1001);
    expect(controller.isMatchFavorite(1001), true);

    final controller2 = AppController(
      preferences,
      footballRepository:
          FootballRepository(dataProvider: MockFootballDataProvider()),
    );
    await controller2.load();
    expect(controller2.notificationsEnabled, true);
    expect(controller2.isTeamFavorite(7), true);
    expect(controller2.isCompetitionFavorite(39), true);
    expect(controller2.isMatchFavorite(1001), true);
  });

  test('AppController normalizes invalid language codes to Arabic', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'fr'});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(
      preferences,
      footballRepository:
          FootballRepository(dataProvider: MockFootballDataProvider()),
    );
    await controller.load();

    expect(controller.locale, AppLocale.defaultLocale);
    expect(controller.isArabic, isTrue);
  });

  test('Premium defaults: ads enabled, trial available', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final premium = PremiumSubscriptionService(preferences);
    await premium.load();

    expect(premium.isPremium, false);
    expect(premium.adsEnabled, true);
    expect(premium.trialAvailable, true);
  });
}
