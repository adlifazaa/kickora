import '../ad_remote_config.dart';
import '../ad_unit_ids.dart';

/// Interstitials are disabled for Kickora MVP (stub kept for legacy imports).
class InterstitialAdManager {
  InterstitialAdManager(AdRemoteConfig config);

  void updateConfig(AdRemoteConfig config) {}

  String get unitId => AdUnitIds.interstitial;

  Future<void> preload() async {}

  Future<bool> showIfAllowed() async => false;

  Future<void> dispose() async {}
}
