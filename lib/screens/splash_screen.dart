import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
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
            child: FadeTransition(
              opacity:
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(
                    CurvedAnimation(
                        parent: _controller, curve: Curves.easeOutBack)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.teal, AppColors.neonGreen],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.55),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sports_soccer_rounded,
                          color: Colors.black, size: 56),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Kickora',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text.appTagline,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.07),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${text.isArabic ? 'إصدار' : 'Version'} 1.0.0',
                style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
