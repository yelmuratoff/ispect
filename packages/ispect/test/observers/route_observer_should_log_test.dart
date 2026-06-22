// Pins down `ISpectNavigatorObserver.shouldLog`: the destination route's kind
// alone decides logging. The regression case is a page pushed from under a
// modal (e.g. a profile opened from a bottom sheet) — it must stay a page
// transition governed by `isLogPages`, not get dropped as "modal".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  PageRoute<void> pageRoute({String? name}) => MaterialPageRoute<void>(
        settings: name == null ? null : RouteSettings(name: name),
        builder: (_) => const SizedBox.shrink(),
      );

  group('ISpectNavigatorObserver.shouldLog', () {
    test('logs page destinations when isLogPages is true', () {
      final observer = ISpectNavigatorObserver();

      expect(observer.shouldLog(pageRoute()), isTrue);
    });

    test('suppresses page destinations when isLogPages is false', () {
      final observer = ISpectNavigatorObserver(isLogPages: false);

      expect(observer.shouldLog(pageRoute()), isFalse);
    });

    test('logs a page pushed from under a modal as a page (regression)', () {
      // Default flags: isLogPages = true, isLogModals = false. The previous
      // route is a bottom sheet, but the destination is a page, so the
      // transition must be logged on the strength of isLogPages alone.
      final observer = ISpectNavigatorObserver();

      expect(observer.shouldLog(pageRoute()), isTrue);
    });

    test('suppresses modal destinations by default', () {
      final observer = ISpectNavigatorObserver();

      expect(observer.shouldLog(_FakePopupRoute()), isFalse);
    });

    test('logs modal destinations when isLogModals is true', () {
      final observer = ISpectNavigatorObserver(isLogModals: true);

      expect(observer.shouldLog(_FakePopupRoute()), isTrue);
    });

    test('logs other route types when isLogOtherTypes is true', () {
      final observer = ISpectNavigatorObserver();

      expect(observer.shouldLog(_FakeRoute()), isTrue);
    });

    test('suppresses other route types when isLogOtherTypes is false', () {
      final observer = ISpectNavigatorObserver(isLogOtherTypes: false);

      expect(observer.shouldLog(_FakeRoute()), isFalse);
    });

    test('treats a null destination as an other route type', () {
      final observer = ISpectNavigatorObserver();

      expect(observer.shouldLog(null), isTrue);
    });

    test('excludes internal ISpect routes by default', () {
      final observer = ISpectNavigatorObserver();

      expect(observer.shouldLog(pageRoute(name: 'ISpectInspector')), isFalse);
    });

    test('logs internal routes when isLogInternalRoutes is true', () {
      final observer = ISpectNavigatorObserver(isLogInternalRoutes: true);

      expect(observer.shouldLog(pageRoute(name: 'ISpectInspector')), isTrue);
    });
  });
}

class _FakePopupRoute extends PopupRoute<void> {
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      const SizedBox.shrink();
}

class _FakeRoute extends Route<void> {}
