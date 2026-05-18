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

  String get searchEmptyTitle =>
      _isArabic ? 'ابدأ البحث' : 'Start searching';
  String get searchEmptySubtitle => _isArabic
      ? 'اكتب اسم بطولة أو فريق أو لاعب لتبدأ.'
      : 'Type a competition, team, or player name to begin.';
  String get recentSearches =>
      _isArabic ? 'عمليات البحث الأخيرة' : 'Recent searches';
  String get clearAll => _isArabic ? 'مسح الكل' : 'Clear';

  String get language => _isArabic ? 'اللغة' : 'Language';
  String get darkMode => _isArabic ? 'الوضع الداكن' : 'Dark mode';
  String get notifications =>
      _isArabic ? 'إشعارات المباريات' : 'Match notifications';
  String get notificationsPrefsBody => _isArabic
      ? 'اختر أنواع التنبيهات التي تريد استلامها.'
      : 'Choose which alerts you want to receive.';
  String get pushNotificationsComingSoon => _isArabic
      ? 'الإشعارات الذكية للمباريات قريبًا'
      : 'Smart match notifications coming soon';

  String get featuredBadge => _isArabic ? 'مميزة' : 'FEATURED';

  String get competitionsSubtitle => _isArabic
      ? 'اكتشف أهم البطولات حول العالم'
      : 'Discover top leagues around the world';

  String get homeFeaturedLiveSubtitle =>
      _isArabic ? 'أبرز ما يحدث الآن' : 'The top live action';

  String matchesCountLabel(int count) =>
      _isArabic ? '$count مباراة' : '$count matches';

  String competitionTeamsCount(int count) =>
      _isArabic ? '$count فريق' : '$count Teams';

  String competitionMatchesToday(int count) => _isArabic
      ? '$count مباراة اليوم'
      : '$count Matches Today';

  String get featuredCompetitionTitle =>
      _isArabic ? 'بطولة مميزة' : 'Featured competition';

  String get aboutTagline =>
      _isArabic ? 'صُمم لعشاق كرة القدم' : 'Built for football fans';

  String get aboutFooter => _isArabic
      ? '© Kickora 2026 · بدعم من Sugarkeys Apps'
      : '© Kickora 2026 · Powered by Sugarkeys Apps';

  String get categoryAll => _isArabic ? 'الكل' : 'All';

  String get categoryFavorites => _isArabic ? 'المفضلة' : 'Favorites';
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
  String get liveMatchesSeeAllTitle =>
      _isArabic ? 'المباريات المباشرة' : 'Live matches';
  String get liveMatchesSearchHint => _isArabic
      ? 'ابحث عن فريق أو بطولة…'
      : 'Search team or competition…';
  String get liveMatchesSearchEmpty => _isArabic
      ? 'لا توجد نتائج لهذا البحث'
      : 'No matches match your search';
  String get live => _isArabic ? 'مباشر' : 'LIVE';
  String get upcoming => _isArabic ? 'قادمة' : 'Upcoming';
  String get finished => _isArabic ? 'منتهية' : 'Finished';
  String get pullRefreshHint => _isArabic ? 'اسحب للتحديث' : 'Pull to refresh';

  String get removeAdsTitle =>
      _isArabic ? 'إزالة الإعلانات' : 'Remove ads';

  String get removeAdsHeadline => _isArabic
      ? 'استمتع بـ Kickora بدون إعلانات'
      : 'Enjoy Kickora without ads';

  String get removeAdsSubtitle => _isArabic
      ? 'تجربة أنظف للمباريات والبطولات والتفاصيل.'
      : 'A cleaner experience across matches, leagues, and details.';

  String get removeAdsSettingsSubtitle => _isArabic
      ? 'اشترك أو جرّب مجانًا — الدفع قريبًا'
      : 'Subscribe or try free — payments coming soon';

  String get premiumActiveTitle =>
      _isArabic ? 'أنت مشترك مميز' : 'You are Premium';

  String get premiumActiveSubtitle => _isArabic
      ? 'الإعلانات مخفية في كل أنحاء التطبيق.'
      : 'Ads are hidden throughout the app.';

  String get subscriptionPlansTitle =>
      _isArabic ? 'اختر خطتك' : 'Choose your plan';

  String get startFreeTrial =>
      _isArabic ? 'ابدأ التجربة المجانية (٧ أيام)' : 'Start free trial (7 days)';

  String get restorePurchases =>
      _isArabic ? 'استعادة المشتريات' : 'Restore purchases';

  String get paymentsComingSoonMessage => _isArabic
      ? 'الدفع غير مفعّل بعد — قريبًا'
      : 'Payments are not active yet — coming soon';

  String get trialStartedMessage => _isArabic
      ? 'تم تفعيل التجربة المجانية محليًا'
      : 'Free trial activated locally';

  String get restoreUnavailableMessage => _isArabic
      ? 'لا توجد مشتريات لاستعادتها بعد'
      : 'No purchases to restore yet';

  String get restoreSuccessMessage => _isArabic
      ? 'تمت الاستعادة'
      : 'Purchases restored';

  String get subscriptionLegalNote => _isArabic
      ? 'الأسعار للعرض فقط. الاشتراك يتجدد تلقائيًا عند التفعيل لاحقًا.'
      : 'Prices shown for preview. Subscriptions will auto-renew when billing goes live.';

  String premiumExpiresLabel(DateTime at) {
    final d = '${at.day}/${at.month}/${at.year}';
    return _isArabic ? 'ينتهي في $d' : 'Renews / expires $d';
  }

  String get refreshingLabel =>
      _isArabic ? 'جاري التحديث…' : 'Refreshing…';

  String updatedLabel(DateTime? at) {
    if (at == null) {
      return _isArabic ? 'اسحب للتحديث' : pullRefreshHint;
    }
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 45) {
      return _isArabic ? 'تم التحديث للتو' : 'Updated just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return _isArabic
          ? 'آخر تحديث منذ $m د'
          : 'Updated $m min ago';
    }
    final h = diff.inHours;
    return _isArabic ? 'آخر تحديث منذ $h س' : 'Updated $h h ago';
  }

  String get timelineEmptyTitle =>
      _isArabic ? 'لا توجد أحداث بعد' : 'No events yet';

  String get timelineEmptySubtitle => _isArabic
      ? 'ستظهر الأهداف والبطاقات والتبديلات هنا.'
      : 'Goals, cards, and substitutions will appear here.';

  String get timelineKickOff => _isArabic ? 'بداية المباراة' : 'Kick-off';

  String get timelineHalftime => _isArabic ? 'استراحة' : 'Halftime';

  String get timelineFulltime => _isArabic ? 'نهاية المباراة' : 'Full time';

  String timelineGoal(String player) =>
      _isArabic ? 'هدف — $player' : 'Goal — $player';

  String timelineOwnGoal(String player) =>
      _isArabic ? 'هدف ذاتي — $player' : 'Own goal — $player';

  String timelinePenalty(String player) =>
      _isArabic ? 'ركلة جزاء — $player' : 'Penalty — $player';

  String timelineYellowCard(String player) =>
      _isArabic ? 'بطاقة صفراء — $player' : 'Yellow card — $player';

  String timelineRedCard(String player) =>
      _isArabic ? 'بطاقة حمراء — $player' : 'Red card — $player';

  String timelineSubstitutionIn(String player) =>
      _isArabic ? 'دخول — $player' : 'Sub on — $player';

  String timelineSubstitution({required String playerIn, required String playerOut}) =>
      _isArabic
          ? '$playerIn بدلاً من $playerOut'
          : '$playerIn replaces $playerOut';

  String timelineAssist(String name) =>
      _isArabic ? 'تمريرة حاسمة: $name' : 'Assist: $name';

  String timelineVar(String label) =>
      _isArabic ? 'قرار VAR — $label' : 'VAR — $label';

  String get globalSearchTitle => _isArabic ? 'بحث' : 'Search';
  String get globalSearchHint => _isArabic
      ? 'ابحث عن فريق، لاعب، بطولة، أو مباراة…'
      : 'Search teams, players, competitions, matches…';
  String get globalSearchEmptySubtitle => _isArabic
      ? 'ابحث عن الفرق واللاعبين والبطولات والمباريات'
      : 'Search teams, players, competitions, and matches';
  String get searchFilterPlayers => _isArabic ? 'لاعبون' : 'Players';
  String get searchTypeTeam => _isArabic ? 'فريق' : 'Team';
  String get searchTypePlayer => _isArabic ? 'لاعب' : 'Player';
  String get searchTypeCompetition => _isArabic ? 'بطولة' : 'Competition';
  String get searchTypeMatch => _isArabic ? 'مباراة' : 'Match';

  String get retry => _isArabic ? 'إعادة المحاولة' : 'Retry';
  String get errorTitle => _isArabic ? 'حدث خطأ' : 'Something went wrong';
  String get errorSub => _isArabic
      ? 'تعذر تحميل البيانات. حاول مرة أخرى.'
      : 'We could not load the data. Please try again.';
}
