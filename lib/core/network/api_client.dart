import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/api_constants.dart';
import '../constants/api_mode.dart';
import '../errors/api_exception.dart';
import 'api_debug_log.dart';
import 'api_request_coordinator.dart';
import 'request_throttler.dart';

/// HTTP client for football data (API-Football direct or Kickora backend proxy).
class ApiClient {
  ApiClient({
    String? baseUrl,
    String? apiKey,
    ApiMode? mode,
    this.connectTimeout = ApiConstants.connectTimeout,
    this.receiveTimeout = ApiConstants.receiveTimeout,
    this.maxRetries = ApiConstants.maxRetries,
    RequestThrottler? throttler,
  })  : _mode = mode ?? ApiConstants.apiMode,
        _baseUrl = baseUrl ?? ApiConstants.effectiveBaseUrl,
        _apiKey = apiKey ?? ApiConstants.apiKey,
        _throttler = throttler ?? RequestThrottler();

  final ApiMode _mode;
  final String _baseUrl;
  final String _apiKey;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int maxRetries;
  final RequestThrottler _throttler;

  ApiMode get mode => _mode;

  bool get isConfigured {
    switch (_mode) {
      case ApiMode.directApi:
        return _apiKey.trim().isNotEmpty;
      case ApiMode.backendProxy:
        return _baseUrl.trim().isNotEmpty;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    if (!isConfigured) {
      throw const ApiException.notConfigured();
    }

    final dedupeKey = _dedupeKey(path, queryParameters);
    return ApiRequestCoordinator.instance.run(
      dedupeKey,
      () => _getWithRetry(path, queryParameters: queryParameters),
    );
  }

  Future<Map<String, dynamic>> _getWithRetry(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _throttler.run(
          () => _getOnce(path, queryParameters: queryParameters),
        );
      } on ApiException catch (e) {
        if (!_shouldRetry(e, attempt)) rethrow;
        ApiDebugLog.retry(path, attempt, e.code ?? 'unknown');
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }
  }

  Future<Map<String, dynamic>> _getOnce(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final requestId = ApiRequestCoordinator.instance.nextRequestId();
    final uri = _buildUri(path, queryParameters);
    ApiDebugLog.request('GET', uri, requestId: requestId);
    final client = HttpClient();
    client.connectionTimeout = connectTimeout;

    try {
      final request = await client.getUrl(uri).timeout(connectTimeout);
      _applyHeaders(request.headers);

      final response = await request.close().timeout(receiveTimeout);
      final body = await response.transform(utf8.decoder).join();

      final decoded = _decodeBody(body);
      _throwIfResponseErrors(decoded, response.statusCode);

      if (response.statusCode == 429) {
        ApiDebugLog.response(
          requestId: requestId,
          statusCode: 429,
          path: path,
          errorCode: 'rate_limit',
          dataSource: 'error',
        );
        throw const ApiException(
          'Rate limit exceeded.',
          statusCode: 429,
          code: 'rate_limit',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        ApiDebugLog.response(
          requestId: requestId,
          statusCode: response.statusCode,
          path: path,
          errorCode: 'http_error',
          dataSource: 'error',
        );
        throw ApiException(
          'Request failed',
          statusCode: response.statusCode,
          code: 'http_error',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const ApiException.parse('Expected JSON object response.');
      }

      final count = _resultCount(decoded);
      ApiDebugLog.response(
        requestId: requestId,
        statusCode: response.statusCode,
        path: path,
        results: count,
        dataSource: count == 0 ? 'empty' : 'api',
      );
      return decoded;
    } on ApiException catch (e) {
      ApiDebugLog.failure(path, e.code ?? 'api');
      rethrow;
    } on SocketException catch (e) {
      ApiDebugLog.failure(path, 'network');
      throw ApiException.network(e.message);
    } on HttpException catch (e) {
      ApiDebugLog.failure(path, 'network');
      throw ApiException.network(e.message);
    } on FormatException catch (e) {
      ApiDebugLog.failure(path, 'parse');
      throw ApiException.parse(e.message);
    } on TimeoutException catch (_) {
      ApiDebugLog.failure(path, 'timeout');
      throw const ApiException(
        'Request timed out.',
        code: 'timeout',
      );
    } catch (e) {
      ApiDebugLog.failure(path, 'network');
      throw ApiException.network(e.toString());
    } finally {
      client.close(force: true);
    }
  }

  static String _dedupeKey(String path, Map<String, String>? query) {
    if (query == null || query.isEmpty) return 'GET:$path';
    final entries = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final qs = entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'GET:$path?$qs';
  }

  int? _resultCount(Map<String, dynamic> decoded) {
    final results = decoded['results'];
    if (results is int) return results;
    if (results is num) return results.toInt();
    final response = decoded['response'];
    if (response is List) return response.length;
    final data = decoded['data'];
    if (data is List) return data.length;
    return null;
  }

  Object? _decodeBody(String body) {
    if (body.trim().isEmpty) {
      throw const ApiException.parse('Empty response body.');
    }
    try {
      return jsonDecode(body);
    } on FormatException catch (e) {
      throw ApiException.parse(e.message);
    }
  }

  void _throwIfResponseErrors(Object? decoded, int statusCode) {
    if (decoded is! Map<String, dynamic>) return;

    // API-Football / proxy: prefer usable rows when present.
    final response = decoded['response'];
    if (response is List && response.isNotEmpty) return;

    final data = decoded['data'];
    if (data is List && data.isNotEmpty) return;

    final errors = decoded['errors'] ?? decoded['error'];
    if (errors == null) return;
    if (errors is List && errors.isEmpty) return;
    if (errors is Map && errors.isEmpty) return;

    final message = errors is List
        ? errors.map((e) => e.toString()).join('; ')
        : errors.toString();

    if (message.toLowerCase().contains('rate limit')) {
      throw ApiException(
        message,
        statusCode: statusCode,
        code: 'rate_limit',
      );
    }

    throw ApiException(
      message.isEmpty ? 'API returned errors.' : message,
      statusCode: statusCode,
      code: 'api_error',
    );
  }

  bool _shouldRetry(ApiException e, int attempt) {
    if (attempt >= maxRetries) return false;
    if (e.isNotConfigured) return false;
    if (e.code == 'parse') return false;
    if (e.code == 'api_error') return false;
    return e.code == 'network' ||
        e.code == 'timeout' ||
        e.code == 'rate_limit' ||
        e.statusCode == 429 ||
        (e.statusCode != null && e.statusCode! >= 500);
  }

  Duration _retryDelay(int attempt) =>
      ApiConstants.retryBaseDelay * attempt;

  Uri _buildUri(String path, Map<String, String>? query) {
    final base = Uri.parse(_baseUrl);
    final resolved =
        base.resolve(path.startsWith('/') ? path.substring(1) : path);
    return query == null || query.isEmpty
        ? resolved
        : resolved.replace(queryParameters: query);
  }

  void _applyHeaders(HttpHeaders headers) {
    headers.set(HttpHeaders.acceptHeader, 'application/json');
    headers.set(HttpHeaders.contentTypeHeader, 'application/json');

    // TODO(production): Use backendProxy for store builds — never ship the sports API key in the app.
    if (_mode == ApiMode.directApi && _apiKey.trim().isNotEmpty) {
      headers.set(ApiConstants.headerApiKey, _apiKey);
    }
    // backendProxy: no x-apisports-key header from Flutter.
  }
}
