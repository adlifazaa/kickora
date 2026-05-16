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
          'API key is not configured. Using local mock data.',
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

  final String message;
  final int? statusCode;
  final String? code;
  final Object? cause;

  bool get isNotConfigured => code == 'not_configured';

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (code != null) buffer.write(' [$code]');
    return buffer.toString();
  }
}
