import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ISpectRedaction.enabled = true);

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

  test('global redaction opt-out deliberately preserves raw values', () {
    ISpectRedaction.enabled = false;
    final codec = FileLogCodec(redactor: RedactionService());

    final encoded = codec.encode(
      ISpectLogData(
        'request',
        id: 'A',
        additionalData: const {'authorization': 'explicit-raw-value'},
      ),
      sessionId: 'SESSION',
      maxBytes: 4096,
    );

    expect(utf8.decode(encoded.bytes), contains('explicit-raw-value'));
  });

  test('converts unsupported nested values to JSON-safe strings', () {
    final codec = FileLogCodec(redactor: RedactionService());
    final instant = DateTime.utc(2026, 7, 10);

    final encoded = codec.encode(
      ISpectLogData(
        'message',
        id: 'A',
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
      {'instant': instant.toString()},
    ]);
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
    final source = ISpectLogData('message', id: 'A');
    final encoded = codec.encode(source, sessionId: 'S', maxBytes: 4096);

    final decoded = codec.decodeLine(utf8.decode(encoded.bytes).trim());

    expect(decoded.id, 'A');
    expect(decoded.additionalData?[TraceKeys.sessionId], 'S');
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
}
