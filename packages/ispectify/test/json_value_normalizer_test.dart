import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _DiagnosticEvent {
  const _DiagnosticEvent();
}

final class _JsonCredential {
  _JsonCredential(this.secret);

  final String secret;
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    return {'tenantSecret': secret};
  }

  @override
  String toString() => 'Credentials($secret)';
}

final class _ThrowingJsonCredential {
  _ThrowingJsonCredential(this.secret);

  final String secret;
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('encode failed');
  }

  @override
  String toString() => 'Credentials($secret)';
}

final class _ThrowingValue {
  const _ThrowingValue();

  @override
  String toString() => throw StateError('must not escape');
}

final class _ThrowingKey {
  const _ThrowingKey();

  @override
  String toString() => throw StateError('must not escape');
}

final class _HostileStateError implements StateError {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('runtimeType must not be invoked');
  }

  @override
  String get message {
    calls++;
    throw StateError('message must not be invoked');
  }

  @override
  String toString() {
    calls++;
    throw StateError('toString must not be invoked');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('diagnostic member must not be invoked');
  }
}

final class _UnboundedIterable extends Iterable<int> {
  @override
  Iterator<int> get iterator => _UnboundedIterator();
}

final class _UnboundedIterator implements Iterator<int> {
  var _current = -1;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    _current++;
    return true;
  }
}

void main() {
  group('JsonValueNormalizer', () {
    test('preserves structures and replaces unsupported values', () {
      final normalized = JsonValueNormalizer.normalize(
        <Object?, Object?>{
          1: const _DiagnosticEvent(),
          'values': <Object?>[double.nan, double.infinity],
        },
      );

      expect(normalized, {
        '1': JsonValueNormalizer.unprintableValue,
        'values': ['NaN', 'Infinity'],
      });
    });

    test('outbound redaction does not execute DTO toJson', () {
      const secret = 'DTO_STRUCTURED_SECRET';
      final credential = _JsonCredential(secret);
      final normalized = JsonValueNormalizer.normalize(
        credential,
      );
      final redacted = RedactionService(
        sensitiveKeys: const {'tenantSecret'},
      ).redactForExport(credential);

      expect(normalized, JsonValueNormalizer.unprintableValue);
      expect(redacted.toString(), isNot(contains(secret)));
      expect(redacted, JsonValueNormalizer.unprintableValue);
      expect(credential.toJsonCalls, 0);
    });

    test('custom toJson requires an explicit opt-in', () {
      const secret = 'DTO_STRUCTURED_SECRET';
      final credential = _JsonCredential(secret);

      final normalized = JsonValueNormalizer.normalize(
        credential,
        allowCustomSerialization: true,
      );

      expect(normalized, const {'tenantSecret': secret});
      expect(credential.toJsonCalls, 1);
    });

    test('fails closed when DTO toJson throws', () {
      const secret = 'THROWING_DTO_SECRET';
      final credential = _ThrowingJsonCredential(secret);

      final normalized = JsonValueNormalizer.normalize(
        credential,
        allowCustomSerialization: true,
      );

      expect(normalized, JsonValueNormalizer.unprintableValue);
      expect(normalized.toString(), isNot(contains(secret)));
      expect(credential.toJsonCalls, 1);
    });

    test('diagnostic descriptors never invoke virtual members', () {
      final error = _HostileStateError();

      final normalized = JsonValueNormalizer.normalize(error);

      expect(normalized, 'StateError');
      expect(error.calls, 0);
    });

    test('preserves typed binary containers for a redaction pass', () {
      final int8 = Int8List.fromList([-1, 2, 3]);
      final uint16 = Uint16List.fromList([256, 512]);
      final byteData = ByteData(4)..setUint32(0, 0x01020304);
      final buffer = Uint8List.fromList([4, 5, 6]).buffer;

      final normalized = JsonValueNormalizer.normalize(
        {
          'int8': int8,
          'uint16': uint16,
          'byteData': byteData,
          'buffer': buffer,
        },
        preserveTypes: true,
      )! as Map<String, Object?>;

      expect(identical(normalized['int8'], int8), isTrue);
      expect(identical(normalized['uint16'], uint16), isTrue);
      expect(identical(normalized['byteData'], byteData), isTrue);
      expect(identical(normalized['buffer'], buffer), isTrue);
    });

    test('normalizes typed lists when type preservation is disabled', () {
      expect(
        JsonValueNormalizer.normalize(Int8List.fromList([-1, 2, 3])),
        [-1, 2, 3],
      );
      expect(
        JsonValueNormalizer.normalize(Uint16List.fromList([256, 512])),
        [256, 512],
      );
    });

    test('replaces circular references with a stable marker', () {
      final value = <String, Object?>{};
      value['self'] = value;

      expect(JsonValueNormalizer.normalize(value), {
        'self': JsonValueNormalizer.circularReference,
      });
    });

    test('stops traversal at the configured depth', () {
      expect(
        JsonValueNormalizer.normalize(
          {
            'nested': {'value': 1},
          },
          maxDepth: 1,
        ),
        {'nested': JsonValueNormalizer.maxDepthReached},
      );
    });

    test('rejects a non-positive maximum depth', () {
      expect(
        () => JsonValueNormalizer.normalize(const {}, maxDepth: 0),
        throwsRangeError,
      );
    });

    test('fails closed when a value or map key cannot be stringified', () {
      final normalized = JsonValueNormalizer.normalize({
        'value': const _ThrowingValue(),
        const _ThrowingKey(): 'secret-behind-unknown-key',
      })! as Map<String, Object?>;

      expect(
        normalized['value'],
        JsonValueNormalizer.unprintableValue,
      );
      expect(
        normalized['<unprintable-key>'],
        JsonValueNormalizer.unprintableValue,
      );
      expect(
        normalized.toString(),
        isNot(contains('secret-behind-unknown-key')),
      );
    });

    test('bounds lazy unbounded iterables per collection', () {
      final normalized = JsonValueNormalizer.normalize(
        _UnboundedIterable(),
        maxCollectionItems: 3,
      )! as List<Object?>;

      expect(normalized, [
        0,
        1,
        2,
        JsonValueNormalizer.maxCollectionItemsReached,
      ]);
    });

    test('bounds total nodes across nested collections', () {
      final normalized = JsonValueNormalizer.normalize(
        {
          'first': [1, 2, 3],
          'second': [4, 5, 6],
        },
        maxNodes: 4,
      );

      expect(
        normalized.toString(),
        contains(JsonValueNormalizer.maxNodesReached),
      );
    });

    test('rejects non-positive node and collection budgets', () {
      expect(
        () => JsonValueNormalizer.normalize(const {}, maxNodes: 0),
        throwsRangeError,
      );
      expect(
        () => JsonValueNormalizer.normalize(const {}, maxCollectionItems: 0),
        throwsRangeError,
      );
    });
  });
}
