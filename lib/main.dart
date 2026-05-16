import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'data/repositories/football_repository.dart';
import 'data/services/football_api_service.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final cache = CacheManager(preferences);
  final footballApi = FootballApiService(cache: cache);
  final footballRepository = FootballRepository(
    api: footballApi,
    cache: cache,
  );
  final controller = AppController(
    preferences,
    footballRepository: footballRepository,
  );
  await controller.load();
  runApp(KickoraApp(controller: controller));
}
