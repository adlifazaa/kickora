import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/notifications/fcm_message_parser.dart';
import 'package:kickora/notifications/models/notification_type.dart';

void main() {
  test('parses goal from data with inferred match topic', () {
    final message = RemoteMessage(
      data: const {
        'type': 'goal_scored',
        'matchId': '42',
        'title': 'Goal!',
        'body': '1-0',
      },
    );
    final payload = FcmMessageParser.parse(message);
    expect(payload.type, NotificationType.goalScored);
    expect(payload.matchId, 42);
    expect(payload.topic, 'match_42');
  });

  test('resolves topic from FCM from /topics/ path', () {
    final message = RemoteMessage(
      from: '/topics/team_7',
      data: const {'type': 'favorite_team_update', 'teamId': '7'},
    );
    final payload = FcmMessageParser.parse(message);
    expect(payload.topic, 'team_7');
    expect(payload.teamId, 7);
  });

  test('parses favorite competition and match update types', () {
    final competition = RemoteMessage(
      data: const {
        'type': 'favorite_competition_update',
        'competitionId': '39',
      },
    );
    final match = RemoteMessage(
      data: const {
        'type': 'favorite_match_update',
        'matchId': '1001',
      },
    );
    expect(
      FcmMessageParser.parse(competition).type,
      NotificationType.favoriteCompetitionUpdate,
    );
    expect(
      FcmMessageParser.parse(match).type,
      NotificationType.favoriteMatchUpdate,
    );
  });

  test('explicit topic in data wins', () {
    final message = RemoteMessage(
      from: '/topics/match_1',
      data: const {
        'type': 'match_started',
        'topic': 'competition_5',
        'competitionId': '5',
      },
    );
    final payload = FcmMessageParser.parse(message);
    expect(payload.topic, 'competition_5');
  });
}
