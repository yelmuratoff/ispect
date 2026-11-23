import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_devtools_extension/src/vm_log_source.dart';

Map<String, Object?> _entry(String message) => {
  'id': message,
  'log': {'message': message, 'time': '2026-03-02T09:00:00.000'},
};

Map<String, Object?> _page(
  List<String> messages, {
  String? cursor,
  bool hasMore = false,
}) => {
  'logs': [for (final message in messages) _entry(message)],
  'hasMore': hasMore,
  'cursor': ?cursor,
};

const _currentSummary = {'protocolVersion': 2};

void main() {
  group('ISpectVmLogSource', () {
    late ISpectLogger sink;
    late List<Map<String, String>> logCalls;

    setUp(() {
      sink = ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));
      logCalls = [];
    });
    tearDown(() => sink.dispose());

    ISpectVmLogSource sourceAnswering(
      List<FutureOr<Map<String, Object?>> Function()> pages, {
      Map<String, Object?> summary = _currentSummary,
    }) {
      final queue = [...pages];
      return ISpectVmLogSource(
        sink: sink,
        call: (method, args) async {
          if (method == ISpectServiceExtensions.getSummary) return summary;
          logCalls.add(args);
          return queue.removeAt(0)();
        },
      );
    }

    List<String?> messages() => sink.history.map((l) => l.message).toList();

    test('the first poll copies the newest page and goes live', () async {
      final source = sourceAnswering([
        () => _page(['a', 'b'], cursor: 'b', hasMore: true),
      ]);
      addTearDown(source.dispose);

      await source.poll();

      expect(messages(), ['a', 'b']);
      expect(logCalls.single, {'detail': 'full', 'limit': '200'});
      expect(source.status.value, ISpectVmLogStatus.live);
    });

    test('later polls page forward until the app has nothing newer', () async {
      final source = sourceAnswering([
        () => _page(['a'], cursor: 'a'),
        () => _page(['b'], cursor: 'b', hasMore: true),
        () => _page(['c'], cursor: 'c'),
      ]);
      addTearDown(source.dispose);

      await source.poll();
      await source.poll();

      expect(messages(), ['a', 'b', 'c']);
      expect(logCalls.map((c) => c['afterId']), [null, 'a', 'b']);
    });

    test(
      'an app on an older ISpect protocol is reported, not polled',
      () async {
        final source = sourceAnswering(
          const [],
          summary: const {'protocolVersion': 1},
        );
        addTearDown(source.dispose);

        await source.poll();

        expect(source.status.value, ISpectVmLogStatus.outdated);
        expect(logCalls, isEmpty);
      },
    );

    test(
      'an expired cursor clears the copy and the next poll refills it',
      () async {
        final source = sourceAnswering([
          () => _page(['old'], cursor: 'old'),
          () => throw const ISpectCursorExpired(),
          () => _page(['fresh'], cursor: 'fresh'),
        ]);
        addTearDown(source.dispose);

        await source.poll();
        await source.poll();
        expect(messages(), isEmpty);
        expect(source.status.value, ISpectVmLogStatus.live);

        await source.poll();
        expect(messages(), ['fresh']);
        expect(logCalls.last.containsKey('afterId'), isFalse);
      },
    );

    test('an app without ISpect extensions reports it', () async {
      final source = ISpectVmLogSource(
        sink: sink,
        call: (_, _) async => throw const ISpectExtensionMissing(),
      );
      addTearDown(source.dispose);

      await source.poll();

      expect(source.status.value, ISpectVmLogStatus.notEnabled);
      expect(messages(), isEmpty);
    });

    test(
      'a failed call marks the app unreachable instead of throwing',
      () async {
        final source = sourceAnswering([
          () => _page(['a'], cursor: 'a'),
          () => throw Exception('connection lost'),
        ]);
        addTearDown(source.dispose);

        await source.poll();
        await expectLater(source.poll(), completes);

        expect(source.status.value, ISpectVmLogStatus.unreachable);
        expect(messages(), ['a']);
      },
    );

    test(
      'an unreadable record is skipped without stalling the cursor',
      () async {
        final source = sourceAnswering([
          () => {
            'logs': [
              _entry('a'),
              {'id': 'broken', 'log': <String, dynamic>{}},
              _entry('c'),
            ],
            'hasMore': false,
            'cursor': 'c',
          },
          () => _page(['d'], cursor: 'd'),
        ]);
        addTearDown(source.dispose);

        await source.poll();
        await source.poll();

        expect(messages(), ['a', 'c', 'd']);
        expect(logCalls.last['afterId'], 'c');
      },
    );

    test('a poll that starts while one runs does not fetch again', () async {
      final pending = Completer<Map<String, Object?>>();
      final source = sourceAnswering([() => pending.future]);
      addTearDown(source.dispose);

      final first = source.poll();
      await source.poll();
      pending.complete(_page(['a'], cursor: 'a'));
      await first;

      expect(logCalls, hasLength(1));
      expect(messages(), ['a']);
    });

    test('disposing during a poll leaves the status alone', () async {
      final pending = Completer<Map<String, Object?>>();
      final source = sourceAnswering([() => pending.future]);

      final polling = source.poll();
      await Future<void>.delayed(Duration.zero);
      source.dispose();
      pending.complete(_page(['a'], cursor: 'a'));

      await expectLater(polling, completes);
    });
  });
}
