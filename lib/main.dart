import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'data/repositories/football_repository.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final cache = CacheManager(preferences);
  final footballRepository = FootballRepository(cache: cache);
  final controller = AppController(
    preferences,
    footballRepository: footballRepository,
  );
  await controller.load();
  runApp(KickoraApp(controller: controller));
}
