import '../network/api_debug_log.dart';
import 'api_constants.dart';
import 'api_developer_config.dart';
import 'api_mode.dart';
import 'api_production_guidance.dart';

/// Resolves and exposes the active football data mode (compile-time via dart-define).
class ApiModeService {
  ApiModeService._();

  static ApiMode get mode => ApiConstants.apiMode;

  static bool get isMock => ApiConstants.isMock;

  static bool get isDirectApi => ApiConstants.isDirectApi;

  static bool get isBackendProxy => ApiConstants.isBackendProxy;

  /// True when remote HTTP should be used (direct key or backend URL configured).
  static bool get usesRemoteApi => ApiConstants.hasRemoteApi;

  static String get effectiveBaseUrl => ApiConstants.effectiveBaseUrl;

  /// Label for developer console traces (`mock`, `directApi`, `backendProxy`).
  static String get effectiveDataSource => ApiDeveloperConfig.dataSourceLabel;

  static bool get remoteActive => ApiDeveloperConfig.remoteActive;

  static List<String> get configurationWarnings =>
      ApiDeveloperConfig.configurationWarnings;

  /// Boot-time developer summary + misconfiguration hints (debug console only).
  static void logConfiguration() {
    ApiDebugLog.boot();
    for (final message in ApiProductionGuidance.bootMessages()) {
      ApiDebugLog.configurationWarning(message);
    }
    for (final warning in configurationWarnings) {
      ApiDebugLog.configurationWarning(warning);
    }
  }

  /// Per-fetch trace: apiMode, dataSource, resultCount (debug console only).
  static void traceFetch({
    required String operation,
    required String dataSource,
    int? resultCount,
  }) {
    ApiDebugLog.developerTrace(
      operation: operation,
      dataSource: dataSource,
      resultCount: resultCount,
    );
  }
}
