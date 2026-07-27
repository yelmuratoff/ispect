import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';

void main() {
  group('JsonInputPreflight', () {
    test('accepts reasonable JSON and ignores delimiters inside strings', () {
      const source = '{"message":"[{nested:true}]","items":[1,2]}';

      expect(
        JsonInputPreflight.decode(source),
        isA<Map<String, dynamic>>(),
      );
    });

    test('rejects encoded bytes independently of character count', () {
      expect(
        () => JsonInputPreflight.validate(
          '["界界"]',
          characterLimit: 10,
          encodedByteLimit: 9,
        ),
        throwsA(isA<JsonInputLimitException>()),
      );
    });

    test('rejects lexical nesting before decoding', () {
      const source = '[[[[0]]]]';

      expect(
        () => JsonInputPreflight.decode(source, nestingDepthLimit: 3),
        throwsA(isA<JsonInputLimitException>()),
      );
    });

    test('rejects wide structures before decoding', () {
      const source = '[0,0,0]';

      expect(
        () => JsonInputPreflight.decode(source, approximateNodeLimit: 4),
        throwsA(isA<JsonInputLimitException>()),
      );
    });

    test('omits malformed source content from parser exceptions', () {
      const secret = 'MALFORMED-IMPORT-SECRET';

      try {
        JsonInputPreflight.decode('{"token":"$secret",}');
        fail('Expected malformed JSON to throw.');
      } on FormatException catch (error) {
        expect(error.message, JsonInputPreflight.invalidContent);
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains(secret)));
      }
    });

    test('rejects cyclic decoded containers iteratively', () {
      final cyclic = <Object?>[];
      cyclic.add(cyclic);

      expect(
        () => JsonInputPreflight.validateDecoded(cyclic),
        throwsA(isA<JsonInputLimitException>()),
      );
    });

    test('snapshots without retaining caller containers or hostile leaves', () {
      final hostile = _HostileLeaf();
      final nested = <String, Object?>{
        'name': 'before',
        'hostile': hostile,
      };
      final source = <String, Object?>{'nested': nested};

      final snapshot = JsonInputPreflight.snapshotForViewer(source);
      final captured = snapshot.value! as Map<String, dynamic>;
      final capturedNested = captured['nested']! as Map<String, dynamic>;

      nested['name'] = 'after';
      nested['added'] = true;
      source.clear();

      expect(captured, isNot(same(source)));
      expect(capturedNested, isNot(same(nested)));
      expect(capturedNested['name'], 'before');
      expect(capturedNested, isNot(contains('added')));
      expect(capturedNested['hostile'], isA<String>());
      expect(capturedNested['hostile'], isNot(same(hostile)));
      expect(hostile.toStringCalls, 0);
      expect(hostile.toJsonCalls, 0);
      expect(() => captured['new'] = true, throwsUnsupportedError);
      expect(() => capturedNested['new'] = true, throwsUnsupportedError);
    });

    test('replaces sensitive Records without formatting their fields', () {
      const secret = 'RECORD-SECRET-MUST-NOT-BE-RETAINED';
      final source = <String, Object?>{
        'record': (
          password: secret,
          payload: 'x' * (2 * JsonInputPreflight.maxViewerEncodedBytes),
        ),
      };

      final snapshot = JsonInputPreflight.snapshotForViewer(source);
      final captured = snapshot.value! as Map<String, dynamic>;
      final encoded = jsonEncode(captured);

      expect(
        captured['record'],
        JsonInputPreflight.unprintableValue,
      );
      expect(encoded, isNot(contains(secret)));
      expect(
        utf8.encode(encoded).length,
        lessThan(JsonInputPreflight.maxViewerEncodedBytes),
      );
    });

    test('catches a hostile custom Map iterator after bounded access', () {
      final source = _PartiallyHostileMap();

      final snapshot = JsonInputPreflight.snapshotForViewer(source);
      final captured = snapshot.value! as Map<String, dynamic>;

      expect(captured['safe'], 'retained');
      expect(
        captured[JsonInputPreflight.traversalMarkerKey],
        JsonInputPreflight.unprintableValue,
      );
      expect(source.entriesReads, 1);
      expect(source.moveNextCalls, 2);
    });

    test('preserves cycle and depth diagnostics in the safe graph', () {
      final cyclic = <Object?>[];
      cyclic.add(cyclic);

      final cycleSnapshot =
          JsonInputPreflight.snapshotForViewer(cyclic).value! as List<dynamic>;
      expect(cycleSnapshot.single, JsonInputPreflight.circularReference);

      Object? nested = 'leaf';
      for (var index = 0; index < 6; index++) {
        nested = <Object?>[nested];
      }
      final depthSnapshot = JsonInputPreflight.snapshotForViewer(
        nested,
        nestingDepthLimit: 3,
      );

      expect(
        jsonEncode(depthSnapshot.value),
        contains(JsonInputPreflight.maxDepthReached),
      );
    });

    test('does not let caller keys suppress a traversal diagnostic', () {
      final source = <Object?, Object?>{
        JsonInputPreflight.traversalMarkerKey: 'caller-value',
        7: 'invalid-key-value',
      };

      final captured = JsonInputPreflight.snapshotForViewer(source).value!
          as Map<String, dynamic>;

      expect(
        captured[JsonInputPreflight.traversalMarkerKey],
        'caller-value',
      );
      expect(
        captured['${JsonInputPreflight.traversalMarkerKey}-1'],
        JsonInputPreflight.invalidObjectKey,
      );
    });

    test('enforces one aggregate encoded-byte budget across huge strings', () {
      const byteLimit = 4096;
      final source = <String, Object?>{
        'first': 'a' * byteLimit,
        'second': 'b' * byteLimit,
        'third': '界' * byteLimit,
      };

      final snapshot = JsonInputPreflight.snapshotForViewer(
        source,
        encodedByteLimit: byteLimit,
      );
      final encoded = utf8.encode(jsonEncode(snapshot.value));

      expect(encoded.length, lessThanOrEqualTo(byteLimit));
      expect(
        utf8.decode(encoded),
        anyOf(
          contains(JsonInputPreflight.truncatedValue),
          contains(JsonInputPreflight.rejectedContent),
        ),
      );
    });

    test('counts unpaired UTF-16 surrogates as JSON escapes', () {
      const byteLimit = 4096;
      final source = <String, Object?>{
        'value': String.fromCharCodes(
          List<int>.filled(byteLimit, 0xd800),
        ),
      };

      final snapshot = JsonInputPreflight.snapshotForViewer(
        source,
        encodedByteLimit: byteLimit,
      );
      final encoded = utf8.encode(jsonEncode(snapshot.value));

      expect(encoded.length, lessThanOrEqualTo(byteLimit));
      expect(
        utf8.decode(encoded),
        contains(JsonInputPreflight.truncatedValue),
      );
    });

    test('fails closed when a map or list exactly exhausts the byte budget',
        () {
      const byteLimit = 128;
      final mapSnapshot = JsonInputPreflight.snapshotForViewer(
        <String, Object?>{
          'a': 'x' * (byteLimit - 8),
          'securityRelevantTrailing': true,
        },
        encodedByteLimit: byteLimit,
      );
      final listSnapshot = JsonInputPreflight.snapshotForViewer(
        <Object?>[
          'x' * (byteLimit - 4),
          true,
        ],
        encodedByteLimit: byteLimit,
      );

      expect(mapSnapshot.value, JsonInputPreflight.rejectedContent);
      expect(listSnapshot.value, JsonInputPreflight.rejectedContent);
      expect(
        utf8.encode(jsonEncode(mapSnapshot.value)).length,
        lessThanOrEqualTo(byteLimit),
      );
      expect(
        utf8.encode(jsonEncode(listSnapshot.value)).length,
        lessThanOrEqualTo(byteLimit),
      );
    });

    test('bounds diagnostics for many invalid object keys', () {
      const nodeLimit = 4000;
      final source = <Object?, Object?>{
        for (var index = 0; index < nodeLimit - 2; index++)
          index: 'invalid-key-value',
      };

      final snapshot = JsonInputPreflight.snapshotForViewer(
        source,
        nodeLimit: nodeLimit,
      );
      final captured = snapshot.value! as Map<String, dynamic>;

      expect(captured.length + 1, lessThanOrEqualTo(nodeLimit));
      expect(captured, hasLength(nodeLimit - 2));
      expect(
        captured.values,
        everyElement(JsonInputPreflight.invalidObjectKey),
      );
      expect(
        jsonEncode(captured),
        contains(JsonInputPreflight.invalidObjectKey),
      );
    });

    test('fails closed when hostile traversal starts at the node limit', () {
      const nodeLimit = 4;
      final hostileMap = _CapacityThenThrowMap(nodeLimit - 1);
      final hostileIterable = _CapacityThenThrowIterable(nodeLimit - 1);

      final mapSnapshot = JsonInputPreflight.snapshotForViewer(
        hostileMap,
        nodeLimit: nodeLimit,
      );
      final iterableSnapshot = JsonInputPreflight.snapshotForViewer(
        hostileIterable,
        nodeLimit: nodeLimit,
      );

      expect(mapSnapshot.value, JsonInputPreflight.rejectedContent);
      expect(iterableSnapshot.value, JsonInputPreflight.rejectedContent);
      expect(hostileMap.moveNextCalls, nodeLimit);
      expect(hostileIterable.moveNextCalls, nodeLimit);
    });

    test('bounds traversal of an infinite custom Map', () {
      const nodeLimit = 8;
      final source = _InfiniteMap();

      final snapshot = JsonInputPreflight.snapshotForViewer(
        source,
        nodeLimit: nodeLimit,
      );
      final captured = snapshot.value! as Map<String, dynamic>;

      expect(source.moveNextCalls, lessThanOrEqualTo(nodeLimit));
      expect(captured.length + 1, lessThanOrEqualTo(nodeLimit));
      expect(
        jsonEncode(captured),
        contains(JsonInputPreflight.maxNodesReached),
      );
    });
  });
}

final class _HostileLeaf {
  int toStringCalls = 0;
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('viewer snapshots must not invoke toJson');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('viewer snapshots must not invoke toString');
  }
}

final class _PartiallyHostileMap extends MapBase<String, Object?> {
  int entriesReads = 0;
  int moveNextCalls = 0;

  @override
  Iterable<MapEntry<String, Object?>> get entries {
    entriesReads++;
    return _PartiallyHostileEntries(this);
  }

  @override
  Object? operator [](Object? key) =>
      throw StateError('operator[] must not be used');

  @override
  void operator []=(String key, Object? value) =>
      throw StateError('operator[]= must not be used');

  @override
  void clear() => throw StateError('clear must not be used');

  @override
  Iterable<String> get keys => throw StateError('keys must not be used');

  @override
  Object? remove(Object? key) => throw StateError('remove must not be used');
}

final class _PartiallyHostileEntries
    extends IterableBase<MapEntry<String, Object?>> {
  _PartiallyHostileEntries(this.owner);

  final _PartiallyHostileMap owner;

  @override
  Iterator<MapEntry<String, Object?>> get iterator =>
      _PartiallyHostileIterator(owner);
}

final class _PartiallyHostileIterator
    implements Iterator<MapEntry<String, Object?>> {
  _PartiallyHostileIterator(this.owner);

  final _PartiallyHostileMap owner;
  var _index = 0;

  @override
  MapEntry<String, Object?> get current =>
      const MapEntry<String, Object?>('safe', 'retained');

  @override
  bool moveNext() {
    owner.moveNextCalls++;
    if (_index++ == 0) return true;
    throw StateError('hostile iterator failure');
  }
}

final class _InfiniteMap extends MapBase<String, Object?> {
  int moveNextCalls = 0;

  @override
  Iterable<MapEntry<String, Object?>> get entries => _InfiniteEntries(this);

  @override
  Object? operator [](Object? key) =>
      throw StateError('operator[] must not be used');

  @override
  void operator []=(String key, Object? value) =>
      throw StateError('operator[]= must not be used');

  @override
  void clear() => throw StateError('clear must not be used');

  @override
  Iterable<String> get keys => throw StateError('keys must not be used');

  @override
  Object? remove(Object? key) => throw StateError('remove must not be used');
}

final class _InfiniteEntries extends IterableBase<MapEntry<String, Object?>> {
  _InfiniteEntries(this.owner);

  final _InfiniteMap owner;

  @override
  Iterator<MapEntry<String, Object?>> get iterator => _InfiniteIterator(owner);
}

final class _InfiniteIterator implements Iterator<MapEntry<String, Object?>> {
  _InfiniteIterator(this.owner);

  final _InfiniteMap owner;
  var _index = 0;

  @override
  MapEntry<String, Object?> get current =>
      MapEntry<String, Object?>('key-${_index - 1}', _index);

  @override
  bool moveNext() {
    owner.moveNextCalls++;
    _index++;
    return true;
  }
}

final class _CapacityThenThrowMap extends MapBase<String, Object?> {
  _CapacityThenThrowMap(this.safeValueCount);

  final int safeValueCount;
  int moveNextCalls = 0;

  @override
  Iterable<MapEntry<String, Object?>> get entries =>
      _CapacityThenThrowEntries(this);

  @override
  Object? operator [](Object? key) =>
      throw StateError('operator[] must not be used');

  @override
  void operator []=(String key, Object? value) =>
      throw StateError('operator[]= must not be used');

  @override
  void clear() => throw StateError('clear must not be used');

  @override
  Iterable<String> get keys => throw StateError('keys must not be used');

  @override
  Object? remove(Object? key) => throw StateError('remove must not be used');
}

final class _CapacityThenThrowEntries
    extends IterableBase<MapEntry<String, Object?>> {
  _CapacityThenThrowEntries(this.owner);

  final _CapacityThenThrowMap owner;

  @override
  Iterator<MapEntry<String, Object?>> get iterator =>
      _CapacityThenThrowMapIterator(owner);
}

final class _CapacityThenThrowMapIterator
    implements Iterator<MapEntry<String, Object?>> {
  _CapacityThenThrowMapIterator(this.owner);

  final _CapacityThenThrowMap owner;
  var _index = 0;

  @override
  MapEntry<String, Object?> get current =>
      MapEntry<String, Object?>('key-${_index - 1}', null);

  @override
  bool moveNext() {
    owner.moveNextCalls++;
    if (_index < owner.safeValueCount) {
      _index++;
      return true;
    }
    throw StateError('hostile iterator failure at capacity');
  }
}

final class _CapacityThenThrowIterable extends IterableBase<Object?> {
  _CapacityThenThrowIterable(this.safeValueCount);

  final int safeValueCount;
  int moveNextCalls = 0;

  @override
  Iterator<Object?> get iterator => _CapacityThenThrowIterableIterator(this);
}

final class _CapacityThenThrowIterableIterator implements Iterator<Object?> {
  _CapacityThenThrowIterableIterator(this.owner);

  final _CapacityThenThrowIterable owner;
  var _index = 0;

  @override
  Object? get current => null;

  @override
  bool moveNext() {
    owner.moveNextCalls++;
    if (_index < owner.safeValueCount) {
      _index++;
      return true;
    }
    throw StateError('hostile iterator failure at capacity');
  }
}
