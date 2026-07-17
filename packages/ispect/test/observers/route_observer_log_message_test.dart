import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/observers/route_observer.dart';
import 'package:ispect/src/common/observers/transition.dart';

void main() {
  group('route log message arguments', () {
    test('shows only string map keys when redaction is enabled', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(
          arguments: const <String, dynamic>{
            'token': 'secret',
            'screen': 'profile',
          },
        ),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, contains('Arguments: {token, screen}'));
      expect(message, isNot(contains('secret')));
      expect(message, isNot(contains('profile')));
    });

    test('shows only the runtime type for typed arguments', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(arguments: const _TypedRouteArguments(id: 'sensitive')),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, contains('Arguments: (_TypedRouteArguments)'));
      expect(message, isNot(contains('sensitive')));
    });

    test('does not stringify non-string map keys while redacting', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(
          arguments: const <Object, String>{
            _SensitiveKey('secret-key'): 'secret-value',
          },
        ),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, contains('Arguments: ('));
      expect(message, isNot(contains('secret-key')));
      expect(message, isNot(contains('secret-value')));
    });

    test('shows values when observer argument redaction is disabled', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(
          arguments: const <String, dynamic>{'token': 'secret'},
        ),
        previousRoute: null,
        enableArgumentRedaction: false,
        globalRedactionEnabled: true,
      );

      expect(message, contains('secret'));
    });

    test('shows values when global redaction is disabled', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(
          arguments: const <String, dynamic>{'token': 'secret'},
        ),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: false,
      );

      expect(message, contains('secret'));
    });
  });
}

Route<dynamic> _route({Object? arguments}) => MaterialPageRoute<void>(
      settings: RouteSettings(name: '/target', arguments: arguments),
      builder: (_) => const SizedBox.shrink(),
    );

final class _TypedRouteArguments {
  const _TypedRouteArguments({required this.id});

  final String id;
}

final class _SensitiveKey {
  const _SensitiveKey(this.value);

  final String value;

  @override
  String toString() => value;
}
