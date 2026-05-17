// Pins down the auto-singleton contract on `ISpectNavigatorObserver`:
// `observers()` publishes the installed observer in `current`, repeated calls
// reuse it, an explicit observer wins, and `resetCurrent()` clears the slot.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  group('ISpectNavigatorObserver auto-singleton', () {
    setUp(ISpectNavigatorObserver.resetCurrent);
    tearDown(ISpectNavigatorObserver.resetCurrent);

    test('observers() respects kISpectEnabled gate on current', () {
      ISpectNavigatorObserver.observers();
      if (kISpectEnabled) {
        expect(ISpectNavigatorObserver.current, isA<ISpectNavigatorObserver>());
      } else {
        expect(ISpectNavigatorObserver.current, isNull);
      }
    });

    test('observers() includes additional observers in either build', () {
      final extra = _NoopObserver();
      final list = ISpectNavigatorObserver.observers(additional: [extra]);
      expect(list, contains(extra));
    });

    test('observers() reuses the auto-created instance across calls', () {
      if (!kISpectEnabled) return;

      final first = ISpectNavigatorObserver.observers()
          .whereType<ISpectNavigatorObserver>()
          .single;
      final second = ISpectNavigatorObserver.observers()
          .whereType<ISpectNavigatorObserver>()
          .single;

      expect(identical(first, second), isTrue);
      expect(ISpectNavigatorObserver.current, same(first));
    });

    test('explicit observer becomes current and replaces previous', () {
      if (!kISpectEnabled) return;

      ISpectNavigatorObserver.observers();
      final auto = ISpectNavigatorObserver.current;

      final explicit = ISpectNavigatorObserver();
      ISpectNavigatorObserver.observers(observer: explicit);

      expect(ISpectNavigatorObserver.current, same(explicit));
      expect(ISpectNavigatorObserver.current, isNot(same(auto)));
    });

    test('resetCurrent() clears the slot', () {
      if (!kISpectEnabled) return;

      ISpectNavigatorObserver.observers();
      expect(ISpectNavigatorObserver.current, isNotNull);

      ISpectNavigatorObserver.resetCurrent();
      expect(ISpectNavigatorObserver.current, isNull);
    });
  });

  group('ISpect.dispose() clears observer current', () {
    setUp(ISpectNavigatorObserver.resetCurrent);
    tearDown(ISpectNavigatorObserver.resetCurrent);

    test('dispose() resets current', () async {
      if (!kISpectEnabled) return;

      ISpectNavigatorObserver.observers();
      expect(ISpectNavigatorObserver.current, isNotNull);

      await ISpect.dispose();

      expect(ISpectNavigatorObserver.current, isNull);
    });
  });
}

class _NoopObserver extends NavigatorObserver {}
