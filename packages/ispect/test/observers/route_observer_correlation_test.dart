import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  late ISpectLogger logger;

  setUp(() {
    logger = ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));
    ISpect.initialize(logger, force: true);
  });

  tearDown(() async {
    await ISpect.dispose();
    ISpectRedaction.reset();
  });

  String? correlationIdOf(ISpectLogData entry) =>
      entry.additionalData?[TraceKeys.correlationId] as String?;

  test(
    'pop shares the correlation id of the popped route push',
    () {
      final a = _route('/a');
      final b = _route('/b');
      ISpectNavigatorObserver()
        ..didPush(a, null)
        ..didPush(b, a)
        ..didPop(b, a);

      final routeLogs = logger.history
          .where((e) => e.key == ISpectLogType.route.key)
          .toList();
      expect(routeLogs, hasLength(3));
      final pushB = correlationIdOf(routeLogs[1]);
      expect(pushB, isNotNull);
      expect(correlationIdOf(routeLogs[2]), pushB);
      expect(correlationIdOf(routeLogs[0]), isNot(pushB));
    },
    skip: !kISpectEnabled
        ? 'Navigation capture requires ISPECT_ENABLED for this test.'
        : false,
  );

  test(
    'a throwing redaction service fails closed without escaping navigation',
    () {
      ISpectRedaction.configure(service: _ThrowingRedactionService());
      final observer = ISpectNavigatorObserver();
      final route = _route('/secret', arguments: {'note': 'RAW_ARG_VALUE'});

      expect(() => observer.didPush(route, null), returnsNormally);
      expect(logger.history, hasLength(2));
      expect(logger.history.last.message, isNot(contains('RAW_ARG_VALUE')));
      expect(
        observer.transitions.single.to?.routeType,
        redactionFailedPlaceholder,
      );
      expect(observer.transitions.single.arguments, redactionFailedPlaceholder);
    },
    skip: !kISpectEnabled
        ? 'Navigation capture requires ISPECT_ENABLED for this test.'
        : false,
  );
}

Route<dynamic> _route(String name, {Object? arguments}) =>
    MaterialPageRoute<void>(
      settings: RouteSettings(name: name, arguments: arguments),
      builder: (_) => const SizedBox.shrink(),
    );

final class _ThrowingRedactionService extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) => throw StateError('redaction failed');
}
