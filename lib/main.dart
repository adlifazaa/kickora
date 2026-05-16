import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'core/network/api_debug_log.dart';
import 'data/repositories/football_repository.dart';
import 'data/services/football_api_service.dart';
import 'ads/ad_service.dart';
import 'core/refresh/match_refresh_service.dart';
import 'notifications/services/kickora_notification_service.dart';
import 'services/app_controller.dart';
import 'services/favorite_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiDebugLog.boot();
  await AdService.instance.initialize();
  final preferences = await SharedPreferences.getInstance();
  final notificationService =
      KickoraNotificationService.createMock(preferences);
  await notificationService.initialize();
  final favoriteManager = FavoriteManager(
    preferences,
    notificationService: notificationService,
  );
  final cache = CacheManager(preferences);
  final footballApi = FootballApiService(cache: cache);
  final footballRepository = FootballRepository(
    api: footballApi,
    cache: cache,
  );
  final matchRefreshService = MatchRefreshService(footballRepository);
  final controller = AppController(
    preferences,
    footballRepository: footballRepository,
    notificationService: notificationService,
    favoriteManager: favoriteManager,
    matchRefreshService: matchRefreshService,
  );
  await controller.load();
  runApp(KickoraApp(controller: controller));
}
