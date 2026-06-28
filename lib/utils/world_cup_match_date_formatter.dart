import 'api_datetime.dart';

/// Bilingual date/time labels for World Cup match cards.
class WorldCupMatchDateFormatter {
  WorldCupMatchDateFormatter._();

  static const _arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const _englishMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _arabicWeekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const _englishWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Card line: Arabic "الجمعة 13 يونيو" / English "Fri, Jun 13".
  static String formatMatchDate(DateTime date, {required bool isArabic}) {
    final local = ApiDateTime.toLocalKickoff(date);
    if (local.year < 2000) return '';
    final weekday = local.weekday - 1;
    final month = local.month - 1;
    if (isArabic) {
      return '${_arabicWeekdays[weekday]} ${local.day} ${_arabicMonths[month]}';
    }
    return '${_englishWeekdays[weekday]}, ${_englishMonths[month]} ${local.day}';
  }

  /// Short numeric fallback: 13/06/2026
  static String formatNumericDate(DateTime date) {
    final local = ApiDateTime.toLocalKickoff(date);
    if (local.year < 2000) return '';
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  /// Schedule section header key (date-only grouping).
  static String dateGroupKey(DateTime date) => ApiDateTime.localDateKey(date);

  /// Header for grouped schedule sections.
  static String formatDateHeader(DateTime date, {required bool isArabic}) {
    final label = formatMatchDate(date, isArabic: isArabic);
    if (label.isNotEmpty) return label;
    return formatNumericDate(date);
  }

  /// Kickoff time from [timeLabel] or [date] hour/minute.
  static String formatKickoffTime(MatchDateTimeInput input) {
    final label = input.timeLabel.trim();
    if (label.isNotEmpty &&
        label.toLowerCase() != 'ft' &&
        !label.endsWith("'") &&
        label.contains(':')) {
      return label;
    }
    if (input.date.hour == 0 && input.date.minute == 0) return label;
    return ApiDateTime.formatClock(input.date);
  }
}

/// Lightweight input for time formatting without importing [MatchModel] here.
class MatchDateTimeInput {
  const MatchDateTimeInput({
    required this.date,
    required this.timeLabel,
  });

  final DateTime date;
  final String timeLabel;
}
