import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _TypedBody {
  const _TypedBody(this.code);

  final String code;

  Map<String, dynamic> toJson() => <String, dynamic>{'referralCode': code};

  @override
  String toString() => '_TypedBody($code)';
}

class _OpaqueBody {
  @override
  String toString() => 'opaque-body';
}

class _ThrowingBody {
  Map<String, dynamic> toJson() => throw StateError('boom');
}

void main() {
  group('NetworkPayloadSanitizer.encodeJsonGracefully', () {
    test('renders a typed body via toJson', () {
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(const _TypedBody('ABC')),
        <String, dynamic>{'referralCode': 'ABC'},
      );
    });

    test('returns the same instance for a body without toJson', () {
      final body = _OpaqueBody();
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(body),
        same(body),
      );
    });

    test('returns the same instance when toJson throws', () {
      final body = _ThrowingBody();
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(body),
        same(body),
      );
    });

    test('passes JSON-native values through unchanged', () {
      const map = <String, dynamic>{'k': 'v'};
      const list = <int>[1, 2, 3];

      expect(NetworkPayloadSanitizer.encodeJsonGracefully(null), isNull);
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(map), same(map));
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(list), same(list));
      expect(NetworkPayloadSanitizer.encodeJsonGracefully('s'), 's');
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(42), 42);
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(true), true);
    });
  });
}
