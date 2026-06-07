import 'package:flutter/material.dart';

/// Supported app languages. Arabic is the default for new installs.
abstract final class AppLocale {
  static const String arabicCode = 'ar';
  static const String englishCode = 'en';

  static const Locale defaultLocale = Locale(arabicCode);

  static const List<Locale> supportedLocales = <Locale>[
    Locale(arabicCode),
    Locale(englishCode),
  ];

  static Locale fromLanguageCode(String? code) {
    if (code == englishCode) {
      return const Locale(englishCode);
    }
    return defaultLocale;
  }

  static bool isArabic(Locale locale) => locale.languageCode == arabicCode;

  static TextDirection textDirection(Locale locale) =>
      isArabic(locale) ? TextDirection.rtl : TextDirection.ltr;

  /// Ignores device locale; the in-app preference always wins.
  static Locale resolveList(
    List<Locale>? deviceLocales,
    Iterable<Locale> supported,
    Locale appLocale,
  ) =>
      fromLanguageCode(appLocale.languageCode);
}
