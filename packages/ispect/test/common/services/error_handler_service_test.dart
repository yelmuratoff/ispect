import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/services/error_handler_options.dart';
import 'package:ispect/src/common/services/error_handler_service.dart';
import 'package:ispectify/ispectify.dart';

class _TestException implements Exception {
  const _TestException(this.message);
  final String message;
  @override
  String toString() => 'TestException: $message';
}

ISpectLogger _logger() =>
    ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));

void main() {
  group('ErrorHandlerService.handleZoneError', () {
    late ISpectLogger logger;

    setUp(() => logger = _logger());
    tearDown(() => logger.dispose());

    ErrorHandlerService service({List<String> filters = const []}) =>
        ErrorHandlerService(logger: logger, filters: filters);

    test('logs the real thrown object and its stack trace', () {
      const exception = _TestException('boom');
      final stack = StackTrace.current;

      service().handleZoneError(
        exception,
        stack,
        onZonedError: null,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      final entry = logger.history.single;
      expect(entry.exception, same(exception));
      expect(entry.stackTrace, same(stack));
      expect(entry.message, 'Zoned error caught');
    });

    test('forwards to onZonedError before logging', () {
      Object? received;
      const exception = _TestException('boom');

      service().handleZoneError(
        exception,
        StackTrace.current,
        onZonedError: (e, _) => received = e,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(received, same(exception));
    });

    test('notifies onUncaughtError with the error and stack when enabled', () {
      Object? error;
      StackTrace? stack;
      final source = StackTrace.current;

      service().handleZoneError(
        const _TestException('boom'),
        source,
        onZonedError: null,
        onUncaughtError: (e, s) {
          error = e;
          stack = s;
        },
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(error, isA<_TestException>());
      expect(stack, same(source));
    });

    test('skips onUncaughtError when uncaught handling is disabled', () {
      var called = false;

      service().handleZoneError(
        const _TestException('boom'),
        StackTrace.current,
        onZonedError: null,
        onUncaughtError: (_, __) => called = true,
        isUncaughtErrorsHandlingEnabled: false,
      );

      expect(called, isFalse);
      expect(logger.history, hasLength(1));
    });

    test('suppresses logging and notification when a filter matches', () {
      var notified = false;

      service(filters: ['boom']).handleZoneError(
        const _TestException('boom'),
        StackTrace.current,
        onZonedError: null,
        onUncaughtError: (_, __) => notified = true,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(logger.history, isEmpty);
      expect(notified, isFalse);
    });

    test('logs when no filter matches the message or stack', () {
      service(filters: ['unrelated']).handleZoneError(
        const _TestException('boom'),
        StackTrace.current,
        onZonedError: null,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(logger.history, hasLength(1));
    });
  });

  group('ErrorHandlerService Flutter/platform handlers', () {
    late ISpectLogger logger;
    FlutterExceptionHandler? originalOnError;
    late FlutterExceptionHandler originalPresentError;

    setUp(() {
      logger = _logger();
      originalOnError = FlutterError.onError;
      originalPresentError = FlutterError.presentError;
    });

    tearDown(() {
      FlutterError.onError = originalOnError;
      FlutterError.presentError = originalPresentError;
      logger.dispose();
    });

    List<ISpectLogData> errorEntries() => logger.history
        .where((e) => e.message == 'Flutter error caught')
        .toList();

    test('FlutterError.onError logs details.exception, not a string', () {
      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
      );

      const exception = _TestException('flutter');
      final stack = StackTrace.current;
      FlutterError.onError!(
        FlutterErrorDetails(exception: exception, stack: stack),
      );

      final entry = errorEntries().single;
      expect(entry.exception, same(exception));
      expect(entry.stackTrace, same(stack));
    });

    test('FlutterError.onError forwards to onFlutterError', () {
      FlutterErrorDetails? received;

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onFlutterError: (details, _) => received = details,
      );

      const details = FlutterErrorDetails(exception: _TestException('flutter'));
      FlutterError.onError!(details);

      expect(received, same(details));
    });

    test('PlatformDispatcher.onError logs the error and returns true', () {
      final original = PlatformDispatcher.instance.onError;
      addTearDown(() => PlatformDispatcher.instance.onError = original);

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isFlutterErrorHandlingEnabled: false,
        ),
      );

      const exception = _TestException('platform');
      final handled = PlatformDispatcher.instance.onError!(
        exception,
        StackTrace.current,
      );

      expect(handled, isTrue);
      final entry = logger.history
          .singleWhere((e) => e.message == 'Platform error caught');
      expect(entry.exception, same(exception));
    });
  });

  group('ErrorHandlerService.handleZonePrint', () {
    late ISpectLogger logger;

    setUp(() => logger = _logger());
    tearDown(() => logger.dispose());

    // `ZoneDelegate` is `final` and cannot be faked, so route the line through
    // a real forked zone whose `print` spec hands the service the genuine
    // delegate/parent it would receive in production.
    void runThroughZone(String line) {
      runZoned(
        // ignore: avoid_print
        () => print(line),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, printed) {
            ErrorHandlerService(logger: logger, filters: const [])
                .handleZonePrint(
              zone,
              parent,
              zone,
              printed,
              isPrintLoggingEnabled: true,
              isFlutterPrintEnabled: false,
            );
          },
        ),
      );
    }

    test('routes plain lines through the logger when print logging is on', () {
      runThroughZone('hello');

      expect(logger.history.single.message, 'hello');
    });

    test('keeps ANSI-colored lines out of the logger', () {
      runThroughZone('\x1B[31mred\x1B[0m');

      expect(logger.history, isEmpty);
    });
  });
}
