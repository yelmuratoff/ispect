import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_logs_viewer/src/core/utils/file_stream_processor.dart';

void main() {
  group('combineChunks', () {
    test('preserves byte order across chunks', () {
      final combined = combineChunks(<Uint8List>[
        Uint8List.fromList(<int>[1, 2]),
        Uint8List.fromList(<int>[3]),
        Uint8List.fromList(<int>[4, 5]),
      ]);

      expect(combined, <int>[1, 2, 3, 4, 5]);
    });

    test('returns an empty buffer for no chunks', () {
      expect(combineChunks(const <Uint8List>[]), isEmpty);
    });
  });

  group('processFileStream', () {
    test('decodes UTF-8 split across chunks', () async {
      final result = Completer<String>();
      final bytes = utf8.encode('Привет');
      final file = _StreamFile(
        Stream<Uint8List>.fromIterable(<Uint8List>[
          Uint8List.fromList(bytes.take(4).toList()),
          Uint8List.fromList(bytes.skip(4).toList()),
        ]),
      );

      processFileStream(
        file,
        onSuccess: result.complete,
        onError: result.completeError,
      );

      expect(await result.future, 'Привет');
    });

    test('reports malformed UTF-8', () async {
      final result = Completer<Object>();
      final file = _StreamFile(
        Stream<Uint8List>.value(Uint8List.fromList(<int>[0xC3, 0x28])),
      );

      processFileStream(
        file,
        onSuccess: (_) =>
            result.completeError(StateError('Expected decoding to fail')),
        onError: result.complete,
      );

      expect(await result.future, isA<FormatException>());
    });

    test('forwards stream errors', () async {
      final result = Completer<Object>();
      final error = StateError('stream failed');
      final file = _StreamFile(Stream<Uint8List>.error(error));

      processFileStream(
        file,
        onSuccess: (_) =>
            result.completeError(StateError('Expected the stream to fail')),
        onError: result.complete,
      );

      expect(await result.future, same(error));
    });

    test('accepts content exactly at the configured size limit', () async {
      final result = Completer<String>();
      final file = _StreamFile(
        Stream<Uint8List>.value(Uint8List.fromList(utf8.encode('1234'))),
      );

      processFileStream(
        file,
        maxFileSize: 4,
        onSuccess: result.complete,
        onError: result.completeError,
      );

      expect(await result.future, '1234');
    });

    test('rejects content above the configured size limit', () async {
      final result = Completer<Object>();
      final file = _StreamFile(
        Stream<Uint8List>.value(Uint8List.fromList(utf8.encode('12345'))),
      );

      processFileStream(
        file,
        maxFileSize: 4,
        onSuccess: (_) => result.completeError(
          StateError('Expected the size limit to reject the file'),
        ),
        onError: result.complete,
      );

      expect(
        await result.future,
        isA<FileSizeLimitException>()
            .having((error) => error.maxFileSize, 'maxFileSize', 4)
            .having((error) => error.actualSize, 'actualSize', 5),
      );
    });
  });
}

final class _StreamFile {
  const _StreamFile(this.stream);

  final Stream<Uint8List> stream;

  Stream<Uint8List> getStream() => stream;
}
