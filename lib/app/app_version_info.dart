import 'package:package_info_plus/package_info_plus.dart';

/// Cached app version from the built package (pubspec / platform metadata).
class AppVersionInfo {
  AppVersionInfo._();

  static PackageInfo? _cached;

  static Future<PackageInfo> load() async {
    return _cached ??= await PackageInfo.fromPlatform();
  }

  static String shortLabel(PackageInfo info) =>
      'v${info.version} · ${info.appName}';

  static String fullLabel(PackageInfo info) =>
      'v${info.version} · build ${info.buildNumber}';
}
