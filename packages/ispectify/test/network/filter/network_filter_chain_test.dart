import 'package:ispectify/src/network/filter/network_filter.dart';
import 'package:test/test.dart';

/// Simple pass-all filter for testing.
class _AlwaysPass extends NetworkFilter<int> {
  const _AlwaysPass();

  @override
  bool apply(int value) => true;
}

/// Simple reject-all filter for testing.
class _AlwaysReject extends NetworkFilter<int> {
  const _AlwaysReject();

  @override
  bool apply(int value) => false;
}

/// Filter that passes only even numbers.
class _EvenFilter extends NetworkFilter<int> {
  const _EvenFilter();

  @override
  bool apply(int value) => value.isEven;
}

/// Filter that passes only values > threshold.
class _ThresholdFilter extends NetworkFilter<int> {
  const _ThresholdFilter(this.threshold);

  final int threshold;

  @override
  bool apply(int value) => value > threshold;
}

void main() {
  group('NetworkFilterChain', () {
    test('empty chain permits all values', () {
      const chain = NetworkFilterChain<int>.empty();
      expect(chain.apply(0), isTrue);
      expect(chain.apply(42), isTrue);
      expect(chain.isEmpty, isTrue);
      expect(chain.length, 0);
    });

    test('single passing filter permits value', () {
      const chain = NetworkFilterChain<int>([_AlwaysPass()]);
      expect(chain.apply(1), isTrue);
      expect(chain.length, 1);
    });

    test('single rejecting filter blocks value', () {
      const chain = NetworkFilterChain<int>([_AlwaysReject()]);
      expect(chain.apply(1), isFalse);
    });

    test('AND semantics — all must pass', () {
      const chain = NetworkFilterChain<int>([
        _EvenFilter(),
        _ThresholdFilter(5),
      ]);
      // 8 is even AND > 5
      expect(chain.apply(8), isTrue);
      // 4 is even but NOT > 5
      expect(chain.apply(4), isFalse);
      // 7 is > 5 but NOT even
      expect(chain.apply(7), isFalse);
    });

    test('short-circuit — stops at first false', () {
      var secondCalled = false;

      final chain = NetworkFilterChain<int>([
        const _AlwaysReject(),
        _CallTracker(() => secondCalled = true),
      ]);

      expect(chain.apply(1), isFalse);
      expect(secondCalled, isFalse, reason: 'second filter should not run');
    });

    test('add returns new chain with appended filter', () {
      const original = NetworkFilterChain<int>([_EvenFilter()]);
      final extended = original.add(const _ThresholdFilter(10));

      expect(original.length, 1, reason: 'original unchanged');
      expect(extended.length, 2);
      // 12 is even AND > 10
      expect(extended.apply(12), isTrue);
      // 8 is even but NOT > 10
      expect(extended.apply(8), isFalse);
    });

    test('merge combines two chains', () {
      const a = NetworkFilterChain<int>([_EvenFilter()]);
      const b = NetworkFilterChain<int>([_ThresholdFilter(10)]);
      final merged = a.merge(b);

      expect(merged.length, 2);
      expect(merged.apply(12), isTrue);
      expect(merged.apply(8), isFalse);
    });

    test('fromPredicate wraps a callback', () {
      final chain = NetworkFilterChain<int>.fromPredicate((v) => v > 0);

      expect(chain.apply(5), isTrue);
      expect(chain.apply(-1), isFalse);
      expect(chain.length, 1);
    });

    test('any combinator — OR semantics', () {
      final orFilter = NetworkFilterChain.any<int>([
        const _EvenFilter(),
        const _ThresholdFilter(100),
      ]);

      final chain = NetworkFilterChain<int>([orFilter]);

      // 4 is even → passes
      expect(chain.apply(4), isTrue);
      // 101 is > 100 → passes
      expect(chain.apply(101), isTrue);
      // 3 is neither even nor > 100 → fails
      expect(chain.apply(3), isFalse);
    });

    test('any with empty list rejects all', () {
      final orFilter = NetworkFilterChain.any<int>([]);
      final chain = NetworkFilterChain<int>([orFilter]);

      expect(chain.apply(42), isFalse);
    });
  });
}

/// Helper filter that tracks whether it was called.
class _CallTracker extends NetworkFilter<int> {
  _CallTracker(this._onCall);

  final void Function() _onCall;

  @override
  bool apply(int value) {
    _onCall();
    return true;
  }
}
