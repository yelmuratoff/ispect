import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _ThrowingRedactor extends RedactionService {
  _ThrowingRedactor([this.message = 'boom']);

  final String message;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    throw StateError(message);
  }
}

class _Harness with NetworkRedactionMixin {
  _Harness(
    this.logger, {
    required this.enableRedaction,
    required this.redactor,
    this.captureMode = DiagnosticCaptureMode.balanced,
  });

  @override
  final ISpectLogger logger;

  @override
  final bool enableRedaction;

  @override
  final DiagnosticCaptureMode captureMode;

  @override
  RedactionService redactor;
}

final class _NullJsonBody {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    return null;
  }

  @override
  String toString() {
    toStringCalls++;
    return 'NULL-JSON-BODY-SECRET';
  }
}

final class _HostileUri implements Uri {
  int pathCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    return Uri.parse('https://spoofed.example.test').runtimeType;
  }

  @override
  String get path {
    pathCalls++;
    throw StateError('HOSTILE_URI_PATH');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_URI_STRING');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('HOSTILE_URI_MEMBER');
}

void main() {
  group('NetworkRedactionMixin URL snapshots', () {
    late _Harness harness;

    setUp(() {
      harness = _Harness(
        FakeISpectLogger(),
        enableRedaction: true,
        redactor: RedactionService(),
      );
    });

    test('redacts URL text parsed inside the trusted snapshot boundary', () {
      final result = harness.redactUrlSnapshot(
        NetworkUriSnapshot.fromTrustedText(
          'https://example.test/private?token=secret',
        ),
        useRedaction: true,
      );

      expect(result.url, isNot(contains('secret')));
      expect(result.path, '/private');
    });

    test('captures and redacts an ordinary SDK Uri by default', () {
      final result = harness.redactUrlAndPath(
        Uri.parse('https://example.test/private?token=secret'),
        useRedaction: true,
      );

      expect(result.url, isNot(contains('secret')));
      expect(result.path, '/private');
    });

    for (final useRedaction in [true, false]) {
      test(
        'never invokes hostile Uri members when redaction is $useRedaction',
        () {
          final uri = _HostileUri();
          final strictHarness = _Harness(
            FakeISpectLogger(),
            enableRedaction: true,
            redactor: RedactionService(),
            captureMode: DiagnosticCaptureMode.strict,
          );

          final result = strictHarness.redactUrlAndPath(
            uri,
            useRedaction: useRedaction,
          );

          expect(result.url, JsonValueNormalizer.unprintableValue);
          expect(result.path, JsonValueNormalizer.unprintableValue);
          expect(uri.toStringCalls, 0);
          expect(uri.pathCalls, 0);
          expect(uri.runtimeTypeCalls, 0);
        },
      );
    }

    test('bounds oversized trusted URL text with redaction enabled and off',
        () {
      final snapshot = NetworkUriSnapshot.fromTrustedText(
        'https://example.test/${'x' * (4 * 1024 * 1024)}?token=secret',
      );

      for (final useRedaction in [true, false]) {
        final result = harness.redactUrlSnapshot(
          snapshot,
          useRedaction: useRedaction,
        );

        expect(
          result.url.length,
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
        expect(
          result.path.length,
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
      }
    });
  });

  group('NetworkRedactionMixin.processMapData', () {
    late FakeISpectLogger logger;

    setUp(() => logger = FakeISpectLogger());

    test('fails closed to a placeholder when redaction throws', () {
      const secret = 'REDACTION-FAILURE-SECRET';
      final harness = _Harness(
        logger,
        enableRedaction: true,
        redactor: _ThrowingRedactor(secret),
      );

      final result = harness.processMapData(
        {'password': 'super-secret', 'token': 'abc123'},
        useRedaction: true,
      );

      expect(result, {'raw': redactionFailedPlaceholder});
      expect(result.values, isNot(contains('super-secret')));
      expect(result.values, isNot(contains('abc123')));
      final warning = logger.byLogLevel(LogLevel.warning).single;
      expect(warning.textMessage, isNot(contains(secret)));
      expect(warning.exception, isNull);
      expect(warning.error, isNull);
      expect(warning.stackTrace, isNull);
    });

    test('returns the data when redaction is disabled', () {
      final harness = _Harness(
        logger,
        enableRedaction: false,
        redactor: _ThrowingRedactor(),
      );

      final result = harness.processMapData(
        {'name': 'value'},
        useRedaction: false,
      );

      expect(result, {'name': 'value'});
    });
  });

  group('NetworkRedactionMixin.safeRedact', () {
    test('does not retain a redaction exception or its stack', () {
      const secret = 'SAFE-REDACT-FAILURE-SECRET';
      final logger = FakeISpectLogger();
      final harness = _Harness(
        logger,
        enableRedaction: true,
        redactor: _ThrowingRedactor(secret),
      );

      final result = harness.safeRedact(
        {'password': 'payload-secret'},
        useRedaction: true,
      );

      expect(result, redactionFailedPlaceholder);
      final warning = logger.byLogLevel(LogLevel.warning).single;
      expect(warning.textMessage, isNot(contains(secret)));
      expect(warning.textMessage, isNot(contains('payload-secret')));
      expect(warning.exception, isNull);
      expect(warning.error, isNull);
      expect(warning.stackTrace, isNull);
    });

    test('does not execute DTO normalization while redaction is active', () {
      final body = _NullJsonBody();
      final harness = _Harness(
        FakeISpectLogger(),
        enableRedaction: true,
        redactor: RedactionService(),
        captureMode: DiagnosticCaptureMode.strict,
      );

      final result = harness.safeRedact(body, useRedaction: true);

      expect(result, isA<String>());
      expect(result, isNot(contains('NULL-JSON-BODY-SECRET')));
      expect(body.toJsonCalls, 0);
      expect(body.toStringCalls, 0);
    });

    test('uses a safe DTO descriptor when redaction is disabled', () {
      final body = _NullJsonBody();
      final harness = _Harness(
        FakeISpectLogger(),
        enableRedaction: false,
        redactor: RedactionService(),
        captureMode: DiagnosticCaptureMode.strict,
      );

      final result = harness.safeRedact(body, useRedaction: false);

      expect(result, isA<String>());
      expect(result, isNot(contains('NULL-JSON-BODY-SECRET')));
      expect(body.toJsonCalls, 0);
      expect(body.toStringCalls, 0);
    });

    test('balanced null DTO snapshot never falls back to the raw object', () {
      final body = _NullJsonBody();
      final harness = _Harness(
        FakeISpectLogger(),
        enableRedaction: false,
        redactor: RedactionService(),
      );

      final result = harness.safeRedact(body, useRedaction: false);

      expect(result, JsonValueNormalizer.unprintableValue);
      expect(body.toJsonCalls, 1);
      expect(body.toStringCalls, 0);
    });

    test('uses the current redactor for every payload', () {
      final harness = _Harness(
        FakeISpectLogger(),
        enableRedaction: true,
        redactor: RedactionService(
          sensitiveKeys: const {'tenant_secret'},
          placeholder: '<FIRST>',
        ),
      );

      expect(
        harness.safeRedact(
          {'tenant_secret': 'value'},
          useRedaction: true,
        ),
        {'tenant_secret': '<FIRST>'},
      );

      harness.redactor = RedactionService(
        sensitiveKeys: const {'tenant_secret'},
        placeholder: '<SECOND>',
      );

      expect(
        harness.safeRedact(
          {'tenant_secret': 'value'},
          useRedaction: true,
        ),
        {'tenant_secret': '<SECOND>'},
      );
    });
  });
}
