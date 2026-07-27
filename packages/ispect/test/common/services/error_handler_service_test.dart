import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

class _ThrowingDiagnostic implements Exception {
  const _ThrowingDiagnostic();

  @override
  String toString() => throw StateError('THROWING_TOSTRING_SECRET');
}

final class _CountingDiagnostic implements Exception {
  _CountingDiagnostic(this.message);

  final String message;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return message;
  }
}

final class _CountingStackTrace implements StackTrace {
  _CountingStackTrace(this.message);

  final String message;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return message;
  }
}

final class _CountingError extends Error {
  _CountingError(this.message);

  final String message;
  int calls = 0;

  @override
  String toString() {
    calls++;
    return message;
  }
}

final class _CountingDiagnosticsNode extends DiagnosticsNode {
  _CountingDiagnosticsNode()
      : super(
          name: 'hostile',
          style: DiagnosticsTreeStyle.singleLine,
        );

  int descriptionCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    return super.runtimeType;
  }

  @override
  Object? get value => null;

  @override
  List<DiagnosticsNode> getChildren() => const [];

  @override
  List<DiagnosticsNode> getProperties() => const [];

  @override
  String toDescription({TextTreeConfiguration? parentConfiguration}) {
    descriptionCalls++;
    return _oversizedDiagnosticText('DESCRIPTION_FORMATTER_SECRET');
  }

  @override
  String toString({
    TextTreeConfiguration? parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.info,
  }) {
    toStringCalls++;
    return _oversizedDiagnosticText('NODE_FORMATTER_SECRET');
  }
}

String _oversizedDiagnosticText(String secret) => '$secret${''.padRight(
      LogExportOutput.maxPreparedValueBytes * 2,
      'x',
    )}';

Iterable<String> _unboundedLines() sync* {
  var index = 0;
  while (true) {
    yield 'password=STACK_FILTER_SECRET_$index';
    index++;
  }
}

Iterable<DiagnosticsNode> _unboundedInformation() sync* {
  var index = 0;
  while (true) {
    yield ErrorDescription('password=INFORMATION_SECRET_$index');
    index++;
  }
}

ISpectLogger _logger() =>
    ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));

void main() {
  tearDown(ISpectRedaction.reset);

  group('ErrorHandlerService.handleZoneError', () {
    late ISpectLogger logger;

    setUp(() => logger = _logger());
    tearDown(() => logger.dispose());

    ErrorHandlerService service({List<String> filters = const []}) =>
        ErrorHandlerService(logger: logger, filters: filters);

    test('logs sanitized copies of the thrown object and stack trace', () {
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
      expect(entry.exception, isNot(same(exception)));
      expect('${entry.exception}', 'Exception');
      expect(entry.stackTrace, isNot(same(stack)));
      expect(
        '${entry.stackTrace}',
        JsonValueNormalizer.unprintableValue,
      );
      expect(entry.message, 'Zoned error caught');
    });

    test('redacts the log while forwarding the original uncaught value', () {
      const exception = 'https://api.example.test/users?token=ZONE_SECRET';
      Object? forwarded;

      service().handleZoneError(
        exception,
        StackTrace.fromString(
          'https://api.example.test/stack?token=STACK_SECRET',
        ),
        onZonedError: null,
        onUncaughtError: (error, _) => forwarded = error,
        isUncaughtErrorsHandlingEnabled: true,
      );

      final entry = logger.history.single;
      expect(forwarded, same(exception));
      expect('${entry.exception}', isNot(contains('ZONE_SECRET')));
      expect('${entry.stackTrace}', isNot(contains('STACK_SECRET')));
    });

    test('keeps host callback values while sanitizing retained diagnostics',
        () {
      Object? forwarded;
      StackTrace? forwardedStack;

      service().handleZoneError(
        'password=CALLBACK_SECRET',
        StackTrace.fromString(
          'file:///Users/alice/project/auth.dart:12:3',
        ),
        onZonedError: null,
        onUncaughtError: (error, stack) {
          forwarded = error;
          forwardedStack = stack;
        },
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect('$forwarded', contains('CALLBACK_SECRET'));
      expect('$forwardedStack', contains('/Users/alice'));
      expect(
        logger.history.single.textMessage,
        isNot(contains('/Users/alice')),
      );
    });

    test('does not call an exception formatter that throws', () {
      const exception = _ThrowingDiagnostic();
      Object? forwarded;

      expect(
        () => service().handleZoneError(
          exception,
          StackTrace.current,
          onZonedError: null,
          onUncaughtError: (error, _) => forwarded = error,
          isUncaughtErrorsHandlingEnabled: true,
        ),
        returnsNormally,
      );

      expect(forwarded, same(exception));
      expect(
        logger.history.single.exception.toString(),
        'Exception',
      );
      expect(
        logger.history.single.toString(),
        isNot(contains('THROWING_TOSTRING_SECRET')),
      );
    });

    test('redacts Error text while preserving the Error log type', () {
      final error = _CountingError(
        _oversizedDiagnosticText(
          'failed https://api.example.test/users?token=ERROR_SECRET',
        ),
      );
      Object? forwarded;

      service().handleZoneError(
        error,
        StackTrace.current,
        onZonedError: null,
        onUncaughtError: (value, _) => forwarded = value,
        isUncaughtErrorsHandlingEnabled: true,
      );

      final entry = logger.history.single;
      expect(error.calls, 0);
      expect(forwarded, isA<Error>());
      expect(forwarded, same(error));
      expect(entry.error, isA<Error>());
      expect(entry.error, isNot(same(error)));
      expect('${entry.error}', isNot(contains('ERROR_SECRET')));
      expect(
        LogExportOutput.utf8Length('${entry.error}'),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(entry.exception, isNull);
    });

    test('bounds logged diagnostics after an explicit global opt-out', () {
      ISpectRedaction.enabled = false;
      const exception = _TestException(
        'https://api.example.test/users?token=ZONE_RAW',
      );
      final stack = StackTrace.fromString(
        'https://api.example.test/stack?token=STACK_RAW',
      );

      service().handleZoneError(
        exception,
        stack,
        onZonedError: null,
        onUncaughtError: (error, forwardedStack) {
          expect(error, same(exception));
          expect(forwardedStack, same(stack));
        },
        isUncaughtErrorsHandlingEnabled: true,
      );

      final entry = logger.history.single;
      expect(entry.exception, isNot(same(exception)));
      expect(entry.stackTrace, isNot(same(stack)));
      expect('${entry.exception}', 'Exception');
      expect(
        '${entry.stackTrace}',
        JsonValueNormalizer.unprintableValue,
      );
    });

    test('forwards the original value to onZonedError before logging', () {
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

    test('does not inspect host callback values while logging a safe copy', () {
      final diagnostic = _CountingDiagnostic(
        _oversizedDiagnosticText('password=STATEFUL_DIAGNOSTIC_SECRET'),
      );
      final stack = _CountingStackTrace(
        _oversizedDiagnosticText('STACK_FORMATTER_SECRET'),
      );
      Object? zonedValue;
      Object? uncaughtValue;

      service().handleZoneError(
        diagnostic,
        stack,
        onZonedError: (error, _) => zonedValue = error,
        onUncaughtError: (error, _) => uncaughtValue = error,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(diagnostic.calls, 0);
      expect(stack.calls, 0);
      expect(zonedValue, same(diagnostic));
      expect(uncaughtValue, same(diagnostic));
      expect(
        LogExportOutput.utf8Length(
          '${logger.history.single.exception}',
        ),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(
        LogExportOutput.utf8Length('${logger.history.single.stackTrace}'),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('drops oversized string diagnostics before retention', () {
      final exception = _oversizedDiagnosticText(
        'password=OVERSIZED_DIAGNOSTIC_SECRET',
      );
      Object? forwarded;

      service().handleZoneError(
        exception,
        StackTrace.empty,
        onZonedError: null,
        onUncaughtError: (error, _) => forwarded = error,
        isUncaughtErrorsHandlingEnabled: true,
      );

      final entry = logger.history.single;
      expect(forwarded, same(exception));
      expect(entry.message, 'Zoned error caught');
      expect(entry.exception, isNull);
      expect(
        LogExportOutput.utf8Length(entry.message!),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(
        entry.textMessage,
        isNot(contains('OVERSIZED_DIAGNOSTIC_SECRET')),
      );
    });

    test('keeps filters from executing diagnostic formatters', () {
      final diagnostic = _CountingDiagnostic('FILTER_FORMATTER_SECRET');
      final stack = _CountingStackTrace('STACK_FILTER_FORMATTER_SECRET');

      service(
        filters: const [
          'FILTER_FORMATTER_SECRET',
          'STACK_FILTER_FORMATTER_SECRET',
        ],
      ).handleZoneError(
        diagnostic,
        stack,
        onZonedError: null,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(diagnostic.calls, 0);
      expect(stack.calls, 0);
      expect(logger.history, hasLength(1));
    });

    test('filters against a non-executing diagnostic family snapshot', () {
      final diagnostic = _CountingDiagnostic('unreachable');

      service(filters: const ['Exception']).handleZoneError(
        diagnostic,
        StackTrace.empty,
        onZonedError: null,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(diagnostic.calls, 0);
      expect(logger.history, isEmpty);
    });

    test('bounds logged opt-out objects without inspecting formatters', () {
      ISpectRedaction.enabled = false;
      final diagnostic = _CountingDiagnostic(
        _oversizedDiagnosticText('RAW_DIAGNOSTIC_SECRET'),
      );
      final stack = _CountingStackTrace(
        _oversizedDiagnosticText('RAW_STACK_SECRET'),
      );
      Object? forwarded;
      StackTrace? forwardedStack;

      service().handleZoneError(
        diagnostic,
        stack,
        onZonedError: null,
        onUncaughtError: (error, trace) {
          forwarded = error;
          forwardedStack = trace;
        },
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(diagnostic.calls, 0);
      expect(stack.calls, 0);
      expect(forwarded, same(diagnostic));
      expect(forwardedStack, same(stack));
      expect(logger.history.single.exception, isNot(same(diagnostic)));
      expect(logger.history.single.stackTrace, isNot(same(stack)));
      expect(
        '${logger.history.single.exception}',
        'Exception',
      );
      expect(
        '${logger.history.single.stackTrace}',
        JsonValueNormalizer.unprintableValue,
      );
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
        'boom',
        StackTrace.current,
        onZonedError: null,
        onUncaughtError: (_, __) => notified = true,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(logger.history, isEmpty);
      expect(notified, isFalse);
    });

    test('matches filters against bounded pre-redaction string text', () {
      service(filters: const ['token=FILTER_SECRET']).handleZoneError(
        'https://api.example.test?token=FILTER_SECRET',
        StackTrace.current,
        onZonedError: null,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(logger.history, isEmpty);
    });

    test('does not inspect stack text while applying filters', () {
      service(filters: const ['/Users/alice/private.dart']).handleZoneError(
        const _TestException('different'),
        StackTrace.fromString('/Users/alice/private.dart:1'),
        onZonedError: null,
        onUncaughtError: null,
        isUncaughtErrorsHandlingEnabled: true,
      );

      expect(logger.history, hasLength(1));
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

    test('FlutterError.onError logs sanitized diagnostic copies', () {
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
      expect(entry.exception, isNot(same(exception)));
      expect('${entry.exception}', 'Exception');
      expect(entry.stackTrace, isNot(same(stack)));
      expect(
        '${entry.stackTrace}',
        JsonValueNormalizer.unprintableValue,
      );
    });

    test('FlutterError.onError forwards the original details', () {
      FlutterErrorDetails? received;

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onFlutterError: (details, _) => received = details,
      );

      const details = FlutterErrorDetails(
        exception: 'https://example.test?token=FLUTTER_CALLBACK_SECRET',
      );
      FlutterError.onError!(details);

      expect(received, same(details));
    });

    test('FlutterError.onError preserves host diagnostic callbacks', () {
      FlutterErrorDetails? received;
      var stackFilterCalled = false;

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onFlutterError: (details, _) => received = details,
      );

      final details = FlutterErrorDetails(
        exception: const _TestException('failure'),
        stack: StackTrace.fromString('package:example/safe.dart:1'),
        context: ErrorDescription('password=CONTEXT_SECRET'),
        stackFilter: (lines) {
          stackFilterCalled = true;
          return [...lines, 'token=FILTER_SECRET'];
        },
        informationCollector: () => <DiagnosticsNode>[
          ErrorDescription('password=INFO_SECRET'),
        ],
      );
      FlutterError.onError!(details);

      expect(received, same(details));
      expect(stackFilterCalled, isFalse);
      expect(received!.stackFilter, same(details.stackFilter));
      expect(
        received!.informationCollector,
        same(details.informationCollector),
      );
    });

    test('does not execute host DiagnosticsNode formatters', () {
      FlutterErrorDetails? received;
      final context = _CountingDiagnosticsNode();
      final information = _CountingDiagnosticsNode();

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onFlutterError: (details, _) => received = details,
      );

      final details = FlutterErrorDetails(
        exception: 'diagnostic node',
        context: context,
        informationCollector: () => [information],
      );
      final contextRuntimeTypeCalls = context.runtimeTypeCalls;
      FlutterError.onError!(details);

      expect(received, same(details));
      expect(context.descriptionCalls, 0);
      expect(context.runtimeTypeCalls, contextRuntimeTypeCalls);
      expect(context.toStringCalls, 0);
      expect(information.descriptionCalls, 0);
      expect(information.toStringCalls, 0);
    });

    test('does not iterate host stack filters or diagnostic information', () {
      FlutterErrorDetails? received;

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onFlutterError: (details, _) => received = details,
      );

      final details = FlutterErrorDetails(
        exception: const _TestException('bounded diagnostics'),
        stackFilter: (_) => _unboundedLines(),
        informationCollector: _unboundedInformation,
      );
      FlutterError.onError!(details);

      expect(received, same(details));
    });

    test('does not consume a throwing host diagnostic iterable', () {
      FlutterErrorDetails? received;

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onFlutterError: (details, _) => received = details,
      );

      Iterable<String> throwingLines() sync* {
        yield 'safe';
        throw StateError('iterator failed');
      }

      final details = FlutterErrorDetails(
        exception: const _TestException('throwing diagnostics'),
        stackFilter: (_) => throwingLines(),
      );
      expect(() => FlutterError.onError!(details), returnsNormally);

      expect(received, same(details));
    });

    testWidgets('presentError logs details.exception after the frame',
        (tester) async {
      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterErrorHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
      );

      await tester.pumpWidget(const SizedBox());

      const exception = _TestException('present');
      FlutterError.presentError(
        const FlutterErrorDetails(exception: exception),
      );
      // The handler defers logging to a post-frame callback; a settled tree
      // won't schedule a frame on its own, so request one explicitly to flush.
      tester.binding.scheduleFrame();
      await tester.pump();

      final entry = logger.history
          .singleWhere((e) => e.message == 'Flutter error presented');
      expect(entry.exception, isNot(same(exception)));
      expect('${entry.exception}', 'Exception');
    });

    testWidgets('presentError forwards original callback details',
        (tester) async {
      FlutterErrorDetails? received;
      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterErrorHandlingEnabled: false,
          isPlatformDispatcherHandlingEnabled: false,
        ),
        onPresentError: (details, _) => received = details,
      );
      await tester.pumpWidget(const SizedBox());

      final details = FlutterErrorDetails(
        exception: 'password=PRESENT_CALLBACK_SECRET',
        stack: StackTrace.fromString(
          'file:///Users/alice/project/present.dart:1:1',
        ),
      );
      FlutterError.presentError(details);
      tester.binding.scheduleFrame();
      await tester.pump();

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
      expect(entry.exception, isNot(same(exception)));
      expect('${entry.exception}', 'Exception');
    });

    test('PlatformDispatcher.onError forwards original callback values', () {
      final original = PlatformDispatcher.instance.onError;
      addTearDown(() => PlatformDispatcher.instance.onError = original);
      Object? callbackError;
      StackTrace? callbackStack;

      ErrorHandlerService(logger: logger, filters: const []).setupErrorHandling(
        options: const ISpectErrorHandlerOptions(
          isFlutterPresentHandlingEnabled: false,
          isFlutterErrorHandlingEnabled: false,
        ),
        onPlatformDispatcherError: (error, stack) {
          callbackError = error;
          callbackStack = stack;
        },
      );

      const error = 'https://example.test?token=PLATFORM_CALLBACK_SECRET';
      final stack = StackTrace.fromString(
        'https://example.test?token=PLATFORM_STACK_SECRET',
      );
      PlatformDispatcher.instance.onError!(error, stack);

      expect(callbackError, same(error));
      expect(callbackStack, same(stack));
    });

    test('dispose restores every handler owned by the service', () {
      var presentCalls = 0;
      var flutterCalls = 0;
      var platformCalls = 0;
      final previousPlatform = PlatformDispatcher.instance.onError;
      void hostPresent(FlutterErrorDetails _) => presentCalls++;
      void hostFlutter(FlutterErrorDetails _) => flutterCalls++;
      bool hostPlatform(Object _, StackTrace __) {
        platformCalls++;
        return false;
      }

      FlutterError.presentError = hostPresent;
      FlutterError.onError = hostFlutter;
      PlatformDispatcher.instance.onError = hostPlatform;
      addTearDown(() {
        PlatformDispatcher.instance.onError = previousPlatform;
      });
      ErrorHandlerService(logger: logger, filters: const [])
        ..setupErrorHandling(
          options: const ISpectErrorHandlerOptions(),
        )
        ..dispose();

      expect(identical(FlutterError.presentError, hostPresent), isTrue);
      expect(identical(FlutterError.onError, hostFlutter), isTrue);
      expect(
        identical(PlatformDispatcher.instance.onError, hostPlatform),
        isTrue,
      );
      FlutterError.presentError(
        const FlutterErrorDetails(exception: 'present'),
      );
      FlutterError.onError!(
        const FlutterErrorDetails(exception: 'flutter'),
      );
      final handled = PlatformDispatcher.instance.onError!(
        'platform',
        StackTrace.empty,
      );
      expect(presentCalls, 1);
      expect(flutterCalls, 1);
      expect(platformCalls, 1);
      expect(handled, isFalse);
    });

    test('dispose does not overwrite a handler installed later', () {
      final handler = ErrorHandlerService(logger: logger, filters: const [])
        ..setupErrorHandling(
          options: const ISpectErrorHandlerOptions(
            isFlutterPresentHandlingEnabled: false,
            isPlatformDispatcherHandlingEnabled: false,
          ),
        );
      void replacement(FlutterErrorDetails _) {}
      FlutterError.onError = replacement;

      handler.dispose();

      expect(identical(FlutterError.onError, replacement), isTrue);
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

    test('redacts sensitive values from captured print lines', () {
      runThroughZone(
        'request failed https://api.example.test/users?token=PRINT_SECRET',
      );

      expect(logger.history.single.message, isNot(contains('PRINT_SECRET')));
    });

    test('uses the current global policy for captured print lines', () {
      final configuredService = RedactionService(
        sensitiveKeys: const {'global_field'},
        placeholder: '<global>',
      );
      ISpectRedaction.configure(service: configuredService);

      runThroughZone('global_field=PRINT_RAW');

      expect(logger.history.single.message, 'global_field=<global>');
      expect(ISpectRedaction.service, same(configuredService));
    });

    test('keeps captured print lines raw after a global opt-out', () {
      ISpectRedaction.enabled = false;

      runThroughZone(
        'request failed https://api.example.test/users?token=PRINT_RAW',
      );

      expect(logger.history.single.message, contains('PRINT_RAW'));
    });

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
