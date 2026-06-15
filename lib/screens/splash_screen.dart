import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _ball = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  )..repeat(reverse: true);

  String _versionName = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _versionName = info.version);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _ball.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final logoAnim = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    final fadeAnim = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF15303A),
                  Color(0xFF080A0F),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _ball]),
              builder: (context, _) {
                final bounce = Curves.easeInOut.transform(_ball.value);
                final ballOffset = -18 - (bounce * 22);
                final ballScale = 0.92 + (bounce * 0.08);

                return FadeTransition(
                  opacity: fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: Tween<double>(begin: 0.82, end: 1)
                                .evaluate(logoAnim),
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.teal,
                                    AppColors.neonGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal
                                        .withValues(alpha: 0.38),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_soccer_rounded,
                                color: Colors.black,
                                size: 56,
                              ),
                            ),
                          ),
                          Positioned(
                            top: ballOffset,
                            right: -6,
                            child: Transform.scale(
                              scale: ballScale,
                              child: Transform.rotate(
                                angle: bounce * math.pi * 0.15,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.sports_soccer,
                                    size: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: logoAnim.value.clamp(0.0, 1.0),
                        child: Text(
                          'Kickora',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: (logoAnim.value * 0.9).clamp(0.0, 1.0),
                        child: Text(
                          text.appTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: fadeAnim,
              child: Center(
                child: Text(
                  _versionName.isEmpty
                      ? (text.isArabic ? 'إصدار' : 'Version')
                      : '${text.isArabic ? 'إصدار' : 'Version'} $_versionName',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
