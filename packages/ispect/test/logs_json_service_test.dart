// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  group('LogsJsonService Tests', () {
    late LogsJsonService service;
    late List<ISpectifyData> sampleLogs;

    setUp(() {
      service = const LogsJsonService();
      sampleLogs = [
        ISpectifyData(
          'Test log message 1',
          time: DateTime(2025, 1, 1, 12),
          logLevel: LogLevel.info,
          title: 'Test',
          key: 'test_key_1',
          additionalData: {'testData': 'value1'},
        ),
        ISpectifyData(
          'Test log message 2',
          time: DateTime(2025, 1, 1, 12, 1),
          logLevel: LogLevel.error,
          title: 'Error',
          key: 'test_key_2',
          exception: Exception('Test exception'),
          additionalData: {'errorCode': 500},
        ),
        ISpectifyData(
          'Test log message 3',
          time: DateTime(2025, 1, 1, 12, 2),
          logLevel: LogLevel.debug,
          title: 'Debug',
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
      expect(firstLog.title, equals('Test'));
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
      final complexLog = ISpectifyData(
        'Complex log with various data',
        time: DateTime(2025, 1, 1, 15, 30, 45),
        logLevel: LogLevel.warning,
        title: 'Complex',
        key: 'complex_key',
        additionalData: {
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
        (index) => ISpectifyData(
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

    test('should throw FormatException for completely invalid JSON', () async {
      // Arrange
      const invalidJson = 'not json at all';

      // Act & Assert
      expect(
        () async => service.importFromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
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
  });
}
