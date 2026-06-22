import 'dart:typed_data';

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

class _ProfileBody {
  const _ProfileBody(this.email);

  final String? email;

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};

  @override
  String toString() => '_ProfileBody($email)';
}

class _AuthBody {
  const _AuthBody(this.provider, this.profile);

  final String provider;
  final _ProfileBody profile;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'provider': provider,
        'profile': profile,
      };
}

class _EnumLikeBody {
  String toJson() => 'APPLE';
}

class _SelfReferencingBody {
  Map<String, dynamic> toJson() => <String, dynamic>{'self': this};
}

class _IdentityBody {
  Object toJson() => this;
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

    test('preserves identity for nested pure-JSON structures', () {
      final map = <String, dynamic>{
        'outer': <String, dynamic>{
          'inner': <Object?>[
            1,
            'two',
            null,
            <String, dynamic>{'deep': true},
          ],
        },
      };
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(map), same(map));
    });

    test('renders a DTO nested inside a map without mutating the original', () {
      final original = <String, dynamic>{
        'provider': 'APPLE',
        'profile': const _ProfileBody('a@b.c'),
      };

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(original);

      expect(encoded, <String, dynamic>{
        'provider': 'APPLE',
        'profile': <String, dynamic>{'email': 'a@b.c'},
      });
      expect(original['profile'], isA<_ProfileBody>());
    });

    test('recurses into the map produced by a top-level DTO toJson', () {
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        const _AuthBody('APPLE', _ProfileBody(null)),
      );

      expect(encoded, <String, dynamic>{
        'provider': 'APPLE',
        'profile': <String, dynamic>{'email': null},
      });
    });

    test('renders DTOs inside lists and deeply nested structures', () {
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(<Object?>[
        const _TypedBody('A'),
        <String, dynamic>{
          'items': <Object?>[
            const _TypedBody('B'),
            'plain',
          ],
        },
      ]);

      expect(encoded, <Object?>[
        <String, dynamic>{'referralCode': 'A'},
        <String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{'referralCode': 'B'},
            'plain',
          ],
        },
      ]);
    });

    test('keeps non-encodable values as-is inside a rebuilt structure', () {
      final opaque = _OpaqueBody();
      final throwing = _ThrowingBody();
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        <String, dynamic>{
          'opaque': opaque,
          'throwing': throwing,
          'typed': const _TypedBody('X'),
        },
      );

      expect(encoded, <String, dynamic>{
        'opaque': same(opaque),
        'throwing': same(throwing),
        'typed': <String, dynamic>{'referralCode': 'X'},
      });
    });

    test('supports toJson returning a non-map value', () {
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        <String, dynamic>{'provider': _EnumLikeBody()},
      );
      expect(encoded, <String, dynamic>{'provider': 'APPLE'});
    });

    test('stringifies non-string keys when rebuilding a map', () {
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        <Object, Object?>{1: const _TypedBody('X')},
      );
      expect(encoded, <String, dynamic>{
        '1': <String, dynamic>{'referralCode': 'X'},
      });
    });

    test('passes TypedData through without copying', () {
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(bytes),
        same(bytes),
      );

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        <String, dynamic>{'file': bytes, 'meta': const _TypedBody('X')},
      ) as Map<String, dynamic>?;
      expect(encoded?['file'], same(bytes));
    });

    test('survives a cyclic map without infinite recursion', () {
      final cyclic = <String, dynamic>{'dto': const _TypedBody('X')};
      cyclic['self'] = cyclic;

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(cyclic)!
          as Map<String, dynamic>;

      expect(encoded['dto'], <String, dynamic>{'referralCode': 'X'});
      expect(encoded['self'], same(cyclic));
    });

    test('survives a DTO whose toJson references itself', () {
      final body = _SelfReferencingBody();
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(body)!
          as Map<String, dynamic>;
      expect(encoded['self'], same(body));
    });

    test('returns the same instance when toJson returns the object itself', () {
      final body = _IdentityBody();
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(body),
        same(body),
      );
    });

    test('leaves values beyond the depth cap as-is', () {
      Object nested = const _TypedBody('deep');
      for (var i = 0; i < 80; i++) {
        nested = <String, dynamic>{'level': nested};
      }

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(nested);
      expect(encoded, same(nested));
    });
  });
}
