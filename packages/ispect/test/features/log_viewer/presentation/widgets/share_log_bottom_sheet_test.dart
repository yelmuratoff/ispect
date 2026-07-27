import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_log_bottom_sheet.dart';
import 'package:ispectify/ispectify.dart';

final class _ThrowingRedactionStrategy implements RedactionStrategy {
  const _ThrowingRedactionStrategy();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      throw StateError('synthetic redaction failure');
}

final class _CountingExtraMap extends MapBase<String, Object?> {
  _CountingExtraMap({
    required this.entryCount,
    required this.value,
  });

  final int entryCount;
  final String value;
  int visitedEntries = 0;

  @override
  Iterable<MapEntry<String, Object?>> get entries sync* {
    for (var index = 0; index < entryCount; index++) {
      visitedEntries++;
      yield MapEntry('field-$index', value);
    }
  }

  @override
  Iterable<String> get keys =>
      Iterable<String>.generate(entryCount, (index) => 'field-$index');

  @override
  Object? operator [](Object? key) => value;

  @override
  void operator []=(String key, Object? value) =>
      throw UnsupportedError('read-only test map');

  @override
  void clear() => throw UnsupportedError('read-only test map');

  @override
  Object? remove(Object? key) => throw UnsupportedError('read-only test map');
}

final class _HostileDiagnostic {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    throw StateError('toJson must not execute');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('toString must not execute');
  }
}

void main() {
  tearDown(() => ISpectRedaction.enabled = true);

  group('ISpectShareLogBottomSheet.buildContent', () {
    final data = <String, dynamic>{
      'id': '01KVDNQHAXXDD3V4967PV198FP',
      'key': 'info',
      'time': '2026-06-18T20:31:25.149609',
      'log-level': '3',
      'message': '[badge] NotificationCountCubit.get: server count=18',
    };

    const metadata = ISpectMetadata(
      appName: 'ISpect Quick Start',
      appVersion: '1.0.0',
      buildNumber: '1',
      environment: 'dev',
    );

    test('merges environment metadata into the exported JSON record', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: metadata,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final exportedMeta = decoded['metadata'] as Map<String, dynamic>;
      expect(exportedMeta['appName'], equals('ISpect Quick Start'));
      expect(exportedMeta['appVersion'], equals('1.0.0'));
      expect(exportedMeta['buildNumber'], equals('1'));
      expect(exportedMeta['environment'], equals('dev'));
      expect(decoded['id'], equals('01KVDNQHAXXDD3V4967PV198FP'));
      expect(
        decoded['message'],
        equals('[badge] NotificationCountCubit.get: server count=18'),
      );
    });

    test('omits the metadata block when no metadata is supplied', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded.containsKey('metadata'), isFalse);
    });

    test('omits the metadata block when metadata has no fields set', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: const ISpectMetadata(),
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded.containsKey('metadata'), isFalse);
    });

    test('copy action exports the truncated record with metadata', () {
      final full = <String, dynamic>{...data, 'message': 'full message'};
      final truncated = <String, dynamic>{...data, 'message': 'short'};

      final content = ISpectShareLogBottomSheet.buildContent(
        data: full,
        truncatedData: truncated,
        format: ExportFormat.json,
        action: ExportAction.copy,
        metadata: metadata,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded['message'], equals('short'));
      expect(decoded.containsKey('metadata'), isTrue);
    });

    test('metadata survives the redaction pass', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        redactKeys: const {'token', 'password'},
        metadata: metadata,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final exportedMeta = decoded['metadata'] as Map<String, dynamic>;
      expect(exportedMeta['appName'], equals('ISpect Quick Start'));
    });

    test('redacts secrets embedded in metadata', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        redactKeys: defaultSensitiveKeys,
        metadata: const ISpectMetadata(
          extra: {
            'endpoint': 'https://example.test/users?token=METADATA_SECRET',
          },
        ),
      );

      expect(content, isNot(contains('METADATA_SECRET')));
      expect(content, contains('[REDACTED]'));
    });

    test('redacts secrets embedded in the free-form message', () {
      final sensitive = <String, dynamic>{
        ...data,
        'message':
            'failed https://alice:password@example.test/users?token=SHARE_SECRET',
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.json,
        action: ExportAction.share,
        redactKeys: defaultSensitiveKeys,
      );

      expect(content, isNot(contains('password')));
      expect(content, isNot(contains('SHARE_SECRET')));
      expect(content, contains('[REDACTED]'));
    });

    test('redacts free-form messages by default when keys are omitted', () {
      final sensitive = <String, dynamic>{
        ...data,
        'message': 'failed https://example.test/users?token=SHARE_DEFAULT',
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.json,
        action: ExportAction.share,
      );

      expect(content, isNot(contains('SHARE_DEFAULT')));
      expect(content, contains('[REDACTED]'));
    });

    test('preserves the root log key but redacts nested key values', () {
      final sensitive = <String, dynamic>{
        ...data,
        'additional-data': {
          'key': 'NESTED_KEY_SECRET',
        },
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.json,
        action: ExportAction.share,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final additional = decoded['additional-data'] as Map<String, dynamic>;
      expect(decoded['key'], 'info');
      expect(additional['key'], contains(defaultPlaceholder));
      expect(content, isNot(contains('NESTED_KEY_SECRET')));
    });

    test('keeps free-form messages raw after explicit export opt-out', () {
      final sensitive = <String, dynamic>{
        ...data,
        'message': 'failed https://example.test/users?token=SHARE_RAW',
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.json,
        action: ExportAction.share,
        enableRedaction: false,
      );

      expect(content, contains('SHARE_RAW'));
    });

    test('honors the global redaction opt-out', () {
      ISpectRedaction.enabled = false;
      final sensitive = <String, dynamic>{
        ...data,
        'message': 'failed https://example.test/users?token=GLOBAL_RAW',
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.json,
        action: ExportAction.share,
        redactKeys: defaultSensitiveKeys,
      );

      expect(content, contains('GLOBAL_RAW'));
    });

    test('does not mutate the source record maps', () {
      final source = <String, dynamic>{...data};

      ISpectShareLogBottomSheet.buildContent(
        data: source,
        truncatedData: source,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: metadata,
      );

      expect(source.containsKey('metadata'), isFalse);
    });

    test('redacts typed binary preserved by single-log share call sites', () {
      final log = ISpectLogData(
        'binary',
        additionalData: {
          'bytes': Uint8List.fromList(List<int>.filled(64, 211)),
          'words': Uint16List.fromList(List<int>.filled(32, 60000)),
          'buffer': Uint8List.fromList(List<int>.filled(64, 244)).buffer,
        },
      );
      final source = log.toJson(preserveTypes: true);

      final content = ISpectShareLogBottomSheet.buildContent(
        data: source,
        truncatedData: source,
        format: ExportFormat.json,
        action: ExportAction.share,
      );
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final additional = decoded['additional-data'] as Map<String, dynamic>;

      for (final key in const ['bytes', 'words', 'buffer']) {
        expect(
          additional[key],
          utf8.encode('[binary 64 bytes]'),
        );
      }
      expect(content, isNot(contains('60000')));
      expect(content, isNot(contains('211, 211, 211')));
      expect(content, isNot(contains('244, 244, 244')));
    });

    test('bounds large typed binary when binary masking is disabled', () {
      const byteLength = 4 * 1024 * 1024;
      final bytes = Uint8List(byteLength)..fillRange(0, byteLength, 77);

      final content = ISpectShareLogBottomSheet.buildContent(
        data: {
          'additional-data': {'payload': bytes},
        },
        truncatedData: {
          'additional-data': {'payload': bytes},
        },
        format: ExportFormat.json,
        action: ExportAction.share,
        redactionService: RedactionService(redactBinary: false),
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final additional = decoded['additional-data'] as Map<String, dynamic>;
      expect(additional['payload'], '[binary $byteLength bytes]');
      expect(content, isNot(contains('77,77,77')));
      _expectWithinSingleRecordLimit(content);
    });

    test('fails closed when export redaction cannot return a safe map', () {
      final sensitive = <String, dynamic>{
        'password': 'SHARE_FAIL_OPEN_SECRET',
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.json,
        action: ExportAction.share,
        redactionService: RedactionService(
          strategy: const _ThrowingRedactionStrategy(),
        ),
      );

      expect(content, isNot(contains('SHARE_FAIL_OPEN_SECRET')));
      expect(
        jsonDecode(content),
        {'diagnostic': defaultPlaceholder},
      );
    });

    test('neutralizes formulas and control-prefixed formulas in CSV', () {
      final sensitive = <String, dynamic>{
        '=HYPERLINK("https://example.test")': '\r=1+1',
      };

      final content = ISpectShareLogBottomSheet.buildContent(
        data: sensitive,
        truncatedData: sensitive,
        format: ExportFormat.csv,
        action: ExportAction.share,
      );

      expect(content, isNot(contains('"=HYPERLINK')));
      expect(content, isNot(contains('"\r=1+1')));
    });

    test(
      'bounds many-leaf metadata and preserves every format framing',
      () {
        final extra = _CountingExtraMap(
          entryCount: 100000,
          value: List<String>.filled(256, '\u0000').join(),
        );
        final contents = {
          for (final format in ExportFormat.values)
            format: ISpectShareLogBottomSheet.buildContent(
              data: data,
              truncatedData: data,
              format: format,
              action: ExportAction.share,
              metadata: ISpectMetadata(extra: extra),
            ),
        };

        for (final content in contents.values) {
          _expectWithinSingleRecordLimit(content);
        }

        expect(
          jsonDecode(contents[ExportFormat.json]!),
          isA<Map<String, dynamic>>(),
        );
        final csvRows = _parseCsv(contents[ExportFormat.csv]!);
        expect(csvRows, isNotEmpty);
        expect(csvRows.first, ['Key', 'Value']);
        expect(csvRows.every((row) => row.length == 2), isTrue);
        _expectClosedMarkdownFence(contents[ExportFormat.markdown]!);
        expect(
          extra.visitedEntries,
          lessThanOrEqualTo(
            JsonValueNormalizer.defaultMaxCollectionItems *
                ExportFormat.values.length,
          ),
        );
      },
    );

    test('replaces oversized metadata before active redaction', () {
      const secret = 'OVERSIZED_METADATA_SECRET';
      final oversized = '$secret${''.padRight(
        LogExportOutput.maxPreparedValueBytes * 2,
        'x',
      )}';

      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: ISpectMetadata(
          extra: {'diagnostic-note': oversized},
        ),
      );

      expect(jsonDecode(content), isA<Map<String, dynamic>>());
      expect(content, isNot(contains(secret)));
      expect(content, contains(LogExportOutput.truncatedMarker));
      _expectWithinSingleRecordLimit(content);
    });

    test('keeps explicit opt-out content visible but bounded', () {
      const visiblePrefix = 'OPT_OUT_METADATA_PREFIX';
      final oversized = '$visiblePrefix${''.padRight(
        LogExportOutput.maxRecordBytes * 2,
        'x',
      )}';

      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: ISpectMetadata(
          extra: {'diagnostic-note': oversized},
        ),
        enableRedaction: false,
      );

      expect(jsonDecode(content), isA<Map<String, dynamic>>());
      expect(content, contains(visiblePrefix));
      _expectWithinSingleRecordLimit(content);
    });

    test('CSV never invokes raw hostile diagnostic conversions', () {
      final hostile = _HostileDiagnostic();

      final content = ISpectShareLogBottomSheet.buildContent(
        data: {'diagnostic': hostile},
        truncatedData: {'diagnostic': hostile},
        format: ExportFormat.csv,
        action: ExportAction.share,
        enableRedaction: false,
      );

      expect(hostile.toJsonCalls, 0);
      expect(hostile.toStringCalls, 0);
      expect(content, isNot(contains('toJson must not execute')));
      expect(content, isNot(contains('toString must not execute')));
      expect(_parseCsv(content).every((row) => row.length == 2), isTrue);
      _expectWithinSingleRecordLimit(content);
    });

    test('uses a Markdown fence that hostile content cannot close', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: const {
          'message': '`````` injected fence',
        },
        truncatedData: const {
          'message': '`````` injected fence',
        },
        format: ExportFormat.markdown,
        action: ExportAction.share,
        enableRedaction: false,
      );

      _expectClosedMarkdownFence(content);
      final openingFence = content.split('\n')[2].replaceFirst('json', '');
      expect(openingFence.length, greaterThan(6));
      _expectWithinSingleRecordLimit(content);
    });
  });
}

void _expectWithinSingleRecordLimit(String content) {
  final bytes = LogExportOutput.utf8Length(content);
  expect(bytes, lessThanOrEqualTo(LogExportOutput.maxRecordBytes));
  expect(bytes, lessThanOrEqualTo(LogExportOutput.maxDocumentBytes));
}

void _expectClosedMarkdownFence(String content) {
  final lines = content.split('\n');
  expect(lines, hasLength(greaterThanOrEqualTo(5)));
  final opening = lines[2];
  expect(opening, endsWith('json'));
  final fence = opening.substring(0, opening.length - 4);
  expect(fence.length, greaterThanOrEqualTo(3));
  expect(fence.codeUnits.every((unit) => unit == 0x60), isTrue);
  expect(lines[lines.length - 2], fence);
}

List<List<String>> _parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < input.length; index++) {
    final character = input[index];
    if (inQuotes) {
      if (character == '"' &&
          index + 1 < input.length &&
          input[index + 1] == '"') {
        field.write('"');
        index++;
      } else if (character == '"') {
        inQuotes = false;
      } else {
        field.write(character);
      }
      continue;
    }

    if (character == '"') {
      inQuotes = true;
    } else if (character == ',') {
      row.add(field.toString());
      field.clear();
    } else if (character == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(character);
    }
  }

  if (inQuotes) throw const FormatException('Unclosed CSV field');
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
