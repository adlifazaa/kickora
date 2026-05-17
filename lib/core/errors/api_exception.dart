/// Typed failures from [ApiClient] / [FootballApiService].
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.cause,
  });

  const ApiException.notConfigured()
      : this(
          'API is not configured. Using local mock data.',
          code: 'not_configured',
        );

  const ApiException.network([String? detail])
      : this(
          detail ?? 'Network request failed.',
          code: 'network',
        );

  const ApiException.parse([String? detail])
      : this(
          detail ?? 'Failed to parse API response.',
          code: 'parse',
        );

  const ApiException.backendUnavailable([String? detail])
      : this(
          detail ?? 'Backend is temporarily unavailable.',
          code: 'backend_unavailable',
        );

  const ApiException.emptyResponse([String? detail])
      : this(
          detail ?? 'The server returned an empty response.',
          code: 'empty_response',
        );

  const ApiException.rateLimited([String? detail])
      : this(
          detail ?? 'Rate limit exceeded.',
          code: 'rate_limit',
        );

  final String message;
  final int? statusCode;
  final String? code;
  final Object? cause;

  bool get isNotConfigured => code == 'not_configured';

  bool get isRateLimited => code == 'rate_limit';

  bool get isBackendUnavailable => code == 'backend_unavailable';

  bool get isNetwork =>
      code == 'network' || code == 'timeout';

  bool get isEmptyResponse => code == 'empty_response';

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (code != null) buffer.write(' [$code]');
    return buffer.toString();
  }
}
