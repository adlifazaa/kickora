import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Decides which errors are real app bugs vs expected remote image/network noise.
///
/// CDN logos, player photos, and news thumbnails fail often (timeouts, DNS,
/// TLS, 404). [CachedNetworkImage] already shows fallbacks — those failures
/// must not inflate Crashlytics fatal crash counts.
class CrashReportFilter {
  CrashReportFilter._();

  /// True when [details] should be sent to Crashlytics as a fatal Flutter error.
  static bool shouldReportFlutterErrorAsFatal(FlutterErrorDetails details) {
    if (isBenignNetworkFailure(details.exception)) return false;
    if (_isImageResourceFlutterError(details)) return false;
    return true;
  }

  /// True when a platform/async error should be reported as fatal.
  static bool shouldReportPlatformErrorAsFatal(
    Object error,
    StackTrace stack,
  ) {
    if (isBenignNetworkFailure(error)) return false;
    if (_stackSuggestsImageLoad(stack)) return false;
    return true;
  }

  /// Socket/timeouts/DNS/HTTP client failures — never fatal crashes.
  @visibleForTesting
  static bool isBenignNetworkFailure(Object? error) {
    if (error == null) return false;
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HandshakeException) return true;
    if (error is TlsException) return true;
    if (error is HttpException) return true;
    // package:http ClientException without a direct dependency.
    if (error.runtimeType.toString() == 'ClientException') return true;

    final text = error.toString().toLowerCase();
    if (text.contains('failed host lookup')) return true;
    if (text.contains('connection abort')) return true;
    if (text.contains('connection refused')) return true;
    if (text.contains('connection reset')) return true;
    if (text.contains('network is unreachable')) return true;
    if (text.contains('http request failed')) return true;
    if (text.contains('software caused connection abort')) return true;
    return false;
  }

  static bool _isImageResourceFlutterError(FlutterErrorDetails details) {
    final library = details.library?.toLowerCase() ?? '';
    if (library.contains('image resource service')) return true;

    final summary = details.summary.toString().toLowerCase();
    if (summary.contains('image provider') ||
        summary.contains('image stream') ||
        summary.contains('failed to load') ||
        summary.contains('networkimage')) {
      return true;
    }

    if (library.contains('painting library') && summary.contains('image')) {
      return true;
    }

    return _stackSuggestsImageLoad(details.stack);
  }

  static bool _stackSuggestsImageLoad(StackTrace? stack) {
    if (stack == null) return false;
    final text = stack.toString().toLowerCase();
    return text.contains('cached_network_image') ||
        text.contains('networkimage') ||
        text.contains('image resource service') ||
        text.contains('_network_image') ||
        text.contains('multiframeimagestreamcompleter') ||
        text.contains('multi_image_stream_completer');
  }
}
