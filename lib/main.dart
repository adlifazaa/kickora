import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'core/constants/api_dev_mode.dart';
import 'core/constants/api_mode_service.dart';
import 'core/firebase/analytics_service.dart';
import 'core/firebase/crashlytics_service.dart';
import 'core/firebase/firebase_service.dart';
import 'core/meta/meta_app_events_service.dart';
import 'core/startup/startup_timing.dart';
import 'data/repositories/football_repository.dart';
import 'data/providers/football_data_provider_factory.dart';
import 'data/services/api_football/api_football_service.dart';
import 'data/services/backend_proxy/backend_proxy_service.dart';
import 'ads/ad_service.dart';
import 'subscription/play_billing_bridge.dart';
import 'subscription/premium_service.dart';
import 'subscription/premium_subscription_service.dart';
import 'subscription/mock_subscription_bridge.dart';
import 'core/refresh/match_refresh_service.dart';
import 'notifications/fcm_background_handler.dart';
import 'notifications/services/kickora_notification_service.dart';
import 'services/app_controller.dart';
import 'services/favorite_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StartupTiming.mark('app_start');

  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );

  ApiModeService.logConfiguration();
  final preferences = await SharedPreferences.getInstance();

  final premiumSubscriptionService = PremiumSubscriptionService(
    preferences,
    paymentBridge: const MockSubscriptionBridge(),
  );
  await premiumSubscriptionService.load();
  PremiumService.configurePayments(enabled: false);

  await FirebaseService.initialize();
  if (FirebaseService.isInitialized && _registerFcmBackgroundHandler) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final notificationService = KickoraNotificationService.create(preferences);
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
  final premiumService = PremiumService(premiumSubscriptionService);
  AdService.instance.bindPremium(premiumSubscriptionService);

  final controller = AppController(
    preferences,
    footballRepository: footballRepository,
    notificationService: notificationService,
    favoriteManager: favoriteManager,
    matchRefreshService: matchRefreshService,
    premiumSubscriptionService: premiumSubscriptionService,
    premiumService: premiumService,
  );

  await controller.loadEssentials();
  StartupTiming.mark('run_app');
  runApp(KickoraApp(controller: controller));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupTiming.mark('first_frame');
    unawaited(_completeDeferredStartup(
      preferences: preferences,
      notificationService: notificationService,
      controller: controller,
      premiumSubscriptionService: premiumSubscriptionService,
      footballRepository: footballRepository,
    ));
  });
}

Future<void> _completeDeferredStartup({
  required SharedPreferences preferences,
  required KickoraNotificationService notificationService,
  required AppController controller,
  required PremiumSubscriptionService premiumSubscriptionService,
  required FootballRepository footballRepository,
}) async {
  try {
    await MetaAppEventsService.instance.initialize(preferences);
    await AnalyticsService.instance.initialize();
    unawaited(AnalyticsService.instance.logAppOpen());
    await CrashlyticsService.instance.initialize();
    FirebaseService.logStartupStatus(
      notificationsEnabled: notificationService.isEnabled,
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[Kickora Startup] deferred Firebase products failed: $e\n$st');
    }
  }

  StartupTiming.mark('firebase_ready');

  final billingBridge = await PlayBillingBridge.create();
  PremiumService.configurePayments(enabled: billingBridge != null);

  ApiFootballService().logStatus();
  BackendProxyService(cache: CacheManager(preferences)).logStatus();

  await notificationService.initialize();
  await controller.completeDeferredStartup();
  StartupTiming.mark('deferred_startup_complete');
}

bool get _registerFcmBackgroundHandler {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
