import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

// Test helpers

class RecordingLogger extends ISpectLogger {
  final List<ISpectLogData> records = <ISpectLogData>[];

  @override
  void logData(ISpectLogData log, {bool redact = true}) {
    records.add(log);
  }

  @override
  void warning(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    records.add(
      ISpectLogData(
        msg?.toString(),
        additionalData: additionalData,
        pen: pen,
      ),
    );
  }

  List<ISpectLogData> byOperation(String op) => records
      .where((r) => r.additionalData?[TraceKeys.operation] == op)
      .toList();
}

final _counterProvider = StateProvider<int>(
  (ref) => 0,
  name: 'counter',
);

final _failingProvider = Provider<int>(
  (ref) => throw StateError('boom'),
  name: 'failing',
);

final _unnamedProvider = Provider<int>((ref) => 42);

final _familyProvider = Provider.family<int, Object?>((ref, argument) => 1);

// Riverpod 2 marks Provider as sealed through metadata, but it is not sealed
// by the Dart type system. This test-only subtype models an implementer that
// overrides Object.runtimeType.
// ignore: subtype_of_sealed_class
final class _HostileRuntimeTypeProvider extends Provider<Object?> {
  _HostileRuntimeTypeProvider() : super((ref) => null);

  final List<int> _runtimeTypeCalls = <int>[0];

  int get runtimeTypeCalls => _runtimeTypeCalls.single;

  @override
  Type get runtimeType {
    _runtimeTypeCalls[0]++;
    throw StateError('tenantSecret=HOSTILE_PROVIDER_TYPE_SECRET');
  }
}

final class _HostileRuntimeTypeValue {
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('tenantSecret=HOSTILE_VALUE_TYPE_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_VALUE_TEXT_SECRET');
  }
}

final class _IterableProbe extends IterableBase<Object?> {
  int iteratorCalls = 0;

  @override
  Iterator<Object?> get iterator {
    iteratorCalls++;
    return const <Object?>['private-value'].iterator;
  }
}

final class _HostileArgument {
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('tenantSecret=HOSTILE_ARGUMENT_TYPE_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_ARGUMENT_SECRET');
  }
}

final class _ThrowingRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      throw StateError('tenantSecret=REDACTOR_FAILURE_SECRET');
}

final class _NullExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      null;
}

final class _ScalarExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      1;
}

final class _ExpandingRedactor extends RedactionService {
  _ExpandingRedactor()
      : expansion = List<String>.filled(2 * 1024 * 1024, 'x').join();

  final String expansion;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      <String, Object?>{'expansion': expansion};
}

final class _HostileMapRedactor extends RedactionService {
  _HostileMapRedactor(this.key, this.value);

  final Object key;
  final Object value;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      <Object, Object>{key: value};
}

final class _HostilePayload {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('tenantSecret=HOSTILE_PAYLOAD_JSON_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_PAYLOAD_TEXT_SECRET');
  }
}

final class _ReadablePayload {
  _ReadablePayload({
    required this.label,
    required this.password,
  });

  final String label;
  final String password;
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    return <String, Object?>{
      'label': label,
      'password': password,
    };
  }
}

final class _HostileException implements Exception {
  _HostileException({required this.throws});

  final bool throws;
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    if (throws) {
      throw StateError('tenantSecret=HOSTILE_EXCEPTION_SECRET');
    }
    return List<String>.filled(2 * 1024 * 1024, 'x').join();
  }
}

final class _HostileStackTrace implements StackTrace {
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('tenantSecret=HOSTILE_STACK_TYPE_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=HOSTILE_STACK_SECRET');
  }
}

void main() {
  group(
    'ISpectRiverpodObserver',
    () {
      late RecordingLogger logger;
      late ProviderContainer container;

      setUp(() {
        ISpectRedaction.reset();
        ISpectRiverpodObserver.debugEnabledOverride = true;
        logger = RecordingLogger();
        container = ProviderContainer();
      });

      tearDown(() {
        ISpectRedaction.reset();
        ISpectRiverpodObserver.debugEnabledOverride = null;
        container.dispose();
      });

      group('didAddProvider', () {
        test('enabled logger without consumers bypasses observer work', () {
          var filterCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectRiverpodObserver(
            logger: sinklessLogger,
            settings: ISpectRiverpodSettings(
              providerFilter: (_) {
                filterCalls++;
                return true;
              },
            ),
          ).didAddProvider(_counterProvider, 0, container);

          expect(filterCalls, 0);
          expect(sinklessLogger.history, isEmpty);
        });

        test('adapter callback remains active without a logger destination',
            () {
          var callbackCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectRiverpodObserver(
            logger: sinklessLogger,
            onProviderAdd: (_, __, ___) => callbackCalls++,
          ).didAddProvider(_counterProvider, 0, container);

          expect(callbackCalls, 1);
          expect(sinklessLogger.history, isEmpty);
        });

        test('logs provider initialization with riverpod-add key', () {
          ISpectRiverpodObserver(logger: logger)
              .didAddProvider(_counterProvider, 0, container);

          final logs = logger.byOperation('add');
          expect(logs, hasLength(1));
          expect(logs.single.key, ISpectLogType.riverpodAdd.key);
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.providerName], 'counter');
        });

        test('falls back to the provider type when it has no name', () {
          ISpectRiverpodObserver(logger: logger)
              .didAddProvider(_unnamedProvider, 42, container);

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.providerName], 'Provider<int>');
        });

        test('strict capture falls back to a coarse label', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(
              captureMode: DiagnosticCaptureMode.strict,
            ),
          ).didAddProvider(_unnamedProvider, 42, container);

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.providerName], 'Provider');
        });

        test('skips add log when printAdds disabled', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(printAdds: false),
          ).didAddProvider(_counterProvider, 0, container);

          expect(logger.byOperation('add'), isEmpty);
        });
      });

      group('didUpdateProvider', () {
        test('keeps update callback active without a logger destination', () {
          var callbackCalls = 0;
          final sinklessLogger = ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          );
          addTearDown(sinklessLogger.dispose);

          ISpectRiverpodObserver(
            logger: sinklessLogger,
            onProviderUpdate: (_, __, ___, ____) => callbackCalls++,
          ).didUpdateProvider(_counterProvider, 0, 1, container);

          expect(callbackCalls, 1);
          expect(sinklessLogger.history, isEmpty);
        });

        test('logs provider updates with riverpod-update key', () {
          ISpectRiverpodObserver(logger: logger)
              .didUpdateProvider(_counterProvider, 0, 1, container);

          final logs = logger.byOperation('update');
          expect(logs, hasLength(1));
          expect(logs.single.key, ISpectLogType.riverpodUpdate.key);
          final meta = logs.single.additionalData?[TraceKeys.meta]
              as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.providerName], 'counter');
        });

        test('skips update log when printUpdates disabled', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings.minimal,
          ).didUpdateProvider(_counterProvider, 0, 1, container);

          expect(logger.byOperation('update'), isEmpty);
        });

        test('respects updateFilter', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              updateFilter: (provider, previous, next) => next != 99,
            ),
          )
            ..didUpdateProvider(_counterProvider, 0, 99, container)
            ..didUpdateProvider(_counterProvider, 0, 1, container);

          expect(logger.byOperation('update'), hasLength(1));
        });
      });

      group('didDisposeProvider', () {
        test('logs provider disposal with riverpod-dispose key', () {
          ISpectRiverpodObserver(logger: logger)
              .didDisposeProvider(_counterProvider, container);

          final logs = logger.byOperation('dispose');
          expect(logs, hasLength(1));
          expect(logs.single.key, ISpectLogType.riverpodDispose.key);
        });

        test('skips dispose log when printDisposes disabled', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(printDisposes: false),
          ).didDisposeProvider(_counterProvider, container);

          expect(logger.byOperation('dispose'), isEmpty);
        });
      });

      group('providerDidFail', () {
        test('emits error trace with riverpod-fail key', () {
          final error = StateError('failed');
          Object? callbackError;
          ISpectRiverpodObserver(
            logger: logger,
            onProviderFail: (_, error, __, ___) => callbackError = error,
          ).providerDidFail(
            _failingProvider,
            error,
            StackTrace.current,
            container,
          );

          final logs = logger.byOperation('fail');
          expect(logs, hasLength(1));
          expect(logs.single.key, ISpectLogType.riverpodFail.key);
          expect(callbackError, same(error));
          expect(logs.single.error, isNot(same(error)));
          expect(logs.single.error.toString(), isNotEmpty);
          expect(
            logs.single.additionalData?[TraceKeys.success],
            isFalse,
          );
        });

        test('failure egress never invokes hostile diagnostic formatters', () {
          for (final throws in <bool>[true, false]) {
            logger.records.clear();
            final error = _HostileException(throws: throws);
            final stackTrace = _HostileStackTrace();

            expect(
              () => ISpectRiverpodObserver(
                logger: logger,
                settings: const ISpectRiverpodSettings(
                  captureMode: DiagnosticCaptureMode.strict,
                ),
              ).providerDidFail(
                _failingProvider,
                error,
                stackTrace,
                container,
              ),
              returnsNormally,
            );

            expect(error.toStringCalls, 0);
            expect(stackTrace.toStringCalls, 0);
            final record = logger.byOperation('fail').single;
            expect(
              LogExportOutput.utf8Length(
                jsonEncode(record.additionalData),
              ),
              lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
            );
          }
        });

        test('custom redactor scrubs error, stack, and trace text', () {
          const secret = 'CUSTOMER_CODE_SECRET';
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              redactor: RedactionService(
                sensitiveKeys: {'customerCode'},
              ),
            ),
          )
            ..didAddProvider(
              _counterProvider,
              const <String, Object?>{'customerCode': secret},
              container,
            )
            ..providerDidFail(
              _failingProvider,
              StateError('customerCode: $secret'),
              StackTrace.fromString('customerCode=$secret'),
              container,
            );

          final serialized = logger.records
              .map(
                (log) => <Object?>[
                  log.message,
                  log.additionalData,
                  log.exception,
                  log.error,
                  log.stackTrace,
                ].join('\n'),
              )
              .join('\n');

          expect(serialized, isNot(contains(secret)));
          expect(logger.byOperation('fail').single.stackTrace, isNotNull);
        });

        test('redaction failures fail closed without retaining diagnostics',
            () {
          const secret = 'FAIL_CLOSED_PAYLOAD_SECRET';
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(redactor: _ThrowingRedactor()),
          )
            ..didAddProvider(
              _counterProvider,
              const <String, Object?>{'tenantSecret': secret},
              container,
            )
            ..providerDidFail(
              _failingProvider,
              StateError('tenantSecret=$secret'),
              StackTrace.fromString('tenantSecret=$secret'),
              container,
            );

          final serialized = logger.records.join('\n');
          expect(serialized, isNot(contains(secret)));
          expect(serialized, isNot(contains('REDACTOR_FAILURE_SECRET')));
        });

        test('skips fail log when printFails disabled', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(printFails: false),
          ).providerDidFail(
            _failingProvider,
            StateError('boom'),
            StackTrace.current,
            container,
          );

          expect(logger.byOperation('fail'), isEmpty);
        });
      });

      group('non-dispatching type labels', () {
        test('observer paths never invoke caller runtimeType getters', () {
          final provider = _HostileRuntimeTypeProvider();
          final previousValue = _HostileRuntimeTypeValue();
          final newValue = _HostileRuntimeTypeValue();
          final error = _HostileRuntimeTypeValue();
          final stackTrace = _HostileStackTrace();
          final observer = ISpectRiverpodObserver(
            logger: logger,
            filters: const <Pattern>['never-match'],
            settings: const ISpectRiverpodSettings(
              captureMode: DiagnosticCaptureMode.strict,
            ),
          );

          expect(
            () {
              observer
                ..didAddProvider(provider, previousValue, container)
                ..didUpdateProvider(
                  provider,
                  previousValue,
                  newValue,
                  container,
                )
                ..didDisposeProvider(provider, container)
                ..providerDidFail(
                  provider,
                  error,
                  stackTrace,
                  container,
                );
            },
            returnsNormally,
          );

          expect(observer.settings.formatValue(newValue), same(newValue));
          expect(provider.runtimeTypeCalls, 0);
          for (final value in <_HostileRuntimeTypeValue>[
            previousValue,
            newValue,
            error,
          ]) {
            expect(value.runtimeTypeCalls, 0);
            expect(value.toStringCalls, 0);
          }
          expect(stackTrace.runtimeTypeCalls, 0);
          expect(stackTrace.toStringCalls, 0);

          final addMeta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(addMeta[RiverpodJsonKeys.providerName], 'Provider');
          expect(addMeta[RiverpodJsonKeys.providerType], 'Provider');
          expect(
            addMeta[RiverpodJsonKeys.value],
            JsonValueNormalizer.unprintableValue,
          );
        });
      });

      group('callback error isolation', () {
        test('observer continues when onProviderAdd callback throws', () {
          const secret = 'CALLBACK_SECRET';
          ISpectRiverpodObserver(
            logger: logger,
            onProviderAdd: (_, __, ___) =>
                throw StateError('tenantSecret=$secret'),
          ).didAddProvider(_counterProvider, 0, container);

          expect(logger.byOperation('add'), hasLength(1));
          expect(
            logger.records.any(
              (r) =>
                  r.message?.contains('onProviderAdd callback threw') ?? false,
            ),
            isTrue,
          );
          expect(logger.records.join('\n'), isNot(contains(secret)));
        });

        test('observer continues when onProviderUpdate callback throws', () {
          ISpectRiverpodObserver(
            logger: logger,
            onProviderUpdate: (_, __, ___, ____) =>
                throw StateError('callback crash'),
          ).didUpdateProvider(_counterProvider, 0, 1, container);

          expect(logger.byOperation('update'), hasLength(1));
        });

        test('observer continues when onProviderDispose callback throws', () {
          ISpectRiverpodObserver(
            logger: logger,
            onProviderDispose: (_, __) => throw StateError('callback crash'),
          ).didDisposeProvider(_counterProvider, container);

          expect(logger.byOperation('dispose'), hasLength(1));
        });

        test('observer continues when onProviderFail callback throws', () {
          ISpectRiverpodObserver(
            logger: logger,
            onProviderFail: (_, __, ___, ____) =>
                throw StateError('callback crash'),
          ).providerDidFail(
            _failingProvider,
            StateError('boom'),
            StackTrace.current,
            container,
          );

          expect(logger.byOperation('fail'), hasLength(1));
        });
      });

      group('provider name filtering', () {
        test('filters out provider matching regex pattern', () {
          ISpectRiverpodObserver(
            logger: logger,
            filters: [RegExp('counter')],
          ).didAddProvider(_counterProvider, 0, container);

          expect(logger.byOperation('add'), isEmpty);
        });

        test('does not filter out non-matching provider', () {
          ISpectRiverpodObserver(
            logger: logger,
            filters: [RegExp('something-else')],
          ).didAddProvider(_counterProvider, 0, container);

          expect(logger.byOperation('add'), hasLength(1));
        });

        test('filters by string pattern', () {
          ISpectRiverpodObserver(
            logger: logger,
            filters: ['counter'],
          ).didUpdateProvider(_counterProvider, 0, 1, container);

          expect(logger.byOperation('update'), isEmpty);
        });

        test('filterPredicate takes precedence', () {
          ISpectRiverpodObserver(
            logger: logger,
            filterPredicate: (candidate) =>
                candidate.toString().contains('counter'),
          ).didAddProvider(_counterProvider, 0, container);

          expect(logger.byOperation('add'), isEmpty);
        });

        test('providerFilter on settings suppresses matching providers', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              providerFilter: (provider) => provider.name != 'counter',
            ),
          ).didAddProvider(_counterProvider, 0, container);

          expect(logger.byOperation('add'), isEmpty);
        });
      });

      group('value rendering', () {
        test('default settings record full redacted values', () {
          ISpectRiverpodObserver(logger: logger)
              .didAddProvider(_counterProvider, 99, container);

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.value], 99);
        });

        test('compact preset keeps value capture disabled', () {
          expect(ISpectRiverpodSettings.compact.printValues, isFalse);
          expect(
            ISpectRiverpodSettings.compact.captureMode,
            DiagnosticCaptureMode.strict,
          );

          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings.compact,
          ).didAddProvider(_counterProvider, 99, container);

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta.containsKey(RiverpodJsonKeys.value), isFalse);
          expect(meta[RiverpodJsonKeys.valueType], 'int');
        });

        test('verbose preset includes raw add and update values', () {
          final observer = ISpectRiverpodObserver(
            logger: logger,
          )
            ..didAddProvider(_counterProvider, 99, container)
            ..didUpdateProvider(_counterProvider, 0, 1, container);

          final addMeta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(addMeta[RiverpodJsonKeys.value], 99);

          final meta = logger
              .byOperation('update')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.previousValue], 0);
          expect(meta[RiverpodJsonKeys.newValue], 1);

          expect(observer.settings.printValues, isTrue);
        });

        test('default update meta records full redacted values', () {
          ISpectRiverpodObserver(logger: logger)
              .didUpdateProvider(_counterProvider, 0, 1, container);

          final meta = logger
              .byOperation('update')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.previousValue], 0);
          expect(meta[RiverpodJsonKeys.newValue], 1);
          expect(meta[RiverpodJsonKeys.previousValueType], 'int');
          expect(meta[RiverpodJsonKeys.newValueType], 'int');
        });

        test('strict family argument rendering never invokes formatters', () {
          final argument = _HostileArgument();

          expect(
            () => ISpectRiverpodObserver(
              logger: logger,
              settings: const ISpectRiverpodSettings(
                captureMode: DiagnosticCaptureMode.strict,
              ),
            ).didAddProvider(
              _familyProvider(argument),
              1,
              container,
            ),
            returnsNormally,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            meta[RiverpodJsonKeys.argument],
            JsonValueNormalizer.unprintableValue,
          );
          expect(argument.runtimeTypeCalls, 0);
          expect(argument.toStringCalls, 0);
        });

        test('verbose redaction fails closed for hostile family arguments', () {
          final argument = _HostileArgument();

          expect(
            () => ISpectRiverpodObserver(
              logger: logger,
            ).didAddProvider(
              _familyProvider(argument),
              1,
              container,
            ),
            returnsNormally,
          );

          expect(
            logger.records.join('\n'),
            isNot(contains('HOSTILE_ARGUMENT')),
          );
        });

        test('verbose preset redacts sensitive family arguments', () {
          const argument = 'password=FAMILY_ARGUMENT_SECRET';
          ISpectRiverpodObserver(
            logger: logger,
          ).didAddProvider(
            _familyProvider(argument),
            1,
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final safeArgument = meta[RiverpodJsonKeys.argument].toString();
          expect(safeArgument, isNot(contains('FAMILY_ARGUMENT_SECRET')));
          expect(safeArgument, contains('[REDACTED]'));
        });

        test('raw family argument requires both verbose and redaction opt-out',
            () {
          const argument = 'password=FAMILY_ARGUMENT_SECRET';
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(
              enableRedaction: false,
            ),
          ).didAddProvider(
            _familyProvider(argument),
            1,
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.argument], argument);
        });

        test('verbose preset redacts structured values and family arguments',
            () {
          const secret = 'violet-riverpod-payload';
          const payload = <String, Object?>{
            'password': secret,
            'label': 'visible',
          };
          ISpectRiverpodObserver(
            logger: logger,
          ).didAddProvider(
            _familyProvider(payload),
            payload,
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[RiverpodJsonKeys.argument] as Map)['password'],
            '[REDACTED]',
          );
          expect(
            (meta[RiverpodJsonKeys.value] as Map)['password'],
            '[REDACTED]',
          );
          expect(logger.records.toString(), isNot(contains(secret)));
        });

        test('verbose captures and redacts typed payloads by default', () {
          const secret = 'TYPED_RIVERPOD_PASSWORD';
          final payload = _ReadablePayload(
            label: 'ready',
            password: secret,
          );

          ISpectRiverpodObserver(logger: logger).didAddProvider(
            _counterProvider,
            payload,
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.value], {
            'label': 'ready',
            'password': '[REDACTED]',
          });
          expect(payload.toJsonCalls, 1);
          expect(logger.records.toString(), isNot(contains(secret)));
        });

        test('strict mode snapshots custom payloads without executing them',
            () {
          final payload = _HostilePayload();
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(
              captureMode: DiagnosticCaptureMode.strict,
            ),
          ).didAddProvider(
            _familyProvider(payload),
            payload,
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            meta[RiverpodJsonKeys.argument],
            isA<String>(),
          );
          expect(
            meta[RiverpodJsonKeys.value],
            isA<String>(),
          );
          expect(payload.toJsonCalls, 0);
          expect(payload.toStringCalls, 0);
          expect(
            logger.records.toString(),
            isNot(contains('HOSTILE_PAYLOAD')),
          );
        });

        test('verbose custom redactor cannot restore raw value or argument',
            () {
          const secret = 'CUSTOM_RIVERPOD_REDACTOR_SECRET';

          for (final redactor in [
            _NullExportRedactor(),
            _ScalarExportRedactor(),
          ]) {
            logger.records.clear();
            ISpectRiverpodObserver(
              logger: logger,
              settings: ISpectRiverpodSettings(
                redactor: redactor,
              ),
            ).didAddProvider(
              _familyProvider(const {'tenantSecret': secret}),
              const {'tenantSecret': secret},
              container,
            );

            final record = logger.byOperation('add').single;
            expect(record.textMessage, isNot(contains(secret)));
            expect(record.additionalData.toString(), isNot(contains(secret)));
            expect(record.additionalData?[TraceKeys.meta], isEmpty);
          }
        });

        test('redaction opt-out preserves ordinary values and arguments', () {
          const payload = <String, Object?>{
            'password': 'violet-raw-riverpod-payload',
            'label': 'visible',
          };
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(
              enableRedaction: false,
            ),
          ).didAddProvider(
            _familyProvider(payload),
            payload,
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.argument], equals(payload));
          expect(meta[RiverpodJsonKeys.value], equals(payload));
        });
      });

      group('redaction', () {
        test('default settings activate redaction without a custom service',
            () {
          const settings = ISpectRiverpodSettings.verbose;
          final redacted = settings.redactAdditionalData(
            <String, dynamic>{'password': 'DEFAULT_REDACTION_SECRET'},
          );

          expect(settings.isRedactionActive, isTrue);
          expect(redacted?['password'], '[REDACTED]');
        });

        test('default settings use the globally configured service', () {
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<GLOBAL_RIVERPOD>',
            ),
          );

          final redacted = ISpectRiverpodSettings.verbose.redactAdditionalData(
            <String, dynamic>{'business_marker': 'riverpod-secret'},
          );

          expect(
            redacted?['business_marker'],
            contains('<GLOBAL_RIVERPOD>'),
          );
          expect(
            redacted?['business_marker'],
            isNot(contains('riverpod-secret')),
          );
        });

        test('default observer resolves global service for every event', () {
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<FIRST_RIVERPOD>',
            ),
          );
          final observer = ISpectRiverpodObserver(
            logger: logger,
          )..didAddProvider(
              _counterProvider,
              const <String, Object?>{'business_marker': 'first-secret'},
              container,
            );
          var meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[RiverpodJsonKeys.value] as Map)['business_marker'],
            contains('<FIRST_RIVERPOD>'),
          );

          logger.records.clear();
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<SECOND_RIVERPOD>',
            ),
          );
          observer.didAddProvider(
            _counterProvider,
            const <String, Object?>{'business_marker': 'second-secret'},
            container,
          );
          meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;

          expect(
            (meta[RiverpodJsonKeys.value] as Map)['business_marker'],
            contains('<SECOND_RIVERPOD>'),
          );
        });

        test('explicit observer redactor remains pinned', () {
          final observer = ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              redactor: RedactionService(
                sensitiveKeys: const {'business_marker'},
                placeholder: '<LOCAL_RIVERPOD>',
              ),
            ),
          );
          ISpectRedaction.configure(
            service: RedactionService(
              sensitiveKeys: const {'business_marker'},
              placeholder: '<GLOBAL_RIVERPOD>',
            ),
          );

          observer.didAddProvider(
            _counterProvider,
            const <String, Object?>{'business_marker': 'riverpod-secret'},
            container,
          );

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[RiverpodJsonKeys.value] as Map)['business_marker'],
            contains('<LOCAL_RIVERPOD>'),
          );
          expect(
            (meta[RiverpodJsonKeys.value] as Map)['business_marker'],
            isNot(contains('<GLOBAL_RIVERPOD>')),
          );
        });

        test('isRedactionActive reflects local and global gates', () {
          expect(
            ISpectRiverpodSettings.compact.isRedactionActive,
            isTrue,
          );
          expect(
            const ISpectRiverpodSettings(
              enableRedaction: false,
            ).isRedactionActive,
            isFalse,
          );

          ISpectRedaction.enabled = false;

          expect(
            ISpectRiverpodSettings.compact.isRedactionActive,
            isFalse,
          );
        });

        test('additionalData helper bounds active and opt-out strings', () {
          final payload = List<String>.filled(2 * 1024 * 1024, 'a').join();
          final redacted = ISpectRiverpodSettings.compact.redactAdditionalData(
            <String, dynamic>{
              'payload': payload,
              'prebounded':
                  'PARTIAL_RIVERPOD${LogExportOutput.truncatedMarker}',
            },
          );
          final unredacted = const ISpectRiverpodSettings(
            enableRedaction: false,
          ).redactAdditionalData(
            <String, dynamic>{'payload': payload},
          );

          expect(redacted?['payload'], LogExportOutput.truncatedMarker);
          expect(redacted?['prebounded'], LogExportOutput.truncatedMarker);
          expect(unredacted, isNotNull);
          expect(unredacted!['payload'], startsWith('a'));
          expect(
            unredacted['payload'],
            endsWith(LogExportOutput.truncatedMarker),
          );
          expect(
            LogExportOutput.utf8Length(jsonEncode(unredacted)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        });

        test('additionalData helper bounds custom redactor expansion', () {
          final result = ISpectRiverpodSettings(
            redactor: _ExpandingRedactor(),
          ).redactAdditionalData(
            <String, dynamic>{'label': 'visible'},
          );

          expect(result?['expansion'], LogExportOutput.truncatedMarker);
          expect(
            LogExportOutput.utf8Length(jsonEncode(result)),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('additionalData helper never formats hostile keys or values', () {
          final hostileValue = _HostilePayload();
          final valueResult =
              ISpectRiverpodSettings.compact.redactAdditionalData(
            <String, dynamic>{'payload': hostileValue},
          );
          final hostileKey = _HostilePayload();
          final hostileMap = <Object?, Object?>{
            hostileKey: 'visible',
          }.cast<String, dynamic>();
          final keyResult =
              ISpectRiverpodSettings.compact.redactAdditionalData(hostileMap);
          final redactorKey = _HostilePayload();
          final redactorValue = _HostilePayload();
          final redactorResult = ISpectRiverpodSettings(
            redactor: _HostileMapRedactor(redactorKey, redactorValue),
          ).redactAdditionalData(
            <String, dynamic>{'label': 'visible'},
          );

          expect(valueResult?['payload'], isA<String>());
          expect(hostileValue.toJsonCalls, 0);
          expect(hostileValue.toStringCalls, 0);
          expect(hostileKey.toJsonCalls, 0);
          expect(hostileKey.toStringCalls, 0);
          expect(redactorKey.toJsonCalls, 0);
          expect(redactorKey.toStringCalls, 0);
          expect(redactorValue.toJsonCalls, 0);
          expect(redactorValue.toStringCalls, 0);
          expect(
            LogExportOutput.utf8Length(jsonEncode(keyResult)),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
          expect(
            LogExportOutput.utf8Length(jsonEncode(redactorResult)),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('does not redact when enableRedaction is false', () {
          final redactor = RedactionService(
            sensitiveKeys: {RiverpodJsonKeys.providerName},
          );
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              enableRedaction: false,
              redactor: redactor,
            ),
          ).didAddProvider(_counterProvider, 0, container);

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.providerName], 'counter');
        });

        test('redacts sensitive meta fields when redactor provided', () {
          final redactor = RedactionService(
            sensitiveKeys: {RiverpodJsonKeys.providerName},
          );
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(redactor: redactor),
          ).didAddProvider(_counterProvider, 0, container);

          final meta = logger
              .byOperation('add')
              .single
              .additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(meta[RiverpodJsonKeys.providerName], isNot('counter'));
        });

        test('bounds multi-megabyte diagnostics before redaction and logging',
            () {
          final payload = List<String>.filled(2 * 1024 * 1024, 's').join();
          ISpectRiverpodObserver(
            logger: logger,
          ).didAddProvider(
            _counterProvider,
            <String, Object?>{
              'payload': payload,
              'prebounded':
                  'PARTIAL_RIVERPOD${LogExportOutput.truncatedMarker}',
            },
            container,
          );

          final record = logger.byOperation('add').single;
          final meta =
              record.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          expect(
            (meta[RiverpodJsonKeys.value] as Map)['payload'],
            LogExportOutput.truncatedMarker,
          );
          expect(
            (meta[RiverpodJsonKeys.value] as Map)['prebounded'],
            LogExportOutput.truncatedMarker,
          );
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
          expect(
            LogExportOutput.utf8Length(record.message ?? ''),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('bounds output from an expanding custom redactor', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              redactor: _ExpandingRedactor(),
            ),
          ).didAddProvider(
            _counterProvider,
            const {'label': 'visible'},
            container,
          );

          final record = logger.byOperation('add').single;
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
          expect(
            LogExportOutput.utf8Length(record.message ?? ''),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
        });

        test('bounds binary output when custom redaction retains bytes', () {
          final payload = Uint8List(2 * 1024 * 1024);
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              redactor: RedactionService(redactBinary: false),
            ),
          ).didAddProvider(
            _counterProvider,
            <String, Object?>{'payload': payload},
            container,
          );

          final record = logger.byOperation('add').single;
          final meta =
              record.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final bounded = (meta[RiverpodJsonKeys.value] as Map)['payload'];
          expect(bounded, '[binary ${2 * 1024 * 1024} bytes]');
          expect(bounded, isNot(same(payload)));
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        });

        test('redaction opt-out keeps a bounded raw string prefix', () {
          final payload = List<String>.filled(2 * 1024 * 1024, 'v').join();
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(
              enableRedaction: false,
            ),
          ).didAddProvider(
            _counterProvider,
            <String, Object?>{'payload': payload},
            container,
          );

          final record = logger.byOperation('add').single;
          final meta =
              record.additionalData?[TraceKeys.meta] as Map<String, dynamic>;
          final bounded =
              (meta[RiverpodJsonKeys.value] as Map)['payload'] as String;
          expect(bounded, startsWith('v'));
          expect(bounded, endsWith(LogExportOutput.truncatedMarker));
          expect(
            LogExportOutput.utf8Length(jsonEncode(record.additionalData)),
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        });
      });

      group('kISpectEnabled gate', () {
        test('emits nothing when ISpect is disabled at build time', () {
          ISpectRiverpodObserver.debugEnabledOverride = false;
          ISpectRiverpodObserver(logger: logger)
            ..didAddProvider(_counterProvider, 0, container)
            ..didUpdateProvider(_counterProvider, 0, 1, container)
            ..didDisposeProvider(_counterProvider, container)
            ..providerDidFail(
              _failingProvider,
              StateError('boom'),
              StackTrace.current,
              container,
            );

          expect(logger.records, isEmpty);
        });
      });

      group('console message redaction', () {
        const secret = 'sk-live-super-secret-value-1234567890';

        test('shows redacted value fields in the add message by default', () {
          ISpectRiverpodObserver(logger: logger).didAddProvider(
            _counterProvider,
            <String, dynamic>{'password': secret},
            container,
          );

          final message = logger.byOperation('add').single.message;
          expect(message, isNot(contains(secret)));
          expect(message, contains('password'));
          expect(message, contains('[REDACTED]'));
        });

        test('shows redacted values in the update message by default', () {
          ISpectRiverpodObserver(logger: logger).didUpdateProvider(
            _counterProvider,
            0,
            <String, dynamic>{'token': secret},
            container,
          );

          final message = logger.byOperation('update').single.message;
          expect(message, isNot(contains(secret)));
          expect(message, contains('token'));
          expect(message, contains('[REDACTED]'));
        });

        test('keeps the raw value in the console when redaction disabled', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: const ISpectRiverpodSettings(
              enableRedaction: false,
            ),
          ).didAddProvider(
            _counterProvider,
            <String, dynamic>{'password': secret},
            container,
          );

          final message = logger.byOperation('add').single.message;
          expect(message, contains(secret));
        });
      });

      group('disabled logger options', () {
        test('provider filter shutdown aborts later hooks and value traversal',
            () {
          final value = _IterableProbe();
          var observerFilterCalls = 0;
          var callbackCalls = 0;
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              providerFilter: (_) {
                logger.disable();
                return true;
              },
            ),
            filterPredicate: (_) {
              observerFilterCalls++;
              return false;
            },
            onProviderAdd: (_, __, ___) => callbackCalls++,
          ).didAddProvider(_counterProvider, value, container);

          expect(observerFilterCalls, 0);
          expect(callbackCalls, 0);
          expect(value.iteratorCalls, 0);
          expect(logger.byOperation('add'), isEmpty);
        });

        test('provider callback shutdown aborts value traversal', () {
          final value = _IterableProbe();
          ISpectRiverpodObserver(
            logger: logger,
            onProviderAdd: (_, __, ___) => logger.disable(),
          ).didAddProvider(_counterProvider, value, container);

          expect(value.iteratorCalls, 0);
          expect(logger.byOperation('add'), isEmpty);
        });

        test('update filter shutdown aborts callbacks and value traversal', () {
          final previousValue = _IterableProbe();
          final newValue = _IterableProbe();
          var callbackCalls = 0;
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings(
              updateFilter: (_, __, ___) {
                logger.disable();
                return true;
              },
            ),
            onProviderUpdate: (_, __, ___, ____) => callbackCalls++,
          ).didUpdateProvider(
            _counterProvider,
            previousValue,
            newValue,
            container,
          );

          expect(callbackCalls, 0);
          expect(previousValue.iteratorCalls, 0);
          expect(newValue.iteratorCalls, 0);
          expect(logger.byOperation('update'), isEmpty);
        });

        test('skip filters, callbacks, and caller-value inspection', () {
          final disabledLogger = ISpectLogger.testing(
            options: ISpectLoggerOptions(
              enabled: false,
              useConsoleLogs: false,
            ),
          );
          addTearDown(disabledLogger.dispose);
          var providerFilterCalls = 0;
          var updateFilterCalls = 0;
          var observerFilterCalls = 0;
          var callbackCalls = 0;
          final value = _HostileRuntimeTypeValue();
          final error = _HostileException(throws: true);
          final stackTrace = _HostileStackTrace();
          ISpectRiverpodObserver(
            logger: disabledLogger,
            settings: ISpectRiverpodSettings(
              providerFilter: (_) {
                providerFilterCalls++;
                return true;
              },
              updateFilter: (_, __, ___) {
                updateFilterCalls++;
                return true;
              },
            ),
            filterPredicate: (_) {
              observerFilterCalls++;
              return false;
            },
            onProviderAdd: (_, __, ___) => callbackCalls++,
            onProviderUpdate: (_, __, ___, ____) => callbackCalls++,
            onProviderDispose: (_, __) => callbackCalls++,
            onProviderFail: (_, __, ___, ____) => callbackCalls++,
          )
            ..didAddProvider(_counterProvider, value, container)
            ..didUpdateProvider(_counterProvider, value, value, container)
            ..didDisposeProvider(_counterProvider, container)
            ..providerDidFail(
              _failingProvider,
              error,
              stackTrace,
              container,
            );

          expect(providerFilterCalls, 0);
          expect(updateFilterCalls, 0);
          expect(observerFilterCalls, 0);
          expect(callbackCalls, 0);
          expect(value.runtimeTypeCalls, 0);
          expect(value.toStringCalls, 0);
          expect(error.toStringCalls, 0);
          expect(stackTrace.runtimeTypeCalls, 0);
          expect(stackTrace.toStringCalls, 0);
          expect(disabledLogger.history, isEmpty);
        });

        test('disposed logger skips filters and callbacks', () async {
          final disposedLogger = ISpectLogger.testing(
            options: ISpectLoggerOptions(useConsoleLogs: false),
          );
          await disposedLogger.dispose();
          var filterCalls = 0;
          var callbackCalls = 0;
          final value = _HostileRuntimeTypeValue();
          ISpectRiverpodObserver(
            logger: disposedLogger,
            filterPredicate: (_) {
              filterCalls++;
              return false;
            },
            onProviderAdd: (_, __, ___) => callbackCalls++,
          ).didAddProvider(_counterProvider, value, container);

          expect(filterCalls, 0);
          expect(callbackCalls, 0);
          expect(value.runtimeTypeCalls, 0);
          expect(value.toStringCalls, 0);
        });
      });

      group('enabled toggle', () {
        test('no logs when enabled is false', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings.silent,
          )
            ..didAddProvider(_counterProvider, 0, container)
            ..didUpdateProvider(_counterProvider, 0, 1, container)
            ..didDisposeProvider(_counterProvider, container)
            ..providerDidFail(
              _failingProvider,
              StateError('boom'),
              StackTrace.current,
              container,
            );

          expect(logger.records, isEmpty);
        });

        test('minimal preset hides updates but keeps add/dispose/fail', () {
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings.minimal,
          )
            ..didAddProvider(_counterProvider, 0, container)
            ..didUpdateProvider(_counterProvider, 0, 1, container)
            ..didDisposeProvider(_counterProvider, container);

          expect(logger.byOperation('add'), hasLength(1));
          expect(logger.byOperation('update'), isEmpty);
          expect(logger.byOperation('dispose'), hasLength(1));
        });

        test('copyWith preserves and replaces local resource limits', () {
          const original = ISpectRiverpodSettings(
            resourceLimits: DiagnosticResourceLimits.constrained,
          );

          expect(
            original.copyWith().resourceLimits,
            same(DiagnosticResourceLimits.constrained),
          );
          expect(
            original
                .copyWith(resourceLimits: DiagnosticResourceLimits.extended)
                .resourceLimits,
            same(DiagnosticResourceLimits.extended),
          );
        });

        test('observer rejects an invalid local resource policy', () {
          expect(
            () => ISpectRiverpodObserver(
              logger: logger,
              settings: const ISpectRiverpodSettings(
                resourceLimits: DiagnosticResourceLimits(
                  maxStateTraceBytes: 0,
                ),
              ),
            ),
            throwsArgumentError,
          );
        });
      });
    },
    skip: !kISpectEnabled,
  );
}
