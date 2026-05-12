import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../services/app_controller.dart';
import '../screens/splash_screen.dart';
import 'app_scope.dart';
import 'routes.dart';
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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kickora',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            supportedLocales: const [Locale('ar'), Locale('en')],
            locale: controller.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final isArabic = controller.locale.languageCode == 'ar';
              return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
