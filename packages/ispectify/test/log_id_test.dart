import 'package:ispectify/src/models/log_id.dart';
import 'package:test/test.dart';

void main() {
  group('LogId.generate', () {
    test('produces 26-character ULID', () {
      final id = LogId.generate();
      expect(id, hasLength(26));
    });

    test('uses Crockford base32 alphabet', () {
      final id = LogId.generate();
      expect(id, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]+$')));
    });

    test('returns different ids on successive calls', () {
      final ids = List.generate(1000, (_) => LogId.generate()).toSet();
      expect(ids, hasLength(1000));
    });

    test('ids share time prefix when generated in the same millisecond', () {
      // Each id keeps a 10-char timestamp prefix and a 16-char random suffix.
      // The randomness must always disambiguate, even when prefixes collide.
      final batch = List.generate(50, (_) => LogId.generate());
      final randoms = batch.map((id) => id.substring(10)).toSet();
      expect(randoms.length, equals(batch.length));
    });

    test('lexicographic order tracks creation time across millisecond windows',
        () async {
      final earlier = LogId.generate();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final later = LogId.generate();
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('timestamp prefix decodes to the current epoch millisecond', () {
      const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      final before = DateTime.now().millisecondsSinceEpoch;
      final id = LogId.generate();
      final after = DateTime.now().millisecondsSinceEpoch;

      var decoded = 0;
      for (final char in id.substring(0, 10).split('')) {
        decoded = decoded * 32 + alphabet.indexOf(char);
      }

      expect(decoded, greaterThanOrEqualTo(before));
      expect(decoded, lessThanOrEqualTo(after));
    });
  });
}
