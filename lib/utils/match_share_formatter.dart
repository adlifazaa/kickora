import '../data/models/match_model.dart';
import '../widgets/api_display_text.dart';

const String matchSharePlayStoreUrl =
    'play.google.com/store/apps/details?id=com.kickora.worldcup';

const String matchShareFooter =
    'تابع نتائج المباريات والبطولات عبر Kickora | كأس العالم 2026';

const String matchShareDownloadLine = '📲 حمّل Kickora:';

/// Builds Arabic-friendly plain text for the native share sheet.
String buildMatchShareText(MatchModel match) {
  final home = _shareName(match.homeTeam.name);
  final away = _shareName(match.awayTeam.name);

  final lines = <String>[];

  if (match.status == MatchStatus.upcoming) {
    lines.add('⚽ $home ضد $away');
    final schedule = _formatUpcomingSchedule(match);
    if (schedule.isNotEmpty) {
      lines.add('🕐 الموعد: $schedule');
    }
  } else {
    final score = _ltr('${match.homeScore}-${match.awayScore}');
    lines.add('⚽ $home $score $away');
    final dateTime = _formatShareDate(match);
    if (dateTime.isNotEmpty) {
      lines.add('📅 $dateTime');
    }
  }

  final competition = _shareName(match.competition.name);
  if (competition.isNotEmpty) {
    lines.add('🏆 البطولة: $competition');
  }

  final venue = _shareName(match.stadium);
  if (venue.isNotEmpty) {
    lines.add('📍 الملعب: $venue');
  }

  lines.add(matchShareFooter);
  if (!lines.any((line) => line.contains(matchSharePlayStoreUrl))) {
    lines.add(matchShareDownloadLine);
    lines.add(matchSharePlayStoreUrl);
  }
  return lines.join('\n');
}

/// Wraps Latin API names so mixed Arabic/LTR text shares cleanly.
String _shareName(String? value) {
  return _ltr(sanitizeApiDisplayText(value));
}

String _ltr(String text) {
  if (text.isEmpty) return text;
  if (!RegExp(r'[A-Za-z0-9]').hasMatch(text)) return text;
  return '\u2066$text\u2069';
}

String _formatUpcomingSchedule(MatchModel match) {
  final date = _formatShareDate(match);
  final kickoff = sanitizeApiDisplayText(match.timeLabel);
  final time = kickoff.isNotEmpty ? _ltr(kickoff) : '';

  if (date.isNotEmpty && time.isNotEmpty) {
    return '$date — $time';
  }
  return date.isNotEmpty ? date : time;
}

String _formatShareDate(MatchModel match) {
  final date = match.date;
  if (date.year < 2000) return '';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final datePart = _ltr('$day/$month/${date.year}');

  if (match.status == MatchStatus.upcoming) {
    return datePart;
  }

  if (date.hour != 0 || date.minute != 0) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$datePart — ${_ltr('$hour:$minute')}';
  }

  return datePart;
}
