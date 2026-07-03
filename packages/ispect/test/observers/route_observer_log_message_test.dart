import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/observers/route_observer.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  group('ISpectNavigatorObserver log message', () {
    tearDown(() => ISpectRedaction.enabled = true);

    test('shows only argument keys when showArgumentValues is false', () {
      final observer = ISpectNavigatorObserver();
      final route = _route(
        arguments: const {'token': 'secret', 'screen': 'profile'},
      );

      final message = observer.buildLogMessage(
        TransitionType.push,
        route,
        null,
      );

      expect(message, contains('Arguments: {token, screen}'));
      expect(message, isNot(contains('secret')));
      expect(message, isNot(contains(': profile')));
    });

    test('shows argument values when showArgumentValues is true', () {
      final observer = ISpectNavigatorObserver(showArgumentValues: true);
      final route = _route(
        arguments: const {'token': 'secret', 'screen': 'profile'},
      );

      final message = observer.buildLogMessage(
        TransitionType.push,
        route,
        null,
      );

      expect(message, contains('secret'));
      expect(message, contains('profile'));
    });

    test('shows typed argument runtime type when values are hidden', () {
      final observer = ISpectNavigatorObserver();
      final route = _route(arguments: const _TypedRouteArgs(id: 1));

      final message = observer.buildLogMessage(
        TransitionType.push,
        route,
        null,
      );

      expect(message, contains('Arguments: (_TypedRouteArgs)'));
    });

    test('shows values when global redaction is disabled', () {
      ISpectRedaction.enabled = false;
      final observer = ISpectNavigatorObserver();
      final route = _route(arguments: const {'token': 'secret'});

      final message = observer.buildLogMessage(
        TransitionType.push,
        route,
        null,
      );

      expect(message, contains('secret'));
    });
  });
}

Route<dynamic> _route({Object? arguments}) => MaterialPageRoute<void>(
      settings: RouteSettings(name: '/profile', arguments: arguments),
      builder: (_) => const SizedBox.shrink(),
    );

class _TypedRouteArgs {
  const _TypedRouteArgs({required this.id});

  final int id;
}
