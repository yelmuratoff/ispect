import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

/// Strategy that always throws, simulating redaction failing mid-walk.
class _ThrowingStrategy implements RedactionStrategy {
  const _ThrowingStrategy();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      throw StateError('boom');
}

class _Harness with NetworkRedactionMixin {
  _Harness(
    this.logger, {
    required this.enableRedaction,
    required this.redactor,
  });

  @override
  final ISpectLogger logger;

  @override
  final bool enableRedaction;

  @override
  final RedactionService redactor;
}

void main() {
  group('NetworkRedactionMixin.processMapData', () {
    late FakeISpectLogger logger;

    setUp(() => logger = FakeISpectLogger());

    test('fails closed to a placeholder when redaction throws', () {
      final harness = _Harness(
        logger,
        enableRedaction: true,
        redactor: RedactionService(strategy: const _ThrowingStrategy()),
      );

      final result = harness.processMapData(
        {'password': 'super-secret', 'token': 'abc123'},
        useRedaction: true,
      );

      expect(result, {'raw': redactionFailedPlaceholder});
      expect(result.values, isNot(contains('super-secret')));
      expect(result.values, isNot(contains('abc123')));
      expect(logger.byLogLevel(LogLevel.warning), isNotEmpty);
    });

    test('returns the data when redaction is disabled', () {
      final harness = _Harness(
        logger,
        enableRedaction: false,
        redactor: RedactionService(strategy: const _ThrowingStrategy()),
      );

      final result = harness.processMapData(
        {'name': 'value'},
        useRedaction: false,
      );

      expect(result, {'name': 'value'});
    });
  });
}
