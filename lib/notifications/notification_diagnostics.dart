import 'dart:convert';
import 'dart:io';

import '../core/constants/api_constants.dart';

class NotificationDiagnosticsSnapshot {
  const NotificationDiagnosticsSnapshot({
    required this.subscribedTeamIds,
    required this.subscribedMatchIds,
    required this.subscribedCompetitionIds,
    required this.subscribedTopicCount,
    required this.subscribedTopicNames,
  });

  final Set<int> subscribedTeamIds;
  final Set<int> subscribedMatchIds;
  final Set<int> subscribedCompetitionIds;
  final int subscribedTopicCount;
  final List<String> subscribedTopicNames;
}

/// Safe backend notification worker status (public endpoint only).
class BackendNotificationStatus {
  const BackendNotificationStatus({
    required this.ok,
    this.enabled,
    this.dryRun,
    this.realFcmActive,
    this.notificationsSent,
    this.lastPollAt,
    this.lastPollError,
    this.fetchError,
    this.worldCupScopeOnly,
  });

  final bool ok;
  final bool? enabled;
  final bool? dryRun;
  final bool? realFcmActive;
  final int? notificationsSent;
  final String? lastPollAt;
  final String? lastPollError;
  final String? fetchError;
  final bool? worldCupScopeOnly;

  factory BackendNotificationStatus.fromJson(Map<String, dynamic> json) {
    final stats = json['lastPollStats'];
    return BackendNotificationStatus(
      ok: json['ok'] == true,
      enabled: json['enabled'] as bool?,
      dryRun: json['dryRun'] as bool?,
      realFcmActive: json['realFcmActive'] as bool?,
      notificationsSent: stats is Map
          ? (stats['notificationsSent'] as num?)?.toInt()
          : null,
      lastPollAt: json['lastPollAt']?.toString(),
      lastPollError: json['lastPollError']?.toString(),
      worldCupScopeOnly: json['worldCupScopeOnly'] as bool?,
    );
  }

  factory BackendNotificationStatus.error(String message) {
    return BackendNotificationStatus(ok: false, fetchError: message);
  }
}

Future<BackendNotificationStatus> fetchBackendNotificationStatus() async {
  try {
    final base = ApiConstants.backendBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/notifications/status');
    final client = HttpClient();
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 12));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      return BackendNotificationStatus.error(
        'HTTP ${response.statusCode}',
      );
    }
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      return BackendNotificationStatus.error('Invalid JSON');
    }
    return BackendNotificationStatus.fromJson(json);
  } catch (e) {
    return BackendNotificationStatus.error(e.toString());
  }
}
