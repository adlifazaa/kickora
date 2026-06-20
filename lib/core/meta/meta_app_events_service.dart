import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Meta (Facebook) App Events — Android/iOS only; no-op on web/desktop.
///
/// Credentials live in native config (not Dart):
/// - Android: `android/app/src/main/res/values/strings.xml`
///   (`facebook_app_id`, `facebook_client_token`)
/// - AndroidManifest meta-data references those strings.
class MetaAppEventsService {
  MetaAppEventsService._();

  static final MetaAppEventsService instance = MetaAppEventsService._();

  static const String _firstLaunchKey = 'meta_app_events_first_launch_logged';

  final FacebookAppEvents _facebook = FacebookAppEvents();
  SharedPreferences? _prefs;
  bool _initialized = false;

  bool get isEnabled => _supportsMobile && _initialized;

  static bool get _supportsMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Call once during deferred startup (after [WidgetsFlutterBinding]).
  Future<void> initialize(SharedPreferences preferences) async {
    if (_initialized) return;
    _initialized = true;
    _prefs = preferences;

    if (!_supportsMobile) {
      if (kDebugMode) {
        debugPrint('[Kickora Meta] App Events disabled on this platform');
      }
      return;
    }

    try {
      await _facebook.setAutoLogAppEventsEnabled(true);
      if (kDebugMode) {
        debugPrint('[Kickora Meta] App Events SDK ready');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Meta] init error (swallowed): $e');
      }
    }
  }

  /// Standard Meta activate-app event (`fb_mobile_activate_app`).
  Future<void> logAppActivate() async {
    if (!_supportsMobile) return;
    try {
      // Package 0.19.x has no activateApp(); log the standard Meta event name.
      await _facebook.logEvent(name: 'fb_mobile_activate_app');
      await _logFirstLaunchIfNeeded();
      if (kDebugMode) {
        debugPrint('[Kickora Meta] fb_mobile_activate_app logged');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Meta] activateApp skipped: $e');
      }
    }
  }

  Future<void> _logFirstLaunchIfNeeded() async {
    final prefs = _prefs;
    if (prefs == null || prefs.getBool(_firstLaunchKey) == true) return;
    await prefs.setBool(_firstLaunchKey, true);
    try {
      await _facebook.logEvent(name: 'fb_mobile_first_time_launch');
      if (kDebugMode) {
        debugPrint('[Kickora Meta] first launch logged');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Meta] first launch skipped: $e');
      }
    }
  }

  Future<void> logSearch(int queryLength) async {
    if (queryLength <= 0) return;
    await _logEvent('search', {'query_length': queryLength});
  }

  Future<void> logMatchOpened(int matchId) async {
    if (matchId <= 0) return;
    await _logEvent('match_opened', {'match_id': matchId});
  }

  Future<void> logFavoriteAdded(String type, int id) async {
    final kind = type.trim().toLowerCase();
    if (kind.isEmpty || id <= 0) return;
    await _logEvent('favorite_added', {
      'favorite_type': kind,
      'item_id': id,
    });
  }

  Future<void> logNotificationEnabled() async {
    await _logEvent('notification_enabled');
  }

  Future<void> _logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    if (!_supportsMobile) return;
    try {
      final payload = <String, dynamic>{};
      for (final entry in parameters.entries) {
        final value = entry.value;
        if (value == null) continue;
        if (value is String || value is num) {
          payload[entry.key] = value;
        } else {
          payload[entry.key] = value.toString();
        }
      }
      await _facebook.logEvent(
        name: name,
        parameters: payload.isEmpty ? null : payload,
      );
      if (kDebugMode) {
        debugPrint('[Kickora Meta] event=$name params=$payload');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Meta] event $name skipped: $e');
      }
    }
  }
}
