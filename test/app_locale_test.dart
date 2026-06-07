import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/app/app_locale.dart';

void main() {
  test('fromLanguageCode defaults to Arabic', () {
    expect(AppLocale.fromLanguageCode(null), AppLocale.defaultLocale);
    expect(AppLocale.fromLanguageCode(''), AppLocale.defaultLocale);
    expect(AppLocale.fromLanguageCode('fr'), AppLocale.defaultLocale);
    expect(
      AppLocale.fromLanguageCode(AppLocale.englishCode).languageCode,
      AppLocale.englishCode,
    );
  });

  test('textDirection follows locale', () {
    expect(
      AppLocale.textDirection(AppLocale.defaultLocale),
      TextDirection.rtl,
    );
    expect(
      AppLocale.textDirection(const Locale(AppLocale.englishCode)),
      TextDirection.ltr,
    );
  });
}
