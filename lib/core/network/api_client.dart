import 'dart:convert';
import 'dart:io';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

/// Thin HTTP client for football APIs. Uses `dart:io` only (no extra packages).
class ApiClient {
  ApiClient({
    String? baseUrl,
    String? apiKey,
    this.connectTimeout = ApiConstants.connectTimeout,
    this.receiveTimeout = ApiConstants.receiveTimeout,
  })  : _baseUrl = baseUrl ?? ApiConstants.baseUrl,
        _apiKey = apiKey ?? ApiConstants.apiKey;

  final String _baseUrl;
  final String _apiKey;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    if (!isConfigured) {
      throw const ApiException.notConfigured();
    }

    final uri = _buildUri(path, queryParameters);
    final client = HttpClient();
    client.connectionTimeout = connectTimeout;

    try {
      final request = await client.getUrl(uri).timeout(connectTimeout);
      _applyHeaders(request.headers);

      final response = await request.close().timeout(receiveTimeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Request failed',
          statusCode: response.statusCode,
          code: 'http_error',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const ApiException.parse('Expected JSON object response.');
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException.network(e.message);
    } on HttpException catch (e) {
      throw ApiException.network(e.message);
    } on FormatException catch (e) {
      throw ApiException.parse(e.message);
    } catch (e) {
      throw ApiException.network(e.toString());
    } finally {
      client.close(force: true);
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final base = Uri.parse(_baseUrl);
    final resolved = base.resolve(path.startsWith('/') ? path.substring(1) : path);
    return query == null || query.isEmpty
        ? resolved
        : resolved.replace(queryParameters: query);
  }

  void _applyHeaders(HttpHeaders headers) {
    headers.set(HttpHeaders.acceptHeader, 'application/json');
    headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    // TODO(api): Adjust header name per provider (API-Football uses x-apisports-key).
    headers.set(ApiConstants.headerApiKey, _apiKey);
  }
}
