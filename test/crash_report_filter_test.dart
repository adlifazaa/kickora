import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/firebase/crash_report_filter.dart';

void main() {
  group('CrashReportFilter.isBenignNetworkFailure', () {
    test('treats SocketException as benign', () {
      expect(
        CrashReportFilter.isBenignNetworkFailure(
          const SocketException('Failed host lookup'),
        ),
        isTrue,
      );
    });

    test('treats TimeoutException as benign', () {
      expect(
        CrashReportFilter.isBenignNetworkFailure(
          TimeoutException('image load'),
        ),
        isTrue,
      );
    });

    test('treats HttpException as benign', () {
      expect(
        CrashReportFilter.isBenignNetworkFailure(
          const HttpException('Connection closed'),
        ),
        isTrue,
      );
    });

    test('treats connection abort message as benign', () {
      expect(
        CrashReportFilter.isBenignNetworkFailure(
          Exception('Software caused connection abort'),
        ),
        isTrue,
      );
    });

    test('does not treat generic app exceptions as benign', () {
      expect(
        CrashReportFilter.isBenignNetworkFailure(
          StateError('bad widget state'),
        ),
        isFalse,
      );
    });
  });

  group('CrashReportFilter Flutter/platform routing', () {
    test('image resource service errors are not fatal', () {
      final details = FlutterErrorDetails(
        exception: Exception('HTTP request failed, statusCode: 404'),
        library: 'image resource service',
        stack: StackTrace.current,
      );
      expect(
        CrashReportFilter.shouldReportFlutterErrorAsFatal(details),
        isFalse,
      );
    });

    test('cached_network_image stack errors are not fatal', () {
      final details = FlutterErrorDetails(
        exception: const SocketException('Software caused connection abort'),
        library: 'image resource service',
        stack: StackTrace.fromString(
          '#0 MultiImageStreamCompleter.<anonymous closure> '
          '(package:cached_network_image/src/image_provider/'
          'multi_image_stream_completer.dart:47:9)',
        ),
      );
      expect(
        CrashReportFilter.shouldReportFlutterErrorAsFatal(details),
        isFalse,
      );
    });

    test('real widget errors remain fatal', () {
      final details = FlutterErrorDetails(
        exception: StateError('setState after dispose'),
        library: 'widgets library',
        stack: StackTrace.current,
      );
      expect(
        CrashReportFilter.shouldReportFlutterErrorAsFatal(details),
        isTrue,
      );
    });

    test('platform SocketException on image stack is not fatal', () {
      expect(
        CrashReportFilter.shouldReportPlatformErrorAsFatal(
          const SocketException('Connection abort'),
          StackTrace.fromString(
            '#0 CachedNetworkImage._load (package:cached_network_image/...)',
          ),
        ),
        isFalse,
      );
    });

    test('platform StateError remains fatal', () {
      expect(
        CrashReportFilter.shouldReportPlatformErrorAsFatal(
          StateError('null check'),
          StackTrace.current,
        ),
        isTrue,
      );
    });
  });
}
