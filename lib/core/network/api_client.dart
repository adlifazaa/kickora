import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';
import 'request_throttler.dart';

/// HTTP client for API-Football with throttling, retries, and timeouts.
class ApiClient {
  ApiClient({
    String? baseUrl,
    String? apiKey,
    this.connectTimeout = ApiConstants.connectTimeout,
    this.receiveTimeout = ApiConstants.receiveTimeout,
    this.maxRetries = ApiConstants.maxRetries,
    RequestThrottler? throttler,
  })  : _baseUrl = baseUrl ?? ApiConstants.baseUrl,
        _apiKey = apiKey ?? ApiConstants.apiKey,
        _throttler = throttler ?? RequestThrottler();

  final String _baseUrl;
  final String _apiKey;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int maxRetries;
  final RequestThrottler _throttler;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    if (!isConfigured) {
      throw const ApiException.notConfigured();
    }

    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _throttler.run(
          () => _getOnce(path, queryParameters: queryParameters),
        );
      } on ApiException catch (e) {
        if (!_shouldRetry(e, attempt)) rethrow;
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }
  }

  Future<Map<String, dynamic>> _getOnce(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final client = HttpClient();
    client.connectionTimeout = connectTimeout;

    try {
      final request = await client.getUrl(uri).timeout(connectTimeout);
      _applyHeaders(request.headers);

      final response = await request.close().timeout(receiveTimeout);
      final body = await response.transform(utf8.decoder).join();

      final decoded = _decodeBody(body);
      _throwIfApiFootballErrors(decoded, response.statusCode);

      if (response.statusCode == 429) {
        throw const ApiException(
          'Rate limit exceeded.',
          statusCode: 429,
          code: 'rate_limit',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Request failed',
          statusCode: response.statusCode,
          code: 'http_error',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const ApiException.parse('Expected JSON object response.');
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException.network(e.message);
    } on HttpException catch (e) {
      throw ApiException.network(e.message);
    } on FormatException catch (e) {
      throw ApiException.parse(e.message);
    } on TimeoutException catch (_) {
      throw const ApiException(
        'Request timed out.',
        code: 'timeout',
      );
    } catch (e) {
      throw ApiException.network(e.toString());
    } finally {
      client.close(force: true);
    }
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

  void _throwIfApiFootballErrors(Object? decoded, int statusCode) {
    if (decoded is! Map<String, dynamic>) return;
    final errors = decoded['errors'];
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
    headers.set(ApiConstants.headerApiKey, _apiKey);
  }
}
