import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../services/app_controller.dart';
import '../screens/splash_screen.dart';
import '../notifications/notification_router.dart';
import '../widgets/notification_tap_listener.dart';
import 'app_scope.dart';
import 'kickora_navigator.dart';
import 'routes.dart';
import 'app_locale.dart';
import 'theme.dart';

class KickoraApp extends StatelessWidget {
  const KickoraApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final router = NotificationRouter(
            navigatorKey: kickoraNavigatorKey,
            footballRepository: controller.footballRepository,
          );
          return NotificationTapListener(
            controller: controller,
            router: router,
            child: MaterialApp(
            navigatorKey: kickoraNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Kickora',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            supportedLocales: AppLocale.supportedLocales,
            locale: controller.locale,
            localeListResolutionCallback: (deviceLocales, supported) =>
                AppLocale.resolveList(
                  deviceLocales,
                  supported,
                  controller.locale,
                ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: AppLocale.textDirection(controller.locale),
                child: child ?? const SplashScreen(),
              );
            },
          ),
          );
        },
      ),
    );
  }
}
