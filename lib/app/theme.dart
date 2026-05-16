import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised premium dark/light Kickora theme.
class AppTheme {
  AppTheme._();

  // Kept for backward compatibility with existing imports.
  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkCard = AppColors.darkCard;
  static const Color teal = AppColors.teal;
  static const Color neonGreen = AppColors.neonGreen;

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.teal,
      secondary: AppColors.neonGreen,
      surface: AppColors.darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: AppColors.darkCard,
      error: AppColors.cardRed,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.darkBorder,
      hintColor: Colors.white70,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.teal.withValues(alpha: 0.28),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.teal : Colors.white54,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
            color: selected ? AppColors.teal : Colors.white54,
          );
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.teal,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.darkCard,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        side: BorderSide(color: Color(0x22FFFFFF)),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.6,
        space: 16,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCard,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70, size: 22),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.teal),
      switchTheme: _switchTheme(dark: true),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.tealDeep,
      secondary: Color(0xFF42C700),
      surface: AppColors.lightSurface,
      onSurface: Color(0xFF0E1822),
      surfaceContainerHighest: AppColors.lightCard,
      error: AppColors.cardRed,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.lightBorder,
      hintColor: const Color(0xFF6A7383),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, const Color(0xFF0E1822)),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: Color(0xFF0E1822),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0E1822),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.tealDeep,
        unselectedItemColor: Color(0xFF5B6473),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.tealDeep.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.tealDeep : const Color(0xFF5B6473),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
            color: selected ? AppColors.tealDeep : const Color(0xFF5B6473),
          );
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.tealDeep,
        labelColor: Color(0xFF0E1822),
        unselectedLabelColor: Color(0xFF6A7383),
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 0.7,
        space: 16,
      ),
      switchTheme: _switchTheme(dark: false),
    );
  }

  /// Premium switches with strong on/off contrast (especially on light cards).
  static SwitchThemeData _switchTheme({required bool dark}) {
    final activeTrack = dark ? AppColors.teal : AppColors.tealDeep;
    final inactiveTrack =
        dark ? const Color(0xFF2A3344) : const Color(0xFFC8D1DC);
    final inactiveOutline =
        dark ? const Color(0xFF4A5568) : const Color(0xFF8B97A8);
    final inactiveThumb =
        dark ? const Color(0xFF9AA8BC) : const Color(0xFF4E5D6E);

    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? Colors.white38 : const Color(0xFFB8C2CE);
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return inactiveThumb;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? const Color(0xFF1E2633) : const Color(0xFFE8EDF3);
        }
        if (states.contains(WidgetState.selected)) {
          return activeTrack;
        }
        return inactiveTrack;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return inactiveOutline;
      }),
      trackOutlineWidth: WidgetStateProperty.all(1.2),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return activeTrack.withValues(alpha: 0.18);
        }
        return inactiveOutline.withValues(alpha: 0.12);
      }),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color color) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w900),
          displayMedium:
              base.displayMedium?.copyWith(fontWeight: FontWeight.w900),
          displaySmall:
              base.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          headlineLarge:
              base.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          headlineMedium:
              base.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          headlineSmall:
              base.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          titleLarge:
              base.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
          titleMedium:
              base.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
          titleSmall:
              base.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.35),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 13.5, height: 1.35),
          bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.3),
          labelLarge:
              base.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
          labelMedium:
              base.labelMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
          labelSmall:
              base.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        )
        .apply(bodyColor: color, displayColor: color);
  }
}
