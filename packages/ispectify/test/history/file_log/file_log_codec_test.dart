import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:test/test.dart';

final class _ThrowingPersistedValue {
  const _ThrowingPersistedValue();

  @override
  String toString() => throw StateError('must not escape');
}

final class _ThrowingPersistedKey {
  const _ThrowingPersistedKey();

  @override
  String toString() => throw StateError('must not escape');
}

final class _HostileToJsonValue {
  _HostileToJsonValue(this.payload);

  final String payload;
  int calls = 0;

  Object toJson() {
    calls++;
    return payload;
  }
}

final class _StringStackTrace implements StackTrace {
  int calls = 0;

  @override
  Type get runtimeType => StackTrace.fromString('').runtimeType;

  @override
  String toString() {
    calls++;
    return 'x' * (1024 * 1024);
  }
}

final class _HostileDateTime implements DateTime {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return 'x' * (1024 * 1024);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _HostileUri implements Uri {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return 'x' * (1024 * 1024);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _HostileFormatException implements FormatException {
  int messageCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('Exception runtimeType must not be invoked');
  }

  @override
  String get message {
    messageCalls++;
    return 'x' * (1024 * 1024);
  }

  @override
  String toString() {
    toStringCalls++;
    return 'x' * (1024 * 1024);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _HostileStateError implements StateError {
  int messageCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('Error runtimeType must not be invoked');
  }

  @override
  String get message {
    messageCalls++;
    return 'x' * (1024 * 1024);
  }

  @override
  String toString() {
    toStringCalls++;
    return 'x' * (1024 * 1024);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _InspectingRedactor extends RedactionService {
  int calls = 0;
  bool sawOversizedValue = false;

  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    calls++;
    if (data is Map<Object?, Object?>) {
      final message = data['message'];
      final additionalData = data['additional-data'];
      sawOversizedValue = sawOversizedValue ||
          message is String && message.length > 4096 ||
          additionalData is Map<Object?, Object?> &&
              additionalData['payload'] is String &&
              (additionalData['payload']! as String).length > 4096;
    }
    return super.redactEnvelopeForExport(
      data,
      rootValueKeys: rootValueKeys,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
  }
}

final class _ReturningEnvelopeRedactor extends RedactionService {
  _ReturningEnvelopeRedactor(this.output);

  final Object? output;

  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      output;
}

final class _HostileRedactorOutput {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    return 'CUSTOM-REDACTOR-SECRET';
  }

  @override
  String toString() {
    toStringCalls++;
    return 'CUSTOM-REDACTOR-SECRET';
  }
}

final class _HostilePersistedLogGetters extends ISpectLogData {
  _HostilePersistedLogGetters({
    Object? message = 'trusted-base-message',
    String id = 'trusted-base-id',
  }) : super(
          message,
          id: id,
          time: DateTime.utc(2025),
          key: 'trusted-base-key',
          logLevel: LogLevel.info,
          additionalData: const {
            TraceKeys.transactionId: 'trusted-transaction',
          },
        );

  static const forgedMarker = 'FORGED_FILE_GETTER_SECRET';

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError(forgedMarker);
  }

  @override
  String get id => _forged();

  @override
  DateTime get time => _forged();

  @override
  String? get key => _forged();

  @override
  LogLevel? get logLevel => _forged();

  @override
  Map<String, dynamic>? get additionalData => _forged();

  @override
  Object? get exception => _forged();

  @override
  Error? get error => _forged();

  @override
  StackTrace? get stackTrace => _forged();

  @override
  Object? get messageForSerialization => _forged();
}

void main() {
  tearDown(ISpectRedaction.reset);

  test('redacts before encoding and adds the non-user session ID', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final log = ISpectLogData(
      'request',
      id: 'A',
      additionalData: const {
        'authorization': 'Bearer persistence-secret',
        '_render-hints': {'expanded': true},
      },
    );

    final encoded = codec.encode(
      log,
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final text = utf8.decode(encoded.bytes);

    expect(text, isNot(contains('persistence-secret')));
    expect(text, isNot(contains('_render-hints')));
    expect(text, contains('SESSION'));
    expect(text.endsWith('\n'), isTrue);
  });

  test('uses the configured global service when no override is supplied', () {
    ISpectRedaction.configure(
      service: RedactionService(
        sensitiveKeys: const {'business_marker'},
        placeholder: '<GLOBAL_POLICY>',
      ),
    );
    final codec = FileLogCodec();

    final encoded = codec.encode(
      ISpectLogData(
        'request',
        additionalData: const {'business_marker': 'history-secret'},
      ),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final text = utf8.decode(encoded.bytes);

    expect(text, isNot(contains('history-secret')));
    expect(text, contains('<GLOBAL_POLICY>'));
  });

  test('encoding ignores hostile log getter overrides', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final fullLog = _HostilePersistedLogGetters();
    final minimizedLog = _HostilePersistedLogGetters(
      message: 'm' * 10000,
      id: 'trusted-minimized-id',
    );

    final full = codec.encode(
      fullLog,
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final minimized = codec.encode(
      minimizedLog,
      sessionId: 'SESSION',
      maxBytes: 1024,
    );
    final fullJson =
        jsonDecode(utf8.decode(full.bytes)) as Map<String, dynamic>;
    final minimizedJson =
        jsonDecode(utf8.decode(minimized.bytes)) as Map<String, dynamic>;

    expect(full.id, 'trusted-base-id');
    expect(fullJson['id'], 'trusted-base-id');
    expect(fullJson['message'], 'trusted-base-message');
    expect(minimized.id, 'trusted-minimized-id');
    expect(minimized.truncated, isTrue);
    expect(minimizedJson['id'], 'trusted-minimized-id');
    expect(
      utf8.decode(minimized.bytes),
      isNot(contains(_HostilePersistedLogGetters.forgedMarker)),
    );
    expect(fullLog.getterCalls, 0);
    expect(minimizedLog.getterCalls, 0);
  });

  test('only restores the trusted envelope session ID', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'request',
        additionalData: const {
          'nested': {
            TraceKeys.sessionId: 'NESTED_SESSION_SECRET',
          },
        },
      ),
      sessionId: 'TRUSTED_SESSION',
      maxBytes: 4096,
    );
    final decoded =
        jsonDecode(utf8.decode(encoded.bytes)) as Map<String, dynamic>;
    final additional = decoded['additional-data'] as Map<String, dynamic>;
    final nested = additional['nested'] as Map<String, dynamic>;

    expect(additional[TraceKeys.sessionId], 'TRUSTED_SESSION');
    expect(nested[TraceKeys.sessionId], defaultPlaceholder);
    expect(
      utf8.decode(encoded.bytes),
      isNot(contains('NESTED_SESSION_SECRET')),
    );
  });

  test('redacts secrets embedded in messages before persistence', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final log = ISpectLogData(
      'failed https://alice:password@example.test/users?token=PERSISTENCE_SECRET&api_key=PATTERN_SECRET',
      id: 'A',
    );

    final encoded = codec.encode(
      log,
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final text = utf8.decode(encoded.bytes);

    expect(text, isNot(contains('password')));
    expect(text, isNot(contains('PERSISTENCE_SECRET')));
    expect(text, isNot(contains('PATTERN_SECRET')));
    expect(text, contains('[REDACTED]'));
  });

  test('global redaction opt-out deliberately preserves raw values', () {
    ISpectRedaction.enabled = false;
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'request',
        id: 'A',
        additionalData: {
          'authorization': 'explicit-raw-value',
          'int8': Int8List.fromList([-1, 2, 3]),
          'uint16': Uint16List.fromList([256, 512]),
        },
      ),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );

    final text = utf8.decode(encoded.bytes);
    final record = jsonDecode(text) as Map<String, dynamic>;
    final additional = record['additional-data'] as Map<String, dynamic>;

    expect(text, contains('explicit-raw-value'));
    expect(additional['int8'], [-1, 2, 3]);
    expect(additional['uint16'], [256, 512]);
    expect(text, isNot(contains('[binary')));
  });

  test('converts interface-typed nested values to a fail-closed marker', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final instant = DateTime.utc(2026, 7, 10);

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        id: 'A',
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {
          'nested': [
            {'instant': instant},
          ],
        },
      ),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final decoded =
        jsonDecode(utf8.decode(encoded.bytes)) as Map<String, dynamic>;
    final additional = decoded['additional-data'] as Map<String, dynamic>;
    final nested = additional['nested'] as List<dynamic>;

    expect(nested, [
      {'instant': JsonValueNormalizer.unprintableValue},
    ]);
  });

  test('never invokes hostile DateTime or Uri formatting', () {
    final instant = _HostileDateTime();
    final uri = _HostileUri();
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {
          'instant': instant,
          'uri': uri,
        },
      ),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final decoded =
        jsonDecode(utf8.decode(encoded.bytes)) as Map<String, dynamic>;
    final additional = decoded['additional-data'] as Map<String, dynamic>;

    expect(instant.calls, 0);
    expect(uri.calls, 0);
    expect(additional['instant'], JsonValueNormalizer.unprintableValue);
    expect(additional['uri'], JsonValueNormalizer.unprintableValue);
  });

  test('persists cycles and throwing diagnostics through the safe boundary',
      () {
    final cyclic = <Object?, Object?>{};
    cyclic['self'] = cyclic;
    cyclic[const _ThrowingPersistedKey()] = 'secret-behind-unknown-key';
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        id: 'A',
        additionalData: {
          'cyclic': cyclic,
          'throwing': const _ThrowingPersistedValue(),
        },
      ),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final text = utf8.decode(encoded.bytes);

    expect(text, contains(JsonValueNormalizer.circularReference));
    expect(text, contains(JsonValueNormalizer.unprintableValue));
    expect(text, isNot(contains('secret-behind-unknown-key')));
    expect(() => jsonDecode(text), returnsNormally);
  });

  test('minimizes a record that exceeds one segment', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        id: 'A',
        additionalData: {'values': List<int>.filled(10000, 1)},
      ),
      sessionId: 'SESSION',
      maxBytes: 512,
    );

    expect(encoded.bytes.length, lessThanOrEqualTo(512));
    expect(encoded.truncated, isTrue);
    expect(utf8.decode(encoded.bytes), contains('payload-truncated'));
  });

  test('pre-bounds hostile large fields before the redaction pass', () {
    final redactor = _InspectingRedactor();
    final codec = FileLogCodec(redactor: redactor);
    final oversized = 'x' * (256 * 1024);

    final encoded = codec.encode(
      ISpectLogData(
        oversized,
        id: 'A',
        additionalData: {'payload': oversized},
      ),
      sessionId: 'SESSION',
      maxBytes: 512,
    );

    expect(encoded.truncated, isTrue);
    expect(encoded.bytes.length, lessThanOrEqualTo(512));
    expect(redactor.calls, 1);
    expect(redactor.sawOversizedValue, isFalse);
    expect(utf8.decode(encoded.bytes), contains('payload-truncated'));
  });

  test('never invokes hostile values returned by a custom redactor', () {
    final hostile = _HostileRedactorOutput();
    final codec = FileLogCodec(
      redactor: _ReturningEnvelopeRedactor(hostile),
    );

    final encoded = codec.encode(
      ISpectLogData('message', id: 'A'),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final text = utf8.decode(encoded.bytes);

    expect(hostile.toJsonCalls, 0);
    expect(hostile.toStringCalls, 0);
    expect(text, isNot(contains('CUSTOM-REDACTOR-SECRET')));
    expect(text, contains('payload-truncated'));
    expect(() => jsonDecode(text), returnsNormally);
  });

  test('bounds oversized envelopes returned by a custom redactor', () {
    final codec = FileLogCodec(
      redactor: _ReturningEnvelopeRedactor(
        <String, Object?>{
          'id': 'A',
          'time': DateTime(2026).toIso8601String(),
          'message': 'x' * (4 * 1024 * 1024),
          'additional-data': const <String, Object?>{},
          'schema-version': 1,
        },
      ),
    );

    final encoded = codec.encode(
      ISpectLogData('message', id: 'A'),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );
    final text = utf8.decode(encoded.bytes);

    expect(encoded.bytes.length, lessThanOrEqualTo(4096));
    expect(encoded.truncated, isTrue);
    expect(text, contains(LogExportOutput.truncatedMarker));
    expect(() => jsonDecode(text), returnsNormally);
  });

  test('rejects a minimized envelope that cannot fit', () {
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.encode(
        ISpectLogData('message', id: 'A'),
        sessionId: 'SESSION',
        maxBytes: 1,
      ),
      throwsA(isA<FileLogLimitException>()),
    );
  });

  test('round trips one JSONL record with its original ID and session', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final source = ISpectLogData('message', id: 'A', key: 'test_key_1');
    final encoded = codec.encode(source, sessionId: 'S', maxBytes: 4096);

    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());

    expect(decoded.id, 'A');
    expect(decoded.key, 'test_key_1');
    expect(decoded.additionalData?[TraceKeys.sessionId], 'S');
  });

  test('persists bounded diagnostic messages and stack traces by default', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        exception: const FormatException('ordinary exception'),
        error: StateError('ordinary error'),
        stackTrace: StackTrace.fromString('ordinary stack frame'),
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );

    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());

    expect(decoded.exception.toString(), contains('ordinary exception'));
    expect(decoded.error.toString(), contains('ordinary error'));
    expect(decoded.stackTrace.toString(), contains('ordinary stack frame'));
  });

  test('does not invoke implementable exception and error fields', () {
    final exception = _HostileFormatException();
    final error = _HostileStateError();
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        exception: exception,
        error: error,
        captureMode: DiagnosticCaptureMode.strict,
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );

    expect(exception.messageCalls, 0);
    expect(exception.runtimeTypeCalls, 0);
    expect(exception.toStringCalls, 0);
    expect(error.messageCalls, 0);
    expect(error.runtimeTypeCalls, 0);
    expect(error.toStringCalls, 0);
    expect(
      () => codec.decodeLine(utf8.decode(encoded.bytes).trim()),
      returnsNormally,
    );
  });

  test('does not invoke a StackTrace that spoofs the SDK implementation', () {
    final stackTrace = _StringStackTrace();
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        stackTrace: stackTrace,
        captureMode: DiagnosticCaptureMode.strict,
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );

    expect(stackTrace.calls, 0);
    expect(
      () => codec.decodeLine(utf8.decode(encoded.bytes).trim()),
      returnsNormally,
    );
  });

  test('decodeLine preserves a map within the prepared-value budget', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final groups = <Object?>[
      for (var group = 0; group < 6; group++)
        <String, Object?>{
          for (var entry = 0; entry < 900; entry++)
            'entry-$entry': 'value-$group-$entry',
        },
    ];

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        id: 'A',
        additionalData: {'groups': groups},
      ),
      sessionId: 'S',
      maxBytes: 1024 * 1024,
    );
    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());
    final decodedGroups = decoded.additionalData!['groups']! as List<dynamic>;

    expect(encoded.truncated, isFalse);
    expect(decodedGroups.whereType<Map<String, dynamic>>(), hasLength(6));
    expect(encoded.bytes.length, lessThanOrEqualTo(1024 * 1024));
  });

  test('preserves the trusted session at the nested collection boundary', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        id: 'A',
        additionalData: <String, Object?>{
          for (var index = 0; index < 1000; index++) 'field-$index': index,
        },
      ),
      sessionId: 'TRUSTED',
      maxBytes: 1024 * 1024,
    );

    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());

    expect(decoded.additionalData!.length, lessThanOrEqualTo(1000));
    expect(decoded.additionalData?[TraceKeys.sessionId], 'TRUSTED');
  });

  test('bounds oversized nested maps and lists within the decoder limit', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        additionalData: {
          'map': <String, Object?>{
            for (var index = 0; index < 1001; index++) 'field-$index': index,
          },
          'list': List<int>.generate(1001, (index) => index),
        },
      ),
      sessionId: 'S',
      maxBytes: 1024 * 1024,
    );

    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());
    final map = decoded.additionalData!['map']! as Map<String, dynamic>;
    final list = decoded.additionalData!['list']! as List<dynamic>;

    expect(map.length, lessThanOrEqualTo(1000));
    expect(list.length, lessThanOrEqualTo(1000));
  });

  test('persistence honors a custom collection budget', () {
    final limits = DiagnosticResourceLimits.balanced.copyWith(
      maxCollectionItems: 4,
    );
    final codec = FileLogCodec(
      redactor: RedactionService(),
      resourceLimits: limits,
    );
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        additionalData: {
          'nested': {
            for (var index = 0; index < 10; index++) 'field-$index': index,
          },
        },
      ),
      sessionId: 'S',
      maxBytes: limits.maxLogRecordBytes,
    );

    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());
    final nested = decoded.additionalData!['nested']! as Map<String, dynamic>;

    expect(nested.length, lessThanOrEqualTo(limits.maxCollectionItems));
    expect(
      nested[JsonValueNormalizer.traversalMarkerKey],
      JsonValueNormalizer.maxCollectionItemsReached,
    );
  });

  test('never invokes hostile toJson while preparing a persisted record', () {
    final hostile = _HostileToJsonValue('x' * (1024 * 1024));
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {'hostile': hostile},
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );
    final record =
        jsonDecode(utf8.decode(encoded.bytes)) as Map<String, dynamic>;
    final additional = record['additional-data'] as Map<String, dynamic>;

    expect(hostile.calls, 0);
    expect(
      additional['hostile'],
      JsonValueNormalizer.unprintableValue,
    );
    expect(utf8.decode(encoded.bytes), isNot(contains(hostile.payload)));
  });

  test('preflight charges repeated aliases each time they are serialized', () {
    final redactor = _InspectingRedactor();
    final codec = FileLogCodec(redactor: redactor);
    final shared = <String, Object?>{'payload': 'x' * 1024};

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        additionalData: {
          'aliases': List<Object?>.filled(1000, shared),
        },
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );

    expect(encoded.truncated, isTrue);
    expect(encoded.bytes.length, lessThanOrEqualTo(4096));
    expect(redactor.calls, 1);
  });

  test('minimized trace metadata never invokes hostile conversion', () {
    final transaction = _HostileToJsonValue('x' * (1024 * 1024));
    final correlation = _HostileToJsonValue('y' * (1024 * 1024));
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'z' * (256 * 1024),
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {
          TraceKeys.transactionId: transaction,
          TraceKeys.correlationId: correlation,
        },
      ),
      sessionId: 'S',
      maxBytes: 512,
    );

    expect(encoded.truncated, isTrue);
    expect(transaction.calls, 0);
    expect(correlation.calls, 0);
    expect(
      () => codec.decodeLine(utf8.decode(encoded.bytes).trim()),
      returnsNormally,
    );
  });

  test('round trips a deep map after exhausting map-heavy siblings', () {
    Object? branch = <String, Object?>{
      'values': List<int>.filled(1000, 1),
    };
    for (var depth = 0; depth < 60; depth++) {
      branch = <String, Object?>{
        'next': branch,
        'values': List<int>.filled(200, depth),
      };
    }
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData('message', additionalData: {'deep': branch}),
      sessionId: 'S',
      maxBytes: 1024 * 1024,
    );

    expect(
      () => codec.decodeLine(utf8.decode(encoded.bytes).trim()),
      returnsNormally,
    );
  });

  test('round trips inputs at and beyond the 64-container boundary', () {
    final codec = FileLogCodec(redactor: RedactionService());

    Object? atBoundary = 'leaf';
    for (var depth = 0; depth < 62; depth++) {
      atBoundary = <String, Object?>{'next': atBoundary};
    }
    Object? beyondBoundary = 'leaf';
    for (var depth = 0; depth < 63; depth++) {
      beyondBoundary = <String, Object?>{'next': beyondBoundary};
    }

    for (final branch in [atBoundary, beyondBoundary]) {
      final encoded = codec.encode(
        ISpectLogData('message', additionalData: {'branch': branch}),
        sessionId: 'S',
        maxBytes: 1024 * 1024,
      );
      expect(
        () => codec.decodeLine(utf8.decode(encoded.bytes).trim()),
        returnsNormally,
      );
    }
  });

  test('redacts typed binary before writing a JSONL record', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        additionalData: {
          'payload': Uint8List.fromList(List<int>.filled(64, 122)),
        },
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );
    final record =
        jsonDecode(utf8.decode(encoded.bytes).trim()) as Map<String, dynamic>;
    final additional = record['additional-data'] as Map<String, dynamic>;
    final payload = additional['payload'] as List<dynamic>;

    expect(payload, utf8.encode('[binary 64 bytes]'));
    expect(payload, isNot(contains(122)));
  });

  test('redacts non-Uint8 typed binary before writing a JSONL record', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        additionalData: {
          'int8': Int8List.fromList(List<int>.filled(64, 77)),
          'uint16': Uint16List.fromList(List<int>.filled(32, 60000)),
          'byteData': ByteData.view(
            Uint8List.fromList(List<int>.filled(64, 211)).buffer,
          ),
          'buffer': Uint8List.fromList(List<int>.filled(64, 244)).buffer,
        },
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );
    final record =
        jsonDecode(utf8.decode(encoded.bytes).trim()) as Map<String, dynamic>;
    final additional = record['additional-data'] as Map<String, dynamic>;

    for (final key in const ['int8', 'uint16', 'byteData', 'buffer']) {
      final payload = additional[key] as List<dynamic>;
      expect(payload, utf8.encode('[binary 64 bytes]'));
    }
    expect(additional['int8'], isNot(contains(77)));
    expect(additional['uint16'], isNot(contains(60000)));
    expect(additional['byteData'], isNot(contains(211)));
    expect(additional['buffer'], isNot(contains(244)));
  });

  test('persists large typed binary as a compact bounded placeholder', () {
    const byteLength = 4 * 1024 * 1024;
    final bytes = Uint8List(byteLength)..fillRange(0, byteLength, 233);
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'message',
        additionalData: {'payload': bytes.buffer},
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );
    final record =
        jsonDecode(utf8.decode(encoded.bytes).trim()) as Map<String, dynamic>;
    final additional = record['additional-data'] as Map<String, dynamic>;

    expect(encoded.bytes.length, lessThan(4096));
    expect(additional['payload'], '[binary $byteLength bytes]');
    expect(utf8.decode(encoded.bytes), isNot(contains('233,233,233')));
  });

  test('scrubs prose secrets and absolute paths before persistence', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final encoded = codec.encode(
      ISpectLogData(
        'failed password=FILE_SECRET '
        'at file:///Users/alice/project/auth.dart:12:3',
      ),
      sessionId: 'S',
      maxBytes: 4096,
    );
    final output = utf8.decode(encoded.bytes);

    expect(output, isNot(contains('FILE_SECRET')));
    expect(output, isNot(contains('/Users/alice')));
    expect(output, contains(defaultPlaceholder));
  });

  test('decodes a valid legacy array', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final input = jsonEncode([
      ISpectLogData('first', id: 'A').toJson(),
      ISpectLogData('second', id: 'B').toJson(),
    ]);

    expect(codec.decodeLegacyArray(input).map((log) => log.id), ['A', 'B']);
  });

  test('reports the invalid legacy entry index', () {
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLegacyArray(
        jsonEncode([
          ISpectLogData('valid', id: 'A').toJson(),
          'invalid',
        ]),
      ),
      throwsA(
        isA<FileLogFormatException>().having(
          (error) => error.operation,
          'operation',
          'decodeLegacyArray[1]',
        ),
      ),
    );
  });

  test('rejects malformed JSONL with a typed format error', () {
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLine('{malformed'),
      throwsA(isA<FileLogFormatException>()),
    );
  });

  test('does not retain malformed JSONL source in the reported cause', () {
    const marker = 'MALFORMED_JSONL_INPUT_MARKER';
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLine('{"message":"$marker"'),
      throwsA(
        isA<FileLogFormatException>()
            .having(
              (error) => error.cause,
              'cause',
              isA<FormatException>().having(
                (error) => error.source,
                'source',
                isNull,
              ),
            )
            .having(
              (error) => '${error.cause}',
              'cause text',
              isNot(contains(marker)),
            ),
      ),
    );
  });

  test('does not retain malformed legacy JSON source in the reported cause',
      () {
    const marker = 'MALFORMED_LEGACY_INPUT_MARKER';
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLegacyArray('[{"message":"$marker"}'),
      throwsA(
        isA<FileLogFormatException>()
            .having(
              (error) => error.cause,
              'cause',
              isA<FormatException>().having(
                (error) => error.source,
                'source',
                isNull,
              ),
            )
            .having(
              (error) => '${error.cause}',
              'cause text',
              isNot(contains(marker)),
            ),
      ),
    );
  });

  test('does not retain hostile decoded fields in record-conversion failures',
      () {
    const marker = 'HOSTILE_DECODED_FIELD_MARKER';
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLine(jsonEncode({'untrusted-field': marker})),
      throwsA(
        isA<FileLogFormatException>()
            .having(
              (error) => (error.cause as FormatException?)?.source,
              'cause source',
              isNull,
            )
            .having(
              (error) => '${error.cause}',
              'cause text',
              isNot(contains(marker)),
            ),
      ),
    );
  });

  test('rejects JSONL character and encoded-byte overflow as typed limits', () {
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLine(
        '{"message":"${'a' * 64}"}',
        maxCharacters: 32,
        maxEncodedBytes: 256,
      ),
      throwsA(isA<FileLogLimitException>()),
    );
    expect(
      () => codec.decodeLine(
        '{"message":"${'€' * 24}"}',
        maxCharacters: 128,
        maxEncodedBytes: 32,
      ),
      throwsA(isA<FileLogLimitException>()),
    );
  });

  test('rejects deep, high-node, and wide legacy JSON as typed limits', () {
    final codec = FileLogCodec(redactor: RedactionService());

    expect(
      () => codec.decodeLegacyArray(
        '[[[[0]]]]',
        maxDepth: 3,
        maxNodes: 100,
        maxCollectionItems: 100,
      ),
      throwsA(isA<FileLogLimitException>()),
    );
    expect(
      () => codec.decodeLegacyArray(
        '[${List<String>.filled(12, '0').join(',')}]',
        maxDepth: 3,
        maxNodes: 5,
        maxCollectionItems: 100,
      ),
      throwsA(isA<FileLogLimitException>()),
    );
    expect(
      () => codec.decodeLegacyArray(
        '[${List<String>.filled(6, '0').join(',')}]',
        maxDepth: 3,
        maxNodes: 100,
        maxCollectionItems: 5,
      ),
      throwsA(isA<FileLogLimitException>()),
    );
  });
}
