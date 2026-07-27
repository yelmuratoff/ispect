import 'dart:collection';
import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _HostileLeaf {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('REPLAY_LEAF_JSON_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('REPLAY_LEAF_TEXT_SECRET');
  }
}

final class _HostileException implements Exception {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('REPLAY_ERROR_SECRET');
  }
}

final class _ThrowingMap<K, V> extends MapBase<K, V> {
  int keysCalls = 0;

  @override
  Iterable<K> get keys {
    keysCalls++;
    throw StateError('REPLAY_MAP_SECRET');
  }

  @override
  V? operator [](Object? key) => null;

  @override
  void operator []=(K key, V value) {}

  @override
  void clear() {}

  @override
  V? remove(Object? key) => null;
}

void main() {
  setUp(ISpectRedaction.reset);
  tearDown(ISpectRedaction.reset);

  group('NetworkReplayResult.safeSnapshot', () {
    test('detaches safe response data and redacts sensitive values', () {
      final headers = <String, String>{
        'authorization': 'Bearer replay-secret',
        'x-request-id': 'req-1',
      };
      final body = <String, Object?>{
        'password': 'replay-secret',
        'items': <Object?>[1, true, 'safe'],
      };

      final snapshot = NetworkReplayResult(
        statusCode: 200,
        headers: headers,
        body: body,
        durationMs: 12,
        error: 'token=replay-secret',
      ).safeSnapshot();

      expect(snapshot.headers, isNot(same(headers)));
      expect(snapshot.body, isNot(same(body)));
      expect(snapshot.headers['authorization'], contains(defaultPlaceholder));
      expect(
        snapshot.headers['authorization'],
        isNot(contains('replay-secret')),
      );
      expect(snapshot.headers['x-request-id'], 'req-1');
      expect(
        (snapshot.body! as Map<String, Object?>)['password'],
        defaultPlaceholder,
      );
      expect(
        (snapshot.body! as Map<String, Object?>)['items'],
        <Object?>[1, true, 'safe'],
      );
      expect(snapshot.error, isNot(contains('replay-secret')));
      expect(
        () => snapshot.headers['later'] = 'mutation',
        throwsUnsupportedError,
      );
    });

    test('uses the configured global service by default', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'business_marker'},
          placeholder: '<GLOBAL_POLICY>',
        ),
      );

      final snapshot = const NetworkReplayResult(
        body: {'business_marker': 'replay-secret'},
      ).safeSnapshot();

      expect(snapshot.body.toString(), isNot(contains('replay-secret')));
      expect(snapshot.body.toString(), contains('<GLOBAL_POLICY>'));
    });

    test('never executes hostile leaves, maps, or errors', () {
      final leaf = _HostileLeaf();
      final bodyMap = _ThrowingMap<Object?, Object?>();
      final headers = _ThrowingMap<String, String>();
      final error = _HostileException();

      final snapshot = NetworkReplayResult(
        headers: headers,
        body: <String, Object?>{
          'leaf': leaf,
          'hostile-map': bodyMap,
        },
        error: error,
      ).safeSnapshot();
      final encoded = jsonEncode(<String, Object?>{
        'headers': snapshot.headers,
        'body': snapshot.body,
        'error': snapshot.error,
      });

      expect(leaf.toJsonCalls, 0);
      expect(leaf.toStringCalls, 0);
      expect(bodyMap.keysCalls, 1);
      expect(headers.keysCalls, 1);
      expect(error.toStringCalls, 0);
      expect(encoded, isNot(contains('REPLAY_')));
      expect(
        encoded,
        anyOf(
          contains(JsonValueNormalizer.unprintableValue),
          contains(defaultPlaceholder),
        ),
      );
    });

    test('bounds multi-megabyte aggregates with redaction disabled', () {
      ISpectRedaction.enabled = false;
      final chunk = List<String>.filled(2048, 'x').join();
      final aggregate = List<String>.filled(2048, chunk);

      final snapshot = NetworkReplayResult(
        statusCode: 200,
        headers: <String, String>{'x-large': chunk},
        body: aggregate,
        error: chunk,
      ).safeSnapshot();
      final encoded = jsonEncode(<String, Object?>{
        'headers': snapshot.headers,
        'body': snapshot.body,
        'error': snapshot.error,
      });

      expect(
        LogExportOutput.utf8Length(encoded),
        lessThan(128 * 1024),
      );
      expect(encoded, contains(LogExportOutput.truncatedMarker));
      expect(snapshot.body, isNot(same(aggregate)));
    });
  });
}
