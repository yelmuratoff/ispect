import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _HostileDateTime implements DateTime {
  int toStringCalls = 0;

  @override
  int get microsecondsSinceEpoch => throw StateError('must not escape');

  @override
  String toString() {
    toStringCalls++;
    return 'x' * (1024 * 1024);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _HostileJsonValue {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_JSON_FORMATTER');
  }
}

final class _HostileMessageValue {
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    throw StateError('HOSTILE_MESSAGE_RUNTIME_TYPE');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_MESSAGE_FORMATTER');
  }
}

final class _ReadableMessageValue {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    return 'readable diagnostic';
  }
}

final class _HostileExtensionLogGetters extends ISpectLogData {
  _HostileExtensionLogGetters({
    Object? exception,
    Error? error,
    StackTrace? stackTrace,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  }) : super(
          'trusted-extension-message',
          id: 'trusted-extension-id',
          time: DateTime.utc(2026, 7, 26),
          key: ISpectLogType.httpRequest.key,
          logLevel: LogLevel.error,
          exception: exception,
          error: error ?? StateError('trusted-error'),
          stackTrace: stackTrace ?? StackTrace.fromString('trusted-stack'),
          captureMode: captureMode,
          additionalData: const {
            'method': 'GET',
            'uri': 'https://example.com/safe',
            TraceKeys.success: false,
          },
        );

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError('FORGED_EXTENSION_GETTER_SECRET');
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
  AnsiPen? get pen => _forged();

  @override
  Map<String, dynamic>? get additionalData => _forged();

  @override
  Object? get exception => _forged();

  @override
  Error? get error => _forged();

  @override
  StackTrace? get stackTrace => _forged();

  @override
  String? get message => _forged();

  @override
  Object? get messageForSerialization => _forged();

  @override
  String get formattedTime => _forged();

  @override
  String? get lowerMessage => _forged();

  @override
  String get textMessage => _forged();

  @override
  String get header => _forged();

  @override
  String? get stackTraceText => _forged();

  @override
  String? get exceptionText => _forged();

  @override
  String? get errorText => _forged();

  @override
  String get messageText => _forged();

  @override
  bool get isError => _forged();

  @override
  int get hashCode => _forged();

  @override
  bool operator ==(Object other) => _forged();

  @override
  Type get runtimeType => _forged();

  String? get baseLowerMessage => super.lowerMessage;

  String get baseTextMessage => super.textMessage;

  String get baseHeader => super.header;

  String? get baseStackTraceText => super.stackTraceText;

  String? get baseExceptionText => super.exceptionText;

  String? get baseErrorText => super.errorText;

  String get baseMessageText => super.messageText;

  String get baseFormattedTime => super.formattedTime;

  bool get baseIsError => super.isError;

  int get baseHashCode => super.hashCode;

  String get baseToString => super.toString();

  bool baseEquals(Object other) => super == other;

  void notifyThroughBase(ISpectObserver observer) =>
      super.notifyObserver(observer);
}

final class _HostileRuntimeTypeError extends Error {
  final List<int> _runtimeTypeCalls = [0];

  int get runtimeTypeCalls => _runtimeTypeCalls.single;

  @override
  Type get runtimeType {
    _runtimeTypeCalls[0]++;
    throw StateError('FORGED_ERROR_RUNTIME_TYPE');
  }
}

final class _HostileDerivedError extends Error {
  final List<int> _calls = [0];

  int get calls => _calls.single;

  @override
  Type get runtimeType {
    _calls[0]++;
    throw StateError('FORGED_DERIVED_ERROR_RUNTIME_TYPE');
  }

  @override
  String toString() {
    _calls[0]++;
    throw StateError('FORGED_DERIVED_ERROR_FORMATTER');
  }
}

final class _HostileDerivedException implements Exception {
  final List<int> _calls = [0];

  int get calls => _calls.single;

  @override
  Type get runtimeType {
    _calls[0]++;
    throw StateError('FORGED_DERIVED_EXCEPTION_RUNTIME_TYPE');
  }

  @override
  String toString() {
    _calls[0]++;
    throw StateError('FORGED_DERIVED_EXCEPTION_FORMATTER');
  }
}

final class _HostileDerivedStackTrace implements StackTrace {
  final List<int> _calls = [0];

  int get calls => _calls.single;

  @override
  String toString() {
    _calls[0]++;
    throw StateError('FORGED_DERIVED_STACK_FORMATTER');
  }
}

final class _CountingObserver extends ISpectObserver {
  int errors = 0;
  int logs = 0;

  @override
  void onError(ISpectLogData data) => errors++;

  @override
  void onLog(ISpectLogData data) => logs++;
}

void main() {
  group('ISpectLogData Extensions', () {
    test('coerces message values to strings', () {
      final data = ISpectLogData(1234);
      expect(data.message, '1234');
    });

    test('captures readable unknown messages in balanced mode by default', () {
      final message = _ReadableMessageValue();

      final data = ISpectLogData(message);

      expect(data.message, 'readable diagnostic');
      expect(message.toStringCalls, 1);
    });

    test('strict mode captures unknown messages without invoking formatters',
        () {
      final hostile = _HostileMessageValue();

      final data = ISpectLogData(
        hostile,
        captureMode: DiagnosticCaptureMode.strict,
      );

      expect(data.message, JsonValueNormalizer.unprintableValue);
      expect(hostile.runtimeTypeCalls, 0);
      expect(hostile.toStringCalls, 0);
    });

    test('balanced mode retains exception messages and stack traces', () {
      final data = ISpectLogException(
        const FormatException('invalid response payload'),
        stackTrace: StackTrace.fromString('package:example/client.dart 42:7'),
      );

      expect(data.exceptionText, contains('invalid response payload'));
      expect(data.stackTraceText, contains('package:example/client.dart 42:7'));
    });

    test('captures a package-owned timestamp snapshot', () {
      final supplied = DateTime.utc(2026, 7, 26, 12, 30);
      final data = ISpectLogData('message', time: supplied);

      expect(data.time.microsecondsSinceEpoch, supplied.microsecondsSinceEpoch);
      expect(data.time.isUtc, isTrue);
      expect(identical(data.time, supplied), isFalse);
    });

    test('replaces a hostile timestamp without formatting it', () {
      final supplied = _HostileDateTime();
      final data = ISpectLogData('message', time: supplied);

      expect(identical(data.time, supplied), isFalse);
      expect(data.time.toIso8601String, returnsNormally);
      expect(supplied.toStringCalls, 0);
    });

    test('captures detached deeply immutable additional data', () {
      final nestedList = <Object?>['captured'];
      final nestedMap = <String, Object?>{'values': nestedList};
      final typedValues = Int16List.fromList([1, 2]);
      final bufferValues = Uint8List.fromList([3, 4]);
      final additionalData = <String, dynamic>{
        'nested': nestedMap,
        'typed': typedValues,
        'buffer': bufferValues.buffer,
      };

      final data = ISpectLogData(
        'message',
        additionalData: additionalData,
      );

      additionalData['late'] = true;
      nestedMap['late'] = true;
      nestedList[0] = 'changed';
      typedValues[0] = 9;
      bufferValues[0] = 9;

      final captured = data.additionalData!;
      final capturedNested = captured['nested']! as Map<String, Object?>;
      final capturedList = capturedNested['values']! as List<Object?>;
      final capturedTyped = captured['typed']! as Int16List;
      final capturedBuffer = captured['buffer']! as ByteBuffer;

      expect(captured, isNot(containsPair('late', true)));
      expect(capturedNested, isNot(containsPair('late', true)));
      expect(capturedList, ['captured']);
      expect(capturedTyped, [1, 2]);
      expect(capturedBuffer.asUint8List(), [3, 4]);
      expect(() => captured['late'] = true, throwsUnsupportedError);
      expect(() => capturedNested['late'] = true, throwsUnsupportedError);
      expect(() => capturedList[0] = 'changed', throwsUnsupportedError);
      expect(() => capturedTyped[0] = 9, throwsUnsupportedError);
      expect(
        () => capturedTyped.buffer.asInt16List()[0] = 9,
        throwsUnsupportedError,
      );
      expect(
        () => capturedBuffer.asUint8List()[0] = 9,
        throwsUnsupportedError,
      );
    });

    test('preserves typed list kinds in additional data snapshots', () {
      final data = ISpectLogData(
        'message',
        additionalData: {
          'int8': Int8List(0),
          'uint8': Uint8List(0),
          'uint8Clamped': Uint8ClampedList(0),
          'int16': Int16List(0),
          'uint16': Uint16List(0),
          'int32': Int32List(0),
          'uint32': Uint32List(0),
          'int64': Int64List(0),
          'uint64': Uint64List(0),
          'float32': Float32List(0),
          'float64': Float64List(0),
          'float32x4': Float32x4List(0),
          'int32x4': Int32x4List(0),
          'float64x2': Float64x2List(0),
          'byteData': ByteData(0),
        },
      );

      expect(data.additionalData!['int8'], isA<Int8List>());
      expect(data.additionalData!['uint8'], isA<Uint8List>());
      expect(data.additionalData!['uint8Clamped'], isA<Uint8ClampedList>());
      expect(data.additionalData!['int16'], isA<Int16List>());
      expect(data.additionalData!['uint16'], isA<Uint16List>());
      expect(data.additionalData!['int32'], isA<Int32List>());
      expect(data.additionalData!['uint32'], isA<Uint32List>());
      expect(data.additionalData!['int64'], isA<Int64List>());
      expect(data.additionalData!['uint64'], isA<Uint64List>());
      expect(data.additionalData!['float32'], isA<Float32List>());
      expect(data.additionalData!['float64'], isA<Float64List>());
      expect(data.additionalData!['float32x4'], isA<Float32x4List>());
      expect(data.additionalData!['int32x4'], isA<Int32x4List>());
      expect(data.additionalData!['float64x2'], isA<Float64x2List>());
      expect(data.additionalData!['byteData'], isA<ByteData>());
    });

    test('captures detached immutable binary message serialization', () {
      ISpectRedaction.enabled = false;
      addTearDown(() => ISpectRedaction.enabled = true);
      final original = Int8List.fromList([-1, 2, 3]);

      final data = ISpectLogData(original);

      original[0] = 9;
      final captured = data.messageForSerialization! as Int8List;
      expect(captured, [-1, 2, 3]);
      expect(identical(captured, original), isFalse);
      expect(() => captured[0] = 9, throwsUnsupportedError);
      expect(
        () => captured.buffer.asInt8List()[0] = 9,
        throwsUnsupportedError,
      );
    });

    test('copies byte buffer message serialization into read-only storage', () {
      ISpectRedaction.enabled = false;
      addTearDown(() => ISpectRedaction.enabled = true);
      final originalBytes = Uint8List.fromList([1, 2, 3]);

      final data = ISpectLogData(originalBytes.buffer);

      originalBytes[0] = 9;
      final captured = data.messageForSerialization! as ByteBuffer;
      expect(captured.asUint8List(), [1, 2, 3]);
      expect(identical(captured, originalBytes.buffer), isFalse);
      expect(
        () => captured.asUint8List()[0] = 9,
        throwsUnsupportedError,
      );
    });

    test('does not copy oversized typed-data message serialization', () {
      ISpectRedaction.enabled = false;
      addTearDown(() => ISpectRedaction.enabled = true);
      final original = Uint8List(
        LogExportOutput.maxPreparedValueBytes + 1,
      );

      final data = ISpectLogData(original);

      expect(
        data.messageForSerialization,
        binaryPlaceholder(original.lengthInBytes),
      );
    });

    test('does not copy oversized byte-buffer message serialization', () {
      ISpectRedaction.enabled = false;
      addTearDown(() => ISpectRedaction.enabled = true);
      final original = Uint8List(
        LogExportOutput.maxPreparedValueBytes + 1,
      ).buffer;

      final data = ISpectLogData(original);

      expect(
        data.messageForSerialization,
        binaryPlaceholder(original.lengthInBytes),
      );
    });

    test('fromJson bounds input without invoking hostile scalar formatters',
        () {
      final hostile = _HostileJsonValue();

      final data = ISpectLogDataJsonUtils.fromJson({
        'message': hostile,
        'time': DateTime.utc(2026, 7, 26).toIso8601String(),
        'exception': hostile,
        'additional-data': {
          'hostile': hostile,
          'oversized': 'x' * (4 * 1024 * 1024),
        },
      });

      expect(hostile.toStringCalls, 0);
      expect(data.message, isNot(contains('HOSTILE_JSON_FORMATTER')));
      expect(
        data.additionalData?['oversized'],
        LogExportOutput.truncatedMarker,
      );
      expect(
        data.additionalData.toString(),
        isNot(contains('HOSTILE_JSON_FORMATTER')),
      );
    });

    test('detects error logs via log type key', () {
      final data = ISpectLogData(
        'Database failure',
        key: ISpectLogType.dbError.key,
      );

      expect(data.isError, isTrue);
    });

    test('base-derived members never dispatch hostile subtype getters', () {
      final error = _HostileDerivedError();
      final exception = _HostileDerivedException();
      final stackTrace = _HostileDerivedStackTrace();
      final data = _HostileExtensionLogGetters(
        error: error,
        exception: exception,
        stackTrace: stackTrace,
        captureMode: DiagnosticCaptureMode.strict,
      );
      final equal = ISpectLogData(
        'other',
        id: 'trusted-extension-id',
      );
      final observer = _CountingObserver();

      expect(data.baseLowerMessage, 'trusted-extension-message');
      expect(data.baseTextMessage, contains('trusted-extension-message'));
      expect(data.baseHeader, contains('http-request'));
      expect(data.baseStackTraceText, isNotNull);
      expect(data.baseExceptionText, isNotNull);
      expect(data.baseErrorText, isNotNull);
      expect(data.baseMessageText, 'trusted-extension-message');
      expect(data.baseFormattedTime, isNotEmpty);
      expect(data.baseIsError, isTrue);
      expect(data.baseHashCode, 'trusted-extension-id'.hashCode);
      expect(data.baseToString, contains('trusted-extension-message'));
      expect(data.baseEquals(equal), isTrue);
      expect(equal == data, isTrue);
      data.notifyThroughBase(observer);
      expect(observer.errors, 1);
      expect(observer.logs, 0);
      expect(data.getterCalls, 0);
      expect(error.calls, 0);
      expect(exception.calls, 0);
      expect(stackTrace.calls, 0);
    });

    test('copy() creates exact duplicate preserving additionalData', () {
      final originalData = ISpectLogData(
        'Test message',
        logLevel: LogLevel.info,
        key: 'test-key',
        additionalData: const {
          'key1': 'value1',
          'key2': {'nested': 'value2'},
        },
      );

      final copiedData = originalData.copy();

      expect(copiedData.message, equals(originalData.message));
      expect(copiedData.logLevel, equals(originalData.logLevel));
      expect(copiedData.key, equals(originalData.key));
      expect(copiedData.additionalData, equals(originalData.additionalData));
      expect(copiedData.time, equals(originalData.time));
      expect(copiedData.exception, equals(originalData.exception));
      expect(copiedData.error, equals(originalData.error));
      expect(copiedData.stackTrace, equals(originalData.stackTrace));
      expect(copiedData.pen, equals(originalData.pen));
    });

    test('copy() preserves id so it stays equal to the original', () {
      final original = ISpectLogData('Test message', key: 'test-key');
      final copied = original.copy();

      expect(copied.id, equals(original.id));
      expect(copied, equals(original));
      expect(copied.hashCode, equals(original.hashCode));
    });

    test('copyWith(id:) mints a new identity', () {
      final original = ISpectLogData('Test message');
      final copied = original.copyWith(id: 'custom-id');

      expect(copied.id, equals('custom-id'));
      expect(copied, isNot(equals(original)));
    });

    test('copyWith() preserves additionalData when no parameters provided', () {
      final originalData = ISpectLogData(
        'Test message',
        additionalData: const {
          'key1': 'value1',
          'key2': {'nested': 'value2'},
        },
      );

      final copiedData = originalData.copyWith();

      expect(copiedData.additionalData, equals(originalData.additionalData));
    });

    test('copyWith() allows overriding additionalData', () {
      final originalData = ISpectLogData(
        'Test message',
        additionalData: const {'original': 'data'},
      );

      final newAdditionalData = {'new': 'data'};
      final copiedData = originalData.copyWith(
        additionalData: newAdditionalData,
      );

      expect(copiedData.additionalData, equals(newAdditionalData));
      expect(
        copiedData.additionalData,
        isNot(equals(originalData.additionalData)),
      );
    });

    test('copyWith() preserves additionalData when other fields are changed',
        () {
      final originalData = ISpectLogData(
        'Original message',
        key: 'original-key',
        additionalData: const {'important': 'metadata'},
      );

      final copiedData = originalData.copyWith(
        message: 'New message',
        key: 'new-key',
      );

      expect(copiedData.message, equals('New message'));
      expect(copiedData.key, equals('new-key'));
      expect(copiedData.additionalData, equals(originalData.additionalData));
    });

    test('public data extensions ignore hostile log getter overrides', () {
      final data = _HostileExtensionLogGetters();

      final copy = data.copy();
      final generated = data.generateText();
      final stack = data.stackTraceLogText;
      final http = data.httpLogText;
      final curl = data.curlCommand;

      expect(copy.id, 'trusted-extension-id');
      expect(copy.message, 'trusted-extension-message');
      expect(generated, contains('trusted-extension-message'));
      expect(stack, isNotNull);
      expect(http, contains('trusted-extension-message'));
      expect(data.isHttpLog, isTrue);
      expect(data.isRouteLog, isFalse);
      expect(curl, contains('https://example.com/safe'));
      expect(data.typeText, isNull);
      expect(data.getterCalls, 0);
    });

    test('typeText uses a non-executing core type label', () {
      final hostile = _HostileRuntimeTypeError();

      expect(ISpectLogError(hostile).typeText, 'Type: Error');
      expect(
        ISpectLogException(const FormatException('safe')).typeText,
        'Type: Exception',
      );
      expect(hostile.runtimeTypeCalls, 0);
    });

    test('curlCommand returns null for non-HTTP logs', () {
      final data = ISpectLogData('Test message');
      expect(data.curlCommand, isNull);
    });

    test('curlCommand returns null for malformed response request data', () {
      final data = ISpectLogData(
        'response',
        key: ISpectLogType.httpResponse.key,
        additionalData: const {'request-options': <Object?>[]},
      );

      expect(data.curlCommand, isNull);
    });

    test('curlCommand generates cURL for HTTP request logs', () {
      final data = ISpectLogData(
        'Test request',
        key: 'http-request',
        additionalData: const {
          'method': 'POST',
          'uri': 'https://example.com/api',
          'headers': {'Content-Type': 'application/json'},
          'data': '{"name": "value"}',
        },
      );

      final curl = data.curlCommand;
      expect(curl, isNotNull);
      expect(
        curl,
        contains("curl -X 'POST' --url 'https://example.com/api'"),
      );
      expect(curl, contains("-H 'Content-Type: application/json'"));
      expect(curl, contains("""--data-raw '{"name":"value"}'"""));
    });

    test('curlCommand generates cURL for HTTP response logs', () {
      final data = ISpectLogData(
        'Response received',
        key: 'http-response',
        additionalData: const {
          'request-options': {
            'method': 'POST',
            'uri': 'https://example.com/api',
            'headers': {'Content-Type': 'application/json'},
            'data': '{"name": "value"}',
          },
        },
      );

      final curl = data.curlCommand;
      expect(curl, isNotNull);
      expect(
        curl,
        contains("curl -X 'POST' --url 'https://example.com/api'"),
      );
      expect(curl, contains("-H 'Content-Type: application/json'"));
      expect(curl, contains("""--data-raw '{"name":"value"}'"""));
    });

    test('curlCommand generates cURL for HTTP error logs', () {
      final data = ISpectLogData(
        'Request failed',
        key: 'http-error',
        additionalData: const {
          'request-options': {
            'method': 'GET',
            'uri': 'https://example.com/fail',
            'headers': {'Authorization': 'Bearer token'},
          },
        },
      );

      final curl = data.curlCommand;
      expect(curl, contains("-H 'Authorization: Bearer [REDACTED]'"));
      expect(curl, isNot(contains('Bearer token')));
    });

    test('curlCommandWith requires an explicit opt-out for raw values', () {
      final data = ISpectLogData(
        'Request failed',
        key: 'http-error',
        additionalData: const {
          'request-options': {
            'method': 'GET',
            'uri': 'https://example.com/fail?token=url-secret',
            'headers': {'Authorization': 'Bearer header-secret'},
          },
        },
      );

      final curl = data.curlCommandWith(enableRedaction: false);

      expect(curl, contains('url-secret'));
      expect(curl, contains('header-secret'));
    });
  });
}
