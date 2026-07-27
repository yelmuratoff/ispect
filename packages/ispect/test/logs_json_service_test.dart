// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';

String _hostileServiceExportValue() =>
    ''.padRight(LogExportOutput.maxRecordBytes * 2, 'x');

final class _HostileServiceDateTime implements DateTime {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('DateTime member must not be invoked during export');
  }
}

final class _HostileServiceUri implements Uri {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Uri member must not be invoked during export');
  }
}

final class _HostileServiceException implements FormatException {
  int calls = 0;

  @override
  String get message {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Exception member must not be invoked during export');
  }
}

final class _HostileServiceError implements StateError {
  int calls = 0;

  @override
  String get message {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Error member must not be invoked during export');
  }
}

final class _HostileServiceStackTrace implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('StackTrace member must not be invoked during export');
  }
}

final class _HostileServiceJsonValue {
  int calls = 0;

  Object toJson() {
    calls++;
    return _hostileServiceExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileServiceExportValue();
  }
}

final class _HostileServiceLogGetters extends ISpectLogData {
  _HostileServiceLogGetters()
      : super(
          'trusted message',
          id: 'trusted-id',
          time: DateTime.utc(2025),
        );

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError('export must not invoke hostile log getters');
  }

  @override
  DateTime get time => _forged();
}

void main() {
  tearDown(ISpectRedaction.reset);

  group('LogsJsonService Tests', () {
    late LogsJsonService service;
    late List<ISpectLogData> sampleLogs;

    setUp(() {
      service = const LogsJsonService();
      ISpect.initialize(ISpectLogger());
      sampleLogs = [
        ISpectLogData(
          'Test log message 1',
          time: DateTime(2025, 1, 1, 12),
          logLevel: LogLevel.info,
          key: 'test_key_1',
          additionalData: const {'testData': 'value1'},
        ),
        ISpectLogData(
          'Test log message 2',
          time: DateTime(2025, 1, 1, 12, 1),
          logLevel: LogLevel.error,
          key: 'test_key_2',
          exception: Exception('Test exception'),
          additionalData: const {'errorCode': 500},
        ),
        ISpectLogData(
          'Test log message 3',
          time: DateTime(2025, 1, 1, 12, 2),
          logLevel: LogLevel.debug,
          key: 'test_key_3',
        ),
      ];
    });

    test('should export logs to JSON with metadata', () async {
      // Act
      final jsonString = await service.exportToJson(sampleLogs);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Assert
      expect(jsonData.containsKey('metadata'), isTrue);
      expect(jsonData.containsKey('logs'), isTrue);

      final metadata = jsonData['metadata'] as Map<String, dynamic>;
      expect(metadata['totalLogs'], equals(3));
      expect(metadata['version'], equals('1.0.0'));
      expect(metadata['platform'], equals('ispect'));

      final logs = jsonData['logs'] as List<dynamic>;
      expect(logs.length, equals(3));
    });

    test('should export logs to JSON without metadata when specified',
        () async {
      // Act
      final jsonString =
          await service.exportToJson(sampleLogs, includeMetadata: false);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Assert
      expect(jsonData.containsKey('metadata'), isFalse);
      expect(jsonData.containsKey('logs'), isTrue);

      final logs = jsonData['logs'] as List<dynamic>;
      expect(logs.length, equals(3));
    });

    test('should import logs from JSON with metadata', () async {
      // Arrange
      final exportedJson = await service.exportToJson(sampleLogs);

      // Act
      final importedLogs = await service.importFromJson(exportedJson);

      // Assert
      expect(importedLogs.length, equals(3));

      // Check first log
      final firstLog = importedLogs[0];
      expect(firstLog.message, equals('Test log message 1'));
      expect(firstLog.logLevel, equals(LogLevel.info));
      expect(firstLog.key, equals('test_key_1'));
    });

    test('should import logs from legacy JSON format (array only)', () async {
      // Arrange
      final legacyJson = jsonEncode(
        sampleLogs.map((log) => log.toJson()).toList(),
      );

      // Act
      final importedLogs = await service.importFromJson(legacyJson);

      // Assert
      expect(importedLogs.length, equals(3));
      expect(importedLogs[0].message, equals('Test log message 1'));
    });

    test('import redacts sensitive fields and embedded URL tokens by default',
        () async {
      const headerSecret = 'IMPORT_HEADER_SECRET';
      const querySecret = 'IMPORT_QUERY_SECRET';
      const nestedSecret = 'IMPORT_NESTED_SECRET';
      final json = jsonEncode({
        'logs': [
          {
            'message': 'GET https://api.example.test/items?token=$querySecret',
            'time': '2025-01-01T12:00:00.000Z',
            'key': 'http-request',
            'additional-data': {
              'headers': {'Authorization': 'Bearer $headerSecret'},
              'nested': {'password': nestedSecret},
            },
          },
        ],
      });

      final imported = await service.importFromJson(json);
      final log = imported.single;
      final serialized = jsonEncode(log.toJson());

      expect(log.key, 'http-request');
      expect(serialized, isNot(contains(headerSecret)));
      expect(serialized, isNot(contains(querySecret)));
      expect(serialized, isNot(contains(nestedSecret)));
      expect(serialized, contains('[REDACTED]'));
    });

    test('import opt-out retains a bounded raw prefix', () async {
      const rawPrefix = 'RAW_IMPORT_SECRET';
      final padding = ''.padRight(
        LogExportOutput.maxPreparedValueBytes * 2,
        'x',
      );
      final json = jsonEncode({
        'logs': [
          {
            'message': '$rawPrefix$padding',
            'time': '2025-01-01T12:00:00.000Z',
          },
        ],
      });

      final imported = await service.importFromJson(
        json,
        enableRedaction: false,
      );
      final message = imported.single.message!;

      expect(message, startsWith(rawPrefix));
      expect(message, contains(LogExportOutput.truncatedMarker));
      expect(
        utf8.encode(message).length,
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('import drops a record when its redaction service throws', () async {
      const secret = 'THROWING_IMPORT_SECRET';
      final json = jsonEncode({
        'logs': [
          {
            'message': secret,
            'time': '2025-01-01T12:00:00.000Z',
          },
        ],
      });

      final imported = await service.importFromJson(
        json,
        redactionService: _ThrowingEnvelopeRedactionService(),
      );

      expect(imported, isEmpty);
    });

    test('import replaces a hostile null redaction result', () async {
      const secret = 'NULL_IMPORT_SECRET';
      final json = jsonEncode({
        'logs': [
          {
            'message': secret,
            'time': '2025-01-01T12:00:00.000Z',
          },
        ],
      });

      final imported = await service.importFromJson(
        json,
        redactionService: _NullEnvelopeRedactionService(),
      );

      expect(imported.single.message, JsonValueNormalizer.unprintableValue);
      expect(jsonEncode(imported.single.toJson()), isNot(contains(secret)));
    });

    test('should handle empty logs list for export', () async {
      // Act
      final jsonString = await service.exportToJson([]);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Assert
      expect(jsonData['metadata']['totalLogs'], equals(0));
      expect(jsonData['logs'], isEmpty);
    });

    test('should handle empty logs list for import', () async {
      // Arrange
      final emptyJson = jsonEncode({'logs': <dynamic>[]});

      // Act
      final importedLogs = await service.importFromJson(emptyJson);

      // Assert
      expect(importedLogs, isEmpty);
    });

    test('should validate valid JSON structure', () {
      // Arrange
      final validJson = jsonEncode({
        'metadata': {'version': '1.0.0'},
        'logs': [
          {'message': 'test', 'time': DateTime.now().toIso8601String()},
        ],
      });

      // Act & Assert
      expect(service.validateJsonStructure(validJson), isTrue);
    });

    test('should validate legacy JSON structure', () {
      // Arrange
      final legacyJson = jsonEncode([
        {'message': 'test', 'time': DateTime.now().toIso8601String()},
      ]);

      // Act & Assert
      expect(service.validateJsonStructure(legacyJson), isTrue);
    });

    test('should reject invalid JSON structure', () {
      // Arrange
      const invalidJson = '{"invalid": "structure"}';

      // Act & Assert
      expect(service.validateJsonStructure(invalidJson), isFalse);
    });

    test('should reject malformed JSON', () {
      // Arrange
      const malformedJson = '{"invalid": json}';

      // Act & Assert
      expect(service.validateJsonStructure(malformedJson), isFalse);
    });

    test('should extract metadata from JSON export', () async {
      // Arrange
      final jsonString = await service.exportToJson(sampleLogs);

      // Act
      final metadata = service.getMetadataFromJson(jsonString);

      // Assert
      expect(metadata, isNotNull);
      expect(metadata!['totalLogs'], equals(3));
      expect(metadata['version'], equals('1.0.0'));
      expect(metadata['platform'], equals('ispect'));
    });

    test('should return null metadata for legacy format', () {
      // Arrange
      final legacyJson = jsonEncode([
        {'message': 'test', 'time': DateTime.now().toIso8601String()},
      ]);

      // Act
      final metadata = service.getMetadataFromJson(legacyJson);

      // Assert
      expect(metadata, isNull);
    });

    test('should handle logs with various data types', () async {
      // Arrange
      final complexLog = ISpectLogData(
        'Complex log with various data',
        time: DateTime(2025, 1, 1, 15, 30, 45),
        logLevel: LogLevel.warning,
        key: 'complex_key',
        additionalData: const {
          'string': 'test string',
          'number': 42,
          'boolean': true,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        },
        exception: Exception('Complex exception'),
        error: StateError('Complex error'),
      );

      // Act
      final jsonString = await service.exportToJson([complexLog]);
      final importedLogs = await service.importFromJson(jsonString);

      // Assert
      expect(importedLogs.length, equals(1));
      final imported = importedLogs[0];
      expect(imported.message, equals('Complex log with various data'));
      expect(imported.logLevel, equals(LogLevel.warning));
      expect(imported.additionalData?['number'], equals(42));
      expect(imported.additionalData?['boolean'], isTrue);
    });

    test('should preserve log order during export/import cycle', () async {
      // Arrange
      final orderedLogs = List.generate(
        10,
        (index) => ISpectLogData(
          'Log message $index',
          time: DateTime(2025, 1, 1, 12, index),
          key: 'key_$index',
        ),
      );

      // Act
      final jsonString = await service.exportToJson(orderedLogs);
      final importedLogs = await service.importFromJson(jsonString);

      // Assert
      expect(importedLogs.length, equals(10));
      for (var i = 0; i < 10; i++) {
        expect(importedLogs[i].message, equals('Log message $i'));
        expect(importedLogs[i].key, equals('key_$i'));
      }
    });

    test('exports and round-trips more than 1000 logs without truncation',
        () async {
      final logs = List.generate(
        1005,
        (index) => ISpectLogData(
          'Bulk log $index',
          time: DateTime(2025).add(Duration(seconds: index)),
          key: 'bulk_key_$index',
        ),
      );

      final jsonString = await service.exportToJson(logs);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final exportedLogs = decoded['logs'] as List<dynamic>;
      final metadata = decoded['metadata'] as Map<String, dynamic>;
      final importedLogs = await service.importFromJson(jsonString);

      expect(exportedLogs, hasLength(logs.length));
      expect(metadata['totalLogs'], logs.length);
      expect(importedLogs, hasLength(logs.length));
      expect(importedLogs.first.message, 'Bulk log 0');
      expect(importedLogs.last.message, 'Bulk log 1004');
    });

    group('export output budgets', () {
      test('oversized sensitive records fail closed as valid bounded JSON',
          () async {
        const secret = 'OVERSIZED_JSON_EXPORT_SECRET';
        final padding = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'x');
        final json = await service.exportToJson([
          ISpectLogData(
            'token=$secret$padding',
            time: DateTime(2025),
          ),
        ]);
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;

        expect(json, isNot(contains(secret)));
        expect(
          exportedLog['message'],
          equals(LogExportOutput.truncatedMarker),
        );
        expect(
          utf8.encode(json).length,
          lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
        );
      });

      test('explicit opt-out retains a bounded raw prefix', () async {
        const prefix = 'RAW_JSON_EXPORT_PREFIX';
        final padding = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'x');
        final json = await service.exportToJson(
          [
            ISpectLogData(
              '$prefix$padding',
              time: DateTime(2025),
            ),
          ],
          enableRedaction: false,
        );
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;
        final message = exportedLog['message'] as String;

        expect(message, startsWith(prefix));
        expect(message, contains(LogExportOutput.truncatedMarker));
        expect(
          utf8.encode(json).length,
          lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
        );
      });

      test('huge-id opt-out export retains a field required for import',
          () async {
        final hugeId = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'i');
        final json = await service.exportToJson(
          [
            ISpectLogData(
              'safe',
              id: hugeId,
              time: DateTime.utc(2025),
            ),
          ],
          enableRedaction: false,
        );
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;
        final importedLogs = await service.importFromJson(json);

        expect(exportedLog['time'], DateTime.utc(2025).toIso8601String());
        expect(
          exportedLog['id'],
          contains(LogExportOutput.truncatedMarker),
        );
        expect(importedLogs, hasLength(1));
        expect(importedLogs.single.time, DateTime.utc(2025));
      });

      test('many-record regular and filtered exports stay valid and bounded',
          () async {
        final message = 'bounded-${''.padRight(8000, 'x')}';
        final logs = List.generate(
          1200,
          (index) => ISpectLogData(
            message,
            time: DateTime(2025).add(Duration(seconds: index)),
          ),
        );
        final outputs = [
          await service.exportToJson(
            logs,
            enableRedaction: false,
          ),
          service.formatFilteredContent(
            logs: logs,
            filteredLogs: logs,
            filter: ISpectFilter(),
            fileType: 'json',
            enableRedaction: false,
          ),
        ];

        for (final output in outputs) {
          final decoded = jsonDecode(output) as Map<String, dynamic>;
          final exportedLogs = decoded['logs'] as List<dynamic>;
          final metadata = decoded['metadata'] as Map<String, dynamic>;

          expect(
            utf8.encode(output).length,
            lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
          );
          expect(exportedLogs.length, greaterThan(1000));
          expect(exportedLogs.length, lessThan(logs.length));
          expect(metadata['totalLogs'], logs.length);
        }
      });

      test('never executes caller formatters in regular or filtered JSON',
          () async {
        final hostileDateTime = _HostileServiceDateTime();
        final hostileUri = _HostileServiceUri();
        final hostileException = _HostileServiceException();
        final hostileError = _HostileServiceError();
        final hostileStackTrace = _HostileServiceStackTrace();
        final hostileJson = _HostileServiceJsonValue();
        final log = ISpectLogData(
          'safe',
          exception: hostileException,
          error: hostileError,
          stackTrace: hostileStackTrace,
          additionalData: {
            'dateTime': hostileDateTime,
            'uri': hostileUri,
            'json': hostileJson,
          },
        );
        final metadata = ISpectMetadata(
          extra: {
            'dateTime': hostileDateTime,
            'uri': hostileUri,
            'json': hostileJson,
            'exception': hostileException,
            'error': hostileError,
            'stackTrace': hostileStackTrace,
          },
        );
        final outputs = [
          await service.exportToJson([log], metadata: metadata),
          service.formatFilteredContent(
            logs: [log],
            filteredLogs: [log],
            filter: ISpectFilter(),
            fileType: 'json',
            metadata: metadata,
          ),
        ];

        for (final output in outputs) {
          expect(() => jsonDecode(output), returnsNormally);
          expect(
            utf8.encode(output).length,
            lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
          );
        }
        for (final calls in [
          hostileDateTime.calls,
          hostileUri.calls,
          hostileException.calls,
          hostileError.calls,
          hostileStackTrace.calls,
          hostileJson.calls,
        ]) {
          expect(calls, 0);
        }
      });

      test('caps aggregate nodes so every export remains importable', () async {
        final additionalData = {
          for (var index = 0; index < 1000; index++) 'k$index': index,
        };
        final logs = List.generate(
          120,
          (index) => ISpectLogData(
            'wide $index',
            time: DateTime(2025).add(Duration(seconds: index)),
            additionalData: additionalData,
          ),
        );

        final json = await service.exportToJson(
          logs,
          enableRedaction: false,
        );
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLogs = decoded['logs'] as List<dynamic>;
        final importedLogs = await service.importFromJson(json);

        expect(
          () => JsonInputPreflight.validate(json),
          returnsNormally,
        );
        expect(exportedLogs.length, greaterThan(80));
        expect(exportedLogs.length, lessThan(logs.length));
        expect(importedLogs.length, exportedLogs.length);
      });

      test('deep records and oversized fallback fields remain importable',
          () async {
        Object nested = 'leaf';
        for (var depth = 0;
            depth < JsonInputPreflight.maxNestingDepth + 8;
            depth++) {
          nested = {'child': nested};
        }
        final hugeId = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'i');
        final json = await service.exportToJson([
          ISpectLogData(
            'deep',
            id: hugeId,
            additionalData: {'nested': nested},
          ),
        ]);
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;
        final importedLogs = await service.importFromJson(json);

        expect(
          () => JsonInputPreflight.validate(json),
          returnsNormally,
        );
        expect(exportedLog['export-error'], LogExportOutput.truncatedMarker);
        expect(exportedLog.containsKey('id'), isFalse);
        expect(importedLogs, hasLength(1));
        expect(
          utf8.encode(jsonEncode(exportedLog)).length,
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      });

      test('fallback uses package-owned time without invoking hostile getters',
          () async {
        final hostileLog = _HostileServiceLogGetters();

        final json = await service.exportToJson(
          [hostileLog],
          redactionService: _EmptyEnvelopeRedactionService(),
        );
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;

        expect(exportedLog['time'], DateTime.utc(2025).toIso8601String());
        expect(exportedLog['export-error'], LogExportOutput.truncatedMarker);
        expect(hostileLog.getterCalls, 0);
      });

      test('normalizes non-finite numbers before encoding a huge-id log',
          () async {
        final hugeId = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'i');
        final json = await service.exportToJson([
          ISpectLogData(
            'non-finite',
            id: hugeId,
            additionalData: const {
              'nan': double.nan,
              'positiveInfinity': double.infinity,
              'negativeInfinity': double.negativeInfinity,
            },
          ),
        ]);
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;
        final additional =
            exportedLog['additional-data'] as Map<String, dynamic>;

        expect(additional['nan'], 'NaN');
        expect(additional['positiveInfinity'], 'Infinity');
        expect(additional['negativeInfinity'], '-Infinity');
        expect(
          utf8.encode(jsonEncode(exportedLog)).length,
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      });
    });

    test('should throw FormatException for completely invalid JSON', () async {
      // Arrange
      const invalidJson = 'not json at all';

      // Act & Assert
      expect(
        () async => service.importFromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('malformed import errors do not retain the source payload', () async {
      const secret = 'MALFORMED-LOG-IMPORT-SECRET';

      try {
        await service.importFromJson('{"logs":[],"token":"$secret",}');
        fail('Expected malformed JSON to throw.');
      } on FormatException catch (error) {
        expect(error.message, JsonInputPreflight.invalidContent);
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains(secret)));
      }
    });

    group('hostile JSON preflight', () {
      test('rejects oversized content across import and inspection APIs',
          () async {
        final oversizedPrefix = '{"logs":[],"padding":"'.padRight(
          LogsJsonService.maxJsonSize,
          'x',
        );
        final oversizedJson = '$oversizedPrefix"}';

        await expectLater(
          service.importFromJson(oversizedJson),
          throwsA(isA<JsonInputLimitException>()),
        );
        expect(service.validateJsonStructure(oversizedJson), isFalse);
        expect(service.getMetadataFromJson(oversizedJson), isNull);
      });

      test('rejects deep content across import and inspection APIs', () async {
        final openings = List<String>.filled(
          LogsJsonService.maxJsonDepth + 1,
          '[',
        ).join();
        final closings = List<String>.filled(
          LogsJsonService.maxJsonDepth + 1,
          ']',
        ).join();
        final deepJson = '$openings$closings';

        await expectLater(
          service.importFromJson(deepJson),
          throwsA(isA<JsonInputLimitException>()),
        );
        expect(service.validateJsonStructure(deepJson), isFalse);
        expect(service.getMetadataFromJson(deepJson), isNull);
      });

      test('rejects wide content across import and inspection APIs', () async {
        final entries = List<String>.filled(
          LogsJsonService.maxJsonNodes,
          'null',
        ).join(',');
        final wideJson = '[$entries]';

        await expectLater(
          service.importFromJson(wideJson),
          throwsA(isA<JsonInputLimitException>()),
        );
        expect(service.validateJsonStructure(wideJson), isFalse);
        expect(service.getMetadataFromJson(wideJson), isNull);
      });
    });

    test('should skip invalid log entries during import', () async {
      // Arrange
      final mixedJson = jsonEncode({
        'logs': [
          {
            'message': 'Valid log',
            'time': DateTime.now().toIso8601String(),
          },
          {
            'invalid': 'log without required fields',
          },
          {
            'message': 'Another valid log',
            'time': DateTime.now().toIso8601String(),
          },
        ],
      });

      // Act
      final importedLogs = await service.importFromJson(mixedJson);

      // Assert
      expect(importedLogs.length, equals(2));
      expect(importedLogs[0].message, equals('Valid log'));
      expect(importedLogs[1].message, equals('Another valid log'));
    });

    test('should handle empty logs gracefully in shareLogsAsJsonFile',
        () async {
      // Act & Assert - should not throw
      await expectLater(
        service.shareLogsAsJsonFile(
          [],
          onShare: (_) async {},
        ),
        completes,
      );
    });

    test(
        'exportToJson applies redactionService when provided alongside '
        'enableRedaction', () async {
      final sensitiveLog = ISpectLogData(
        'Sensitive payload',
        time: DateTime(2025, 1, 1, 12),
        logLevel: LogLevel.info,
        additionalData: const {
          'authorization': 'Bearer super-secret-token',
          'safe': 'visible',
        },
      );

      final jsonString = await service.exportToJson(
        [sensitiveLog],
        redactionService: RedactionService(),
      );
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final logs = jsonData['logs'] as List<dynamic>;
      final additional = (logs.first as Map<String, dynamic>)['additional-data']
          as Map<String, dynamic>;

      expect(
        additional['authorization'],
        isNot(contains('super-secret-token')),
      );
      expect(additional['safe'], equals('visible'));
    });

    test('exportToJson redacts secrets embedded in messages', () async {
      final sensitiveLog = ISpectLogData(
        'failed https://alice:password@example.test/users?token=JSON_EXPORT_SECRET',
        time: DateTime(2025, 1, 1, 12),
      );

      final jsonString = await service.exportToJson(
        [sensitiveLog],
        redactionService: RedactionService(),
      );

      expect(jsonString, isNot(contains('password')));
      expect(jsonString, isNot(contains('JSON_EXPORT_SECRET')));
      expect(jsonString, contains('[REDACTED]'));
    });

    test('exportToJson redacts by default when no service is supplied',
        () async {
      final sensitiveLog = ISpectLogData(
        'Sensitive payload',
        time: DateTime(2025, 1, 1, 12),
        logLevel: LogLevel.info,
        additionalData: const {'authorization': 'Bearer raw'},
      );

      final jsonString = await service.exportToJson([sensitiveLog]);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final logs = jsonData['logs'] as List<dynamic>;
      final additional = (logs.first as Map<String, dynamic>)['additional-data']
          as Map<String, dynamic>;

      expect(additional['authorization'], isNot(equals('Bearer raw')));
      expect(additional['authorization'], contains('[REDACTED]'));
    });

    test('exportToJson resolves the global custom redaction policy', () async {
      final globalService = RedactionService(
        sensitiveKeys: const {'global_field'},
        placeholder: '<global>',
      );
      ISpectRedaction.configure(service: globalService);
      final sensitiveLog = ISpectLogData(
        'Sensitive payload',
        time: DateTime(2025, 1, 1, 12),
        additionalData: const {
          'global_field': 'GLOBAL_RAW',
          'safe_field': 'VISIBLE',
        },
      );

      final jsonString = await service.exportToJson([sensitiveLog]);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final logs = jsonData['logs'] as List<dynamic>;
      final additional = (logs.first as Map<String, dynamic>)['additional-data']
          as Map<String, dynamic>;

      expect('${additional['global_field']}', contains('<global>'));
      expect('${additional['global_field']}', isNot(contains('GLOBAL_RAW')));
      expect(additional['safe_field'], 'VISIBLE');
    });

    test('an explicit export service overrides only that export', () async {
      final globalService = RedactionService(
        sensitiveKeys: const {'global_field'},
        placeholder: '<global>',
      );
      final localService = RedactionService(
        sensitiveKeys: const {'local_field'},
        placeholder: '<local>',
      );
      ISpectRedaction.configure(service: globalService);
      final sensitiveLog = ISpectLogData(
        'Sensitive payload',
        time: DateTime(2025, 1, 1, 12),
        additionalData: const {
          'global_field': 'GLOBAL_RAW',
          'local_field': 'LOCAL_RAW',
        },
      );

      final jsonString = await service.exportToJson(
        [sensitiveLog],
        redactionService: localService,
      );
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final logs = jsonData['logs'] as List<dynamic>;
      final additional = (logs.first as Map<String, dynamic>)['additional-data']
          as Map<String, dynamic>;

      expect(additional['global_field'], 'GLOBAL_RAW');
      expect('${additional['local_field']}', contains('<local>'));
      expect('${additional['local_field']}', isNot(contains('LOCAL_RAW')));
      expect(ISpectRedaction.service, same(globalService));
    });

    test('exportToJson honors an explicit per-export redaction opt-out',
        () async {
      final sensitiveLog = ISpectLogData(
        'Sensitive payload',
        time: DateTime(2025, 1, 1, 12),
        additionalData: const {'authorization': 'Bearer raw'},
      );

      final jsonString = await service.exportToJson(
        [sensitiveLog],
        enableRedaction: false,
      );

      expect(jsonString, contains('Bearer raw'));
    });

    test('exportToJson honors the global redaction opt-out', () async {
      ISpectRedaction.enabled = false;
      final sensitiveLog = ISpectLogData(
        'failed https://example.test/users?token=JSON_GLOBAL_RAW',
        time: DateTime(2025, 1, 1, 12),
      );

      final jsonString = await service.exportToJson(
        [sensitiveLog],
        redactionService: RedactionService(),
      );

      expect(jsonString, contains('JSON_GLOBAL_RAW'));
    });

    test(
        'should handle empty filtered logs gracefully in shareFilteredLogsAsJsonFile',
        () async {
      // Arrange
      final filter = ISpectFilter();

      // Act & Assert - should not throw
      await expectLater(
        service.shareFilteredLogsAsJsonFile(
          [],
          [],
          filter,
          onShare: (_) async {},
        ),
        completes,
      );
    });

    group('environment metadata', () {
      test('merges supplied metadata into the export metadata block', () async {
        final json = await service.exportToJson(
          sampleLogs,
          metadata: const ISpectMetadata(
            appVersion: '1.4.2',
            os: 'iOS',
            extra: {'flavor': 'qa'},
          ),
        );

        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final metadata = decoded['metadata'] as Map<String, dynamic>;

        expect(metadata['appVersion'], equals('1.4.2'));
        expect(metadata['os'], equals('iOS'));
        expect(metadata['flavor'], equals('qa'));
        expect(metadata['platform'], equals('ispect'));
      });

      test('redacts secrets embedded in supplied metadata', () async {
        final json = await service.exportToJson(
          sampleLogs,
          metadata: const ISpectMetadata(
            extra: {
              'endpoint': 'https://example.test/users?token=METADATA_SECRET',
            },
          ),
          redactionService: RedactionService(),
        );

        expect(json, isNot(contains('METADATA_SECRET')));
        expect(json, contains('[REDACTED]'));
      });

      test('custom redactor null result cannot restore raw metadata', () async {
        const secret = 'NULL_REDACTOR_METADATA_SECRET';

        final json = await service.exportToJson(
          sampleLogs,
          metadata: const ISpectMetadata(extra: {'token': secret}),
          redactionService: _NullRedactionService(),
        );

        expect(json, isNot(contains(secret)));
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        expect(decoded[ISpectMetadata.exportKey], isNull);
      });

      test('redacts typed binary before JSON normalization', () async {
        final bytes = Uint8List.fromList(List<int>.filled(64, 122));
        final log = ISpectLogData(
          'binary',
          additionalData: {'payload': bytes},
        );
        final metadata = ISpectMetadata(extra: {'diagnosticBytes': bytes});

        final json = await service.exportToJson([log], metadata: metadata);
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final exportedMetadata =
            decoded[ISpectMetadata.exportKey] as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;
        final additional =
            exportedLog['additional-data'] as Map<String, dynamic>;

        for (final value in [
          exportedMetadata['diagnosticBytes'],
          additional['payload'],
        ]) {
          final redactedBytes = value as List<dynamic>;
          expect(redactedBytes.take(7), equals('[binary'.codeUnits));
          expect(redactedBytes, isNot(contains(122)));
        }
      });

      test('host metadata cannot replace authoritative export fields',
          () async {
        final json = await service.exportToJson(
          sampleLogs,
          metadata: const ISpectMetadata(
            extra: {
              'exportedAt': 'attacker-controlled',
              'version': '999.0.0',
              'totalLogs': -1,
              'platform': 'spoofed',
            },
          ),
        );

        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final metadata = decoded['metadata'] as Map<String, dynamic>;

        expect(metadata['exportedAt'], isNot('attacker-controlled'));
        expect(metadata['version'], '1.0.0');
        expect(metadata['totalLogs'], sampleLogs.length);
        expect(metadata['platform'], 'ispect');
      });

      test('omits environment fields when no metadata is supplied', () async {
        final json = await service.exportToJson(sampleLogs);

        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final metadata = decoded['metadata'] as Map<String, dynamic>;

        expect(metadata.containsKey('appVersion'), isFalse);
        expect(metadata['platform'], equals('ispect'));
      });
    });

    group('filtered JSON redaction (H6)', () {
      ISpectLogData sensitiveLog() => ISpectLogData(
            'Sensitive filtered payload',
            time: DateTime(2025, 1, 1, 12),
            logLevel: LogLevel.info,
            additionalData: const {
              'authorization': 'Bearer super-secret-token',
              'safe': 'visible',
            },
          );

      String jsonContentFor(
        List<ISpectLogData> logs, {
        bool enableRedaction = true,
        Set<String>? redactKeys,
      }) =>
          service.formatFilteredContent(
            logs: logs,
            filteredLogs: logs,
            filter: ISpectFilter(),
            fileType: 'json',
            enableRedaction: enableRedaction,
            redactKeys: redactKeys,
          );

      test('masks sensitive values in filtered JSON when redactKeys is set',
          () {
        final content = jsonContentFor(
          [sensitiveLog()],
          redactKeys: const {'authorization'},
        );

        expect(content, isNot(contains('super-secret-token')));
        expect(content, contains('visible'));
      });

      test('redacts default sensitive keys in filtered JSON by default', () {
        final log = ISpectLogData(
          'Sensitive filtered payload',
          time: DateTime(2025, 1, 1, 12),
          logLevel: LogLevel.info,
          additionalData: const {'password': 'hunter2', 'safe': 'visible'},
        );

        final content = jsonContentFor([log]);

        expect(content, isNot(contains('hunter2')));
        expect(content, contains('visible'));
      });

      test('filtered JSON retains more than 1000 matching logs', () {
        final logs = List.generate(
          1005,
          (index) => ISpectLogData(
            'Filtered log $index',
            time: DateTime(2025).add(Duration(seconds: index)),
            key: 'filtered_key_$index',
          ),
        );

        final content = jsonContentFor(logs);
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final exportedLogs = decoded['logs'] as List<dynamic>;
        final metadata = decoded['metadata'] as Map<String, dynamic>;

        expect(exportedLogs, hasLength(logs.length));
        expect(metadata['totalLogs'], logs.length);
        expect(metadata['filteredLogs'], logs.length);
      });

      test('keeps filtered JSON raw when redaction is disabled (opt-out)', () {
        final content = jsonContentFor(
          [sensitiveLog()],
          enableRedaction: false,
        );

        expect(content, contains('super-secret-token'));
      });

      test('custom redactor null result cannot restore filtered metadata', () {
        const secret = 'NULL_REDACTOR_FILTERED_SECRET';
        final log = sensitiveLog();

        final content = service.formatFilteredContent(
          logs: [log],
          filteredLogs: [log],
          filter: ISpectFilter(),
          fileType: 'json',
          metadata: const ISpectMetadata(extra: {'token': secret}),
          redactionService: _NullRedactionService(),
        );

        expect(content, isNot(contains(secret)));
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        expect(decoded[ISpectMetadata.exportKey], isNull);
      });

      test('custom redactor failure aborts before sharing', () async {
        var shared = false;
        final log = sensitiveLog();

        await expectLater(
          service.shareFilteredLogsAsJsonFile(
            [log],
            [log],
            ISpectFilter(),
            onShare: (_) async => shared = true,
            redactionService: _ThrowingRedactionService(),
          ),
          throwsA(isA<StateError>()),
        );
        expect(shared, isFalse);
      });

      for (final fileType in const ['txt', 'md', 'csv']) {
        test('$fileType forwards the explicit redaction opt-out', () {
          final log = ISpectLogData(
            'failed https://example.test?token=super-secret-token',
            time: DateTime(2025, 1, 1, 12),
          );

          final safeContent = service.formatFilteredContent(
            logs: [log],
            filteredLogs: [log],
            filter: ISpectFilter(),
            fileType: fileType,
          );
          final rawContent = service.formatFilteredContent(
            logs: [log],
            filteredLogs: [log],
            filter: ISpectFilter(),
            fileType: fileType,
            enableRedaction: false,
          );

          expect(safeContent, isNot(contains('super-secret-token')));
          expect(rawContent, contains('super-secret-token'));
        });
      }

      test('all formats honor the supplied custom redaction service', () {
        final customService = RedactionService(
          sensitiveKeys: const {},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
          placeholder: '<CUSTOM_POLICY>',
        );
        final log = ISpectLogData(
          'tenantCredential=FILTERED_CUSTOM_SECRET',
          time: DateTime(2025, 1, 1, 12),
        );

        for (final fileType in const ['txt', 'md', 'csv', 'json']) {
          final content = service.formatFilteredContent(
            logs: [log],
            filteredLogs: [log],
            filter: ISpectFilter(),
            fileType: fileType,
            redactionService: customService,
            redactKeys: const {'unrelated'},
          );

          expect(
            content,
            isNot(contains('FILTERED_CUSTOM_SECRET')),
            reason: '$fileType ignored the supplied service',
          );
          expect(
            content,
            contains(
              fileType == 'md' ? '&lt;CUSTOM_POLICY&gt;' : '<CUSTOM_POLICY>',
            ),
          );
        }
      });

      test('host metadata cannot replace filtered export fields', () {
        final content = service.formatFilteredContent(
          logs: [sensitiveLog()],
          filteredLogs: [sensitiveLog()],
          filter: ISpectFilter(),
          fileType: 'json',
          metadata: const ISpectMetadata(
            extra: {
              'exportedAt': 'attacker-controlled',
              'totalLogs': -1,
              'filteredLogs': -1,
              'platform': 'spoofed',
              'appliedFilter': 'spoofed',
            },
          ),
        );

        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final metadata = decoded['metadata'] as Map<String, dynamic>;

        expect(metadata['exportedAt'], isNot('attacker-controlled'));
        expect(metadata['totalLogs'], 1);
        expect(metadata['filteredLogs'], 1);
        expect(metadata['platform'], 'ispect');
        expect(metadata['appliedFilter'], isA<Map<String, dynamic>>());
      });

      test('filtered JSON redacts typed binary before normalization', () {
        final bytes = Uint8List.fromList(List<int>.filled(64, 122));
        final log = ISpectLogData(
          'binary',
          additionalData: {'payload': bytes},
        );

        final content = service.formatFilteredContent(
          logs: [log],
          filteredLogs: [log],
          filter: ISpectFilter(),
          fileType: 'json',
          metadata: ISpectMetadata(extra: {'diagnosticBytes': bytes}),
        );
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final metadata =
            decoded[ISpectMetadata.exportKey] as Map<String, dynamic>;
        final exportedLog =
            (decoded['logs'] as List<dynamic>).single as Map<String, dynamic>;
        final additional =
            exportedLog['additional-data'] as Map<String, dynamic>;

        for (final value in [
          metadata['diagnosticBytes'],
          additional['payload'],
        ]) {
          final redactedBytes = value as List<dynamic>;
          expect(redactedBytes.take(7), equals('[binary'.codeUnits));
          expect(redactedBytes, isNot(contains(122)));
        }
      });
    });
  });
}

final class _NullRedactionService extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      null;
}

final class _ThrowingRedactionService extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      throw StateError('redaction failed');
}

final class _EmptyEnvelopeRedactionService extends RedactionService {
  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      const <String, Object?>{};
}

final class _NullEnvelopeRedactionService extends RedactionService {
  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      null;
}

final class _ThrowingEnvelopeRedactionService extends RedactionService {
  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      throw StateError('import redaction failed');
}
