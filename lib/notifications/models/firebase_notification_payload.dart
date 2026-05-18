import 'kickora_notification.dart';
import 'notification_type.dart';

/// Shape of FCM `data` payloads (Firebase SDK not required at runtime).
class FirebaseNotificationPayload {
  const FirebaseNotificationPayload({
    required this.type,
    this.title,
    this.body,
    this.matchId,
    this.teamId,
    this.competitionId,
    this.topic,
    this.homeTeam,
    this.awayTeam,
    this.minute,
    this.score,
    this.raw = const {},
  });

  final NotificationType type;
  final String? title;
  final String? body;
  final int? matchId;
  final int? teamId;
  final int? competitionId;
  final String? topic;
  final String? homeTeam;
  final String? awayTeam;
  final String? minute;
  final String? score;
  final Map<String, dynamic> raw;

  factory FirebaseNotificationPayload.fromData(Map<String, dynamic> data) {
    final type =
        NotificationTypeX.fromWireValue(data['type']?.toString()) ??
            NotificationType.matchStarted;

    return FirebaseNotificationPayload(
      type: type,
      title: data['title']?.toString(),
      body: data['body']?.toString(),
      matchId: _intOrNull(data['matchId'] ?? data['fixture_id']),
      teamId: _intOrNull(data['teamId'] ?? data['team_id']),
      competitionId: _intOrNull(data['competitionId'] ?? data['league_id']),
      topic: data['topic']?.toString(),
      homeTeam: data['homeTeam']?.toString(),
      awayTeam: data['awayTeam']?.toString(),
      minute: data['minute']?.toString(),
      score: data['score']?.toString(),
      raw: Map<String, dynamic>.from(data),
    );
  }

  KickoraNotification toKickoraNotification({bool isArabic = false}) {
    final resolvedTitle = title ?? _defaultTitle(isArabic);
    final resolvedBody = body ?? _defaultBody(isArabic);

    return KickoraNotification(
      id: '${type.wireValue}_${matchId ?? teamId ?? DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: resolvedTitle,
      body: resolvedBody,
      matchId: matchId,
      teamId: teamId,
      competitionId: competitionId,
      payload: raw.map((k, v) => MapEntry(k, '$v')),
    );
  }

  String _defaultTitle(bool isArabic) {
    switch (type.canonical) {
      case NotificationType.matchStarted:
        return isArabic ? 'المباراة تبدأ قريبًا' : 'Match starting soon';
      case NotificationType.goalScored:
        return isArabic ? 'هدف!' : 'Goal!';
      case NotificationType.redCard:
        return isArabic ? 'بطاقة حمراء' : 'Red card';
      case NotificationType.matchFinished:
        return isArabic ? 'نهاية المباراة' : 'Match finished';
      case NotificationType.halftime:
        return isArabic ? 'استراحة' : 'Half time';
      case NotificationType.favoriteTeamUpdate:
        return isArabic ? 'مباراة فريقك المفضل' : 'Favorite team update';
      default:
        return isArabic ? 'Kickora' : 'Kickora';
    }
  }

  String _defaultBody(bool isArabic) {
    final teams = [homeTeam, awayTeam].whereType<String>().join(' vs ');
    if (teams.isEmpty) {
      return isArabic ? 'اضغط لمشاهدة التفاصيل' : 'Tap to view details';
    }
    if (score != null && score!.isNotEmpty) {
      return '$teams · $score';
    }
    if (minute != null && minute!.isNotEmpty) {
      return '$teams · $minute';
    }
    return teams;
  }

  static int? _intOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
