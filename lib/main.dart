import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'core/constants/api_dev_mode.dart';
import 'core/constants/api_mode_service.dart';
import 'core/firebase/firebase_service.dart';
import 'data/repositories/football_repository.dart';
import 'data/providers/football_data_provider_factory.dart';
import 'ads/ad_service.dart';
import 'subscription/premium_subscription_service.dart';
import 'core/refresh/match_refresh_service.dart';
import 'notifications/services/kickora_notification_service.dart';
import 'services/app_controller.dart';
import 'services/favorite_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await FirebaseService.initialize();
  ApiModeService.logConfiguration();
  final preferences = await SharedPreferences.getInstance();
  final premiumSubscriptionService = PremiumSubscriptionService(preferences);
  await premiumSubscriptionService.load();
  AdService.instance.bindPremium(premiumSubscriptionService);
  await AdService.instance.initialize();
  final notificationService =
      KickoraNotificationService.createMock(preferences);
  await notificationService.initialize();
  final favoriteManager = FavoriteManager(
    preferences,
    notificationService: notificationService,
  );
  final cache = CacheManager(preferences);
  final footballData = FootballDataProviderFactory.create(cache: cache);
  footballData.logConfiguration();
  final footballRepository = FootballRepository(
    dataProvider: footballData,
    cache: cache,
  );
  final matchRefreshService = MatchRefreshService(
    footballRepository,
    config: ApiDevMode.refreshConfig(),
  );
  final controller = AppController(
    preferences,
    footballRepository: footballRepository,
    notificationService: notificationService,
    favoriteManager: favoriteManager,
    matchRefreshService: matchRefreshService,
    premiumSubscriptionService: premiumSubscriptionService,
  );
  await controller.load();
  runApp(KickoraApp(controller: controller));
}
