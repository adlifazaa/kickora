import '../../../core/constants/api_constants.dart';
import '../../../core/constants/api_mode.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../football_api_envelope.dart';

/// Shared GET client for football remote data (direct or backend proxy).
abstract class FootballRemoteClient {
  bool get isConfigured;

  Future<FootballApiEnvelope> get(
    String path, {
    Map<String, String>? queryParameters,
  });
}

/// API-Football direct (`KICKORA_API_KEY` via dart-define only).
class DirectApiFootballClient implements FootballRemoteClient {
  DirectApiFootballClient({ApiClient? client})
      : _client = client ??
            ApiClient(
              baseUrl: ApiConstants.apiFootballBaseUrl,
              apiKey: ApiConstants.apiKey,
              mode: ApiMode.directApi,
            );

  final ApiClient _client;

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  Future<FootballApiEnvelope> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    if (!isConfigured) throw const ApiException.notConfigured();
    final raw = await _client.get(path, queryParameters: queryParameters);
    return FootballApiEnvelope.from(raw);
  }
}

/// Kickora backend proxy (no API key in Flutter).
class BackendProxyFootballClient implements FootballRemoteClient {
  BackendProxyFootballClient({ApiClient? client})
      : _client = client ??
            ApiClient(
              baseUrl: ApiConstants.backendBaseUrl,
              apiKey: '',
              mode: ApiMode.backendProxy,
            );

  final ApiClient _client;

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  Future<FootballApiEnvelope> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    if (!isConfigured) throw const ApiException.notConfigured();
    final raw = await _client.get(path, queryParameters: queryParameters);
    return FootballApiEnvelope.from(raw);
  }
}
