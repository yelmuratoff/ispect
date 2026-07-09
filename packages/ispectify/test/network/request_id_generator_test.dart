import 'dart:math';

import 'package:ispectify/src/network/request_id_generator.dart';
import 'package:test/test.dart';

void main() {
  group('RequestIdGenerator', () {
    test('produces the net-<hex>-<counter> format', () {
      final id = RequestIdGenerator(random: Random(1)).next();
      expect(id, matches(RegExp(r'^net-[0-9a-f]{6}-\d+$')));
    });

    test('counter increments monotonically within a generator', () {
      final gen = RequestIdGenerator(random: Random(1));
      final first = int.parse(gen.next().split('-').last);
      final second = int.parse(gen.next().split('-').last);
      expect(second, first + 1);
    });

    test('a seeded Random yields a deterministic session prefix', () {
      final a = RequestIdGenerator(random: Random(42)).next().split('-')[1];
      final b = RequestIdGenerator(random: Random(42)).next().split('-')[1];
      expect(a, equals(b));
    });
  });
}
