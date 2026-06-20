import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../notifications/models/kickora_notification.dart';
import '../notifications/models/notification_permission_status.dart';
import '../notifications/models/notification_type.dart';
import '../notifications/notification_diagnostics.dart';
import '../widgets/section_header.dart';

/// Local notification diagnostics — no secrets or FCM token values exposed.
class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  State<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends State<NotificationDiagnosticsScreen> {
  BackendNotificationStatus? _backend;
  bool? _tokenAvailable;
  NotificationPermissionStatus? _permission;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final app = AppScope.of(context);
    final service = app.notificationService;
    final permission = await service.permissionStatus();
    final tokenOk = await service.hasFcmTokenAvailable();
    final backend = await fetchBackendNotificationStatus();
    if (!mounted) return;
    setState(() {
      _permission = permission;
      _tokenAvailable = tokenOk;
      _backend = backend;
      _loading = false;
    });
  }

  Future<void> _sendLocalTest() async {
    final app = AppScope.of(context);
    final text = AppText.of(context);
    if (!app.notificationsEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text.isArabic
              ? 'فعّل الإشعارات من الإعدادات أولاً.'
              : 'Enable notifications in Settings first.'),
        ),
      );
      return;
    }
    await app.notificationService.showLocal(
      KickoraNotification(
        id: 'diag_local_test',
        type: NotificationType.matchStarted,
        title: text.isArabic ? 'اختبار Kickora' : 'Kickora test',
        body: text.isArabic
            ? 'إشعار محلي للتشخيص — ليس من FCM.'
            : 'Local diagnostic notification — not from FCM.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);
    final diag = app.notificationService.diagnosticsSnapshot;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.isArabic ? 'تشخيص الإشعارات' : 'Notification diagnostics'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionHeader(
                  title: text.isArabic ? 'الجهاز' : 'Device',
                  icon: Icons.phone_android_rounded,
                ),
                const SizedBox(height: 10),
                _row(text.isArabic ? 'الإشعارات مفعّلة' : 'Notifications enabled',
                    app.notificationsEnabled ? '✓' : '✗'),
                _row(text.isArabic ? 'إذن النظام' : 'OS permission',
                    _permission?.name ?? '—'),
                _row(
                  text.isArabic ? 'Firebase متاح' : 'Firebase available',
                  app.notificationService.usesMockFirebase ? 'mock' : 'live',
                ),
                _row(
                  text.isArabic ? 'رمز FCM متوفر' : 'FCM token available',
                  _tokenAvailable == true ? '✓' : '✗',
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: text.isArabic ? 'الاشتراكات' : 'Subscriptions',
                  icon: Icons.topic_outlined,
                ),
                const SizedBox(height: 10),
                _row(text.isArabic ? 'فرق' : 'Teams',
                    diag.subscribedTeamIds.join(', ').isEmpty
                        ? '—'
                        : diag.subscribedTeamIds.join(', ')),
                _row(text.isArabic ? 'مباريات' : 'Matches',
                    diag.subscribedMatchIds.join(', ').isEmpty
                        ? '—'
                        : diag.subscribedMatchIds.join(', ')),
                _row(text.isArabic ? 'بطولات' : 'Competitions',
                    diag.subscribedCompetitionIds.join(', ').isEmpty
                        ? '—'
                        : diag.subscribedCompetitionIds.join(', ')),
                _row(text.isArabic ? 'مواضيع FCM' : 'FCM topics',
                    '${diag.subscribedTopicCount}'),
                if (diag.subscribedTopicNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      diag.subscribedTopicNames.join('\n'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: text.isArabic ? 'الخادم (Render)' : 'Backend (Render)',
                  icon: Icons.cloud_outlined,
                ),
                const SizedBox(height: 10),
                if (_backend?.fetchError != null)
                  _row('Error', _backend!.fetchError!)
                else ...[
                  _row('Worker enabled', '${_backend?.enabled}'),
                  _row('Dry run', '${_backend?.dryRun}'),
                  _row('Real FCM active', '${_backend?.realFcmActive}'),
                  _row('WC scope only', '${_backend?.worldCupScopeOnly}'),
                  _row(
                    text.isArabic ? 'إشعارات مُرسلة' : 'notificationsSent',
                    '${_backend?.notificationsSent ?? 0}',
                  ),
                  _row('lastPollAt', _backend?.lastPollAt ?? '—'),
                  if (_backend?.lastPollError != null)
                    _row('lastPollError', _backend!.lastPollError!),
                ],
                const SizedBox(height: 24),
                if (kDebugMode)
                  OutlinedButton.icon(
                    onPressed: _sendLocalTest,
                    icon: const Icon(Icons.notifications_none_rounded),
                    label: Text(text.isArabic
                        ? 'إرسال إشعار محلي للاختبار'
                        : 'Send local test notification'),
                  ),
                const SizedBox(height: 12),
                Text(
                  text.isArabic
                      ? 'للوصول: أضف مفضلة + فعّل الإشعارات + تأكد أن مواضيع team_/match_/competition_ مسجّلة.'
                      : 'Tip: favorite a team/match, enable notifications, verify team_/match_/competition_ topics.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
