import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _ReturningStrategy implements RedactionStrategy {
  _ReturningStrategy(this._value);
  final Object? _value;

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionRuntime runtime,
    String? keyName,
  }) =>
      _value;
}

class _CountingStrategy implements RedactionStrategy {
  int calls = 0;
  @override
  Object? tryRedact(
    Object? node, {
    required RedactionRuntime runtime,
    String? keyName,
  }) {
    calls++;
    return null;
  }
}

RedactionRuntime _runtime() => RedactionRuntime(
      placeholder: '[REDACTED]',
      redactBinary: true,
      redactBase64: true,
      sensitiveKeysLower: const {},
      sensitiveKeyPatterns: const [],
      fullyMaskedKeyNamesLower: const {},
      isIgnoredValue: (_) => false,
      isIgnoredKey: (_) => false,
      maskString: (v, {keyName}) => 'MASKED(${v.length})',
      binaryPlaceholder: (len) => '[binary $len bytes]',
      base64Placeholder: (len) => '[base64 ~${len}B]',
      redactUint8List: (d) => d,
      looksLikeAuthorizationValue: (_) => false,
      isLikelyBase64: (_) => false,
      isProbablyBinaryString: (_) => false,
    );

void main() {
  group('CompositeRedactionStrategy', () {
    test('returns first non-null redaction', () {
      final composite = CompositeRedactionStrategy([
        _ReturningStrategy(null),
        _ReturningStrategy('HIT'),
      ]);
      final out = composite.tryRedact('value', runtime: _runtime());
      expect(out, 'HIT');
    });

    test('short-circuits subsequent strategies after first hit', () {
      final counter = _CountingStrategy();
      final composite = CompositeRedactionStrategy([
        _ReturningStrategy('FIRST'),
        counter,
      ]);
      final out = composite.tryRedact('value', runtime: _runtime());
      expect(out, 'FIRST');
      expect(counter.calls, 0);
    });
  });
}
