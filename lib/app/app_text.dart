import 'package:flutter/material.dart';

import 'app_scope.dart';

/// Lightweight localisation surface. Centralised here so every screen can
/// reach a single `text.something` API. Keep keys flat and screen-agnostic.
class AppText {
  AppText(this._isArabic);

  final bool _isArabic;
  bool get isArabic => _isArabic;

  static AppText of(BuildContext context) {
    final controller = AppScope.of(context);
    return AppText(controller.isArabic);
  }

  String get appName => 'Kickora';
  String get appTagline =>
      _isArabic ? 'رفيقك المباشر لعالم كرة القدم' : 'Your live football companion';
  String get homeSubtitle => _isArabic
      ? 'نتائج مباشرة، جداول، وتفاصيل احترافية.'
      : 'Live scores, standings, and match insights.';

  String get home => _isArabic ? 'الرئيسية' : 'Home';
  String get matches => _isArabic ? 'المباريات' : 'Matches';
  String get competitions => _isArabic ? 'البطولات' : 'Competitions';
  String get favorites => _isArabic ? 'المفضلة' : 'Favorites';
  String get settings => _isArabic ? 'الإعدادات' : 'Settings';

  String get featuredMatch => _isArabic ? 'المباراة الأبرز' : 'Featured match';
  String get liveNow => _isArabic ? 'مباشر الآن' : 'Live now';
  String get todayMatches => _isArabic ? 'مباريات اليوم' : 'Today matches';
  String get more => _isArabic ? 'المزيد' : 'More';
  String get searchCompetition =>
      _isArabic ? 'ابحث عن بطولة' : 'Search competition';

  String get noMatches =>
      _isArabic ? 'لا توجد مباريات في هذا القسم' : 'No matches in this section';
  String get noMatchesSub => _isArabic
      ? 'تحقق لاحقًا أو اسحب للأسفل للتحديث.'
      : 'Check back later or pull to refresh.';
  String get noMatchesEmptyDetail => _isArabic
      ? 'جرّب تبويبًا آخر أو غيّر التاريخ من الشريط العلوي.'
      : 'Try another tab or pick a different date from the chip above.';
  String get noSearchResultsTitle =>
      _isArabic ? 'لا توجد نتائج بحث' : 'No search results';
  String get noSearchResultsSubtitle => _isArabic
      ? 'جرّب اسمًا مختلفًا أو أقل أحرفًا.'
      : 'Try a different name or fewer characters.';
  String get noFavoritesTitle =>
      _isArabic ? 'لا توجد مفضلات بعد' : 'No favorites yet';
  String get noFavoritesSubtitle => _isArabic
      ? 'أضف فرقًا، بطولات، أو مباريات لتظهر هنا.'
      : 'Add teams, competitions, or matches and they will appear here.';
  String get noFavoritesDetail => _isArabic
      ? 'اضغط على النجمة في بطاقة المباراة أو أيقونة الإشارة المرجعية في البطولة.'
      : 'Tap the star on a match card or the bookmark on a competition.';

  String get language => _isArabic ? 'اللغة' : 'Language';
  String get darkMode => _isArabic ? 'الوضع الداكن' : 'Dark mode';
  String get notifications =>
      _isArabic ? 'إشعارات المباريات' : 'Match notifications';
  String get notificationsPrefsBody => _isArabic
      ? 'تنبيهات الأهداف والجولات (وضع تجريبي محلي فقط).'
      : 'Goals & kick-off alerts (local preference only for now).';
  String get pushNotificationsComingSoon =>
      _isArabic ? 'الإشعارات الفورية قريبًا.' : 'Push notifications coming soon.';
  String get matchDetails => _isArabic ? 'تفاصيل المباراة' : 'Match details';

  String get overview => _isArabic ? 'نظرة عامة' : 'Overview';
  String get stats => _isArabic ? 'الإحصائيات' : 'Stats';
  String get lineups => _isArabic ? 'التشكيلات' : 'Lineups';
  String get standings => _isArabic ? 'الترتيب' : 'Standings';
  String get teams => _isArabic ? 'الفرق' : 'Teams';
  String get topScorers => _isArabic ? 'الهدافون' : 'Top scorers';
  String get news => _isArabic ? 'الأخبار' : 'News';
  String get substitutes => _isArabic ? 'البدلاء' : 'Substitutes';
  String get coach => _isArabic ? 'المدرب' : 'Coach';
  String get recentMatches => _isArabic ? 'آخر المباريات' : 'Recent matches';
  String get appVersion => _isArabic ? 'إصدار التطبيق' : 'App version';
  String get about => _isArabic ? 'عن Kickora' : 'About Kickora';
  String get privacy =>
      _isArabic ? 'سياسة الخصوصية' : 'Privacy policy';
  String get terms => _isArabic ? 'شروط الاستخدام' : 'Terms of use';
  String get contactUs => _isArabic ? 'تواصل معنا' : 'Contact us';
  String get all => _isArabic ? 'عرض الكل' : 'See all';
  String get live => _isArabic ? 'مباشر' : 'LIVE';
  String get upcoming => _isArabic ? 'قادمة' : 'Upcoming';
  String get finished => _isArabic ? 'منتهية' : 'Finished';
  String get pullRefreshHint => _isArabic ? 'اسحب للتحديث' : 'Pull to refresh';

  String get retry => _isArabic ? 'إعادة المحاولة' : 'Retry';
  String get errorTitle => _isArabic ? 'حدث خطأ' : 'Something went wrong';
  String get errorSub => _isArabic
      ? 'تعذر تحميل البيانات. حاول مرة أخرى.'
      : 'We could not load the data. Please try again.';
}
