import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_logs_viewer/src/core/utils/file_read_tracker.dart';
import 'package:web_logs_viewer/src/core/utils/file_stream_processor.dart';

void main() {
  group('FileReadTracker', () {
    late FileReadTracker tracker;
    late StreamController<Uint8List> source;
    late List<String> contents;
    late List<Object> errors;

    setUp(() {
      tracker = FileReadTracker();
      source = StreamController<Uint8List>();
      contents = <String>[];
      errors = <Object>[];
    });

    tearDown(() => unawaited(source.close()));

    void startRead() => tracker.read(
      _StreamFile(source.stream),
      onSuccess: contents.add,
      onError: errors.add,
    );

    test('a read that finishes after cancelAll reports nothing', () async {
      startRead();
      source.add(Uint8List.fromList(utf8.encode('{"cleared": true}')));
      await pumpEventQueue();

      await tracker.cancelAll();
      unawaited(source.close());
      await pumpEventQueue();

      expect(contents, isEmpty);
      expect(errors, isEmpty);
      expect(tracker.activeReads, 0);
    });

    test('cancelAll starts a new generation', () async {
      final before = tracker.generation;

      await tracker.cancelAll();

      expect(tracker.isCurrent(before), isFalse);
      expect(tracker.isCurrent(tracker.generation), isTrue);
    });

    test('a finished read is pruned from the active reads', () async {
      startRead();
      expect(tracker.activeReads, 1);

      source.add(Uint8List.fromList(utf8.encode('done')));
      await source.close();
      await pumpEventQueue();

      expect(contents, ['done']);
      expect(tracker.activeReads, 0);
    });

    test('a failed read is pruned from the active reads', () async {
      startRead();

      source.addError(StateError('read failed'));
      await pumpEventQueue();

      expect(errors.single, isA<StateError>());
      expect(tracker.activeReads, 0);
    });

    test('routes an asynchronous onSuccess failure to onError', () async {
      tracker.read(
        _StreamFile(source.stream),
        onSuccess: (_) async {
          await Future<void>.value();
          throw StateError('inspection failed');
        },
        onError: errors.add,
      );

      source.add(Uint8List.fromList(utf8.encode('{"value": 1}')));
      await source.close();
      await pumpEventQueue();

      expect(errors.single, isA<StateError>());
      expect(tracker.activeReads, 0);
    });

    test('routes a synchronous onSuccess failure to onError', () async {
      tracker.read(
        _StreamFile(source.stream),
        onSuccess: (_) => throw StateError('inspection failed'),
        onError: errors.add,
      );

      source.add(Uint8List.fromList(utf8.encode('{"value": 1}')));
      await source.close();
      await pumpEventQueue();

      expect(errors.single, isA<StateError>());
    });

    test('rejects a file above the shared size cap by default', () async {
      final megabyte = Uint8List(1024 * 1024);
      final chunks = maxLoadableFileSize ~/ megabyte.length + 1;
      final result = Completer<Object>();

      tracker.read(
        _StreamFile(
          Stream<Uint8List>.fromIterable(
            List<Uint8List>.filled(chunks, megabyte),
          ),
        ),
        onSuccess: (_) => result.completeError(
          StateError('Expected the shared cap to reject the file'),
        ),
        onError: result.complete,
      );

      expect(
        await result.future,
        isA<FileSizeLimitException>().having(
          (error) => error.maxFileSize,
          'maxFileSize',
          maxLoadableFileSize,
        ),
      );
    });
  });
}

final class _StreamFile {
  const _StreamFile(this.stream);

  final Stream<Uint8List> stream;

  Stream<Uint8List> getStream() => stream;
}
