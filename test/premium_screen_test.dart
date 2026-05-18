import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/ads/ad_placement.dart';
import 'package:kickora/ads/ad_service.dart';
import 'package:kickora/app/app_scope.dart';
import 'package:kickora/app/theme.dart';
import 'package:kickora/screens/premium_screen.dart';
import 'package:kickora/services/app_controller.dart';
import 'package:kickora/subscription/premium_service.dart';
import 'package:kickora/widgets/ad_placeholder.dart';
import 'package:kickora/widgets/gentle_ad_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PremiumScreen shows benefits and Coming Soon', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppController(prefs);
    await controller.load();
    await controller.setLocale(const Locale('en'));

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PremiumScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kickora Premium'), findsWidgets);
    expect(find.text('Remove ads'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.textContaining('Restore'), findsOneWidget);
    expect(PremiumService.paymentsEnabled, isFalse);
  });

  testWidgets('GentleAdSlot renders nothing when placeholders disabled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppController(prefs);
    await controller.load();
    AdService.instance.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          controller: controller,
          child: const Scaffold(
            body: GentleAdSlot(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdPlaceholder), findsNothing);
    expect(
      AdService.instance.shouldShowPlaceholder(
        AdPlacement.feedNative,
        feedItemIndex: 4,
      ),
      isFalse,
    );
  });
}
