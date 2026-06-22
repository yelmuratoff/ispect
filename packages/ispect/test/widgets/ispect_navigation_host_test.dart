// The deprecated `ISpectBuilder(...)` constructor is the only way to reach
// `_ISpectBuilderState` in tests; `wrap` short-circuits in disabled builds.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';

/// A navigator that rejects imperative pops, mirroring how a declarative
/// router (e.g. `yx_navigation`) overrides [NavigatorState.pop].
class _ThrowOnPopNavigator extends Navigator {
  const _ThrowOnPopNavigator({super.observers, super.onGenerateRoute});

  @override
  NavigatorState createState() => _ThrowOnPopNavigatorState();
}

class _ThrowOnPopNavigatorState extends NavigatorState {
  @override
  void pop<T extends Object?>([T? result]) {
    throw StateError('RouteNode cannot be popped');
  }
}

void main() {
  group('ISpect navigation decoupling', () {
    testWidgets(
      'options.pop pops the local navigator even when the host navigator '
      'rejects imperative pops',
      (tester) async {
        final hostObserver = ISpectNavigatorObserver();
        final ispectNavKey = GlobalKey<NavigatorState>();
        final options = ISpectOptions(observer: hostObserver);

        await tester.pumpWidget(
          MaterialApp(
            home: _ThrowOnPopNavigator(
              observers: [hostObserver],
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Navigator(
                  key: ispectNavKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('ispect-base')),
                  ),
                ),
              ),
            ),
          ),
        );

        // Not awaited: a push future only completes once the route is popped.
        unawaited(
          ispectNavKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (ctx) => Scaffold(
                body: TextButton(
                  onPressed: () => options.pop(ctx),
                  child: const Text('back'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('back'), findsOneWidget);

        await tester.tap(find.text('back'));
        await tester.pumpAndSettle();

        expect(find.text('back'), findsNothing);
        expect(find.text('ispect-base'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'wrapped child stays interactive while no ISpect route is open',
      (tester) async {
        if (!kISpectEnabled) return;
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: ISpectLocalizations.delegate(),
            home: ISpectBuilder(
              options: const ISpectOptions(),
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => tapped = true,
                    child: const Text('app-button'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('app-button'));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'mounts a navigator dedicated to ISpect alongside the host navigator',
      (tester) async {
        if (!kISpectEnabled) return;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: ISpectLocalizations.delegate(),
            home: const ISpectBuilder(
              options: ISpectOptions(),
              child: Text('child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The host navigator (MaterialApp) plus ISpect's own overlay navigator.
        expect(find.byType(Navigator), findsAtLeastNWidgets(2));
      },
    );
  });
}
