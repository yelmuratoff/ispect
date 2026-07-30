import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/observers/route_extension.dart';
import 'package:ispect/src/common/observers/route_sanitizer.dart';
import 'package:ispect/src/common/observers/transition.dart';

void main() {
  tearDown(() async {
    await ISpect.dispose();
    ISpectRedaction.reset();
  });

  test(
    'disabled logger stops route capture before callbacks and inspection',
    () {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(
          enabled: false,
          useConsoleLogs: false,
        ),
      );
      expect(ISpect.initialize(logger), isTrue);
      var callbackCount = 0;
      final route = _ThrowingSettingsRoute();
      final observer = ISpectNavigatorObserver(
        onPush: (_, __) => callbackCount++,
      )
        ..didPush(route, null)
        ..addTransition(
          RouteTransition(
            id: 'external',
            from: null,
            to: null,
            type: TransitionType.push,
            timestamp: DateTime(2026),
            arguments: null,
          ),
        );

      expect(callbackCount, 0);
      expect(route.calls, 0);
      expect(observer.transitions, isEmpty);
    },
    skip: !kISpectEnabled
        ? 'Navigation capture requires ISPECT_ENABLED for this test.'
        : false,
  );

  test('lazy logger access does not activate route capture', () async {
    await ISpect.dispose();
    final lazy = ISpect.logger;
    var callbackCount = 0;
    final route = _ThrowingSettingsRoute();
    final observer = ISpectNavigatorObserver(
      onPush: (_, __) => callbackCount++,
    )
      ..didPush(route, null)
      ..addTransition(
        RouteTransition(
          id: 'external',
          from: null,
          to: null,
          type: TransitionType.push,
          timestamp: DateTime(2026),
          arguments: null,
        ),
      );

    expect(lazy.isDisposed, isFalse);
    expect(ISpect.loggerIfInitialized, isNull);
    expect(callbackCount, 0);
    expect(route.calls, 0);
    expect(observer.transitions, isEmpty);
  });

  test(
    'route transition hash stays stable when logger limits change',
    () {
      _initializeRouteCapture();
      final transition = RouteTransition(
        id: 'stable-hash',
        from: const RouteMetadata(name: '/from', routeType: 'Page'),
        to: const RouteMetadata(name: '/to', routeType: 'Page'),
        type: TransitionType.push,
        timestamp: DateTime(2026),
        arguments: {'payload': 'x' * 1024},
      );
      final transitions = <RouteTransition>{transition};
      final initialHash = transition.hashCode;

      final logger = ISpect.logger;
      logger.configure(
        options: logger.options.copyWith(
          resourceLimits: DiagnosticResourceLimits.balanced.copyWith(
            maxCapturedValueBytes: 64,
          ),
        ),
      );

      expect(transition.hashCode, initialHash);
      expect(transitions, contains(transition));
    },
    skip: !kISpectEnabled
        ? 'Navigation capture requires ISPECT_ENABLED for this test.'
        : false,
  );

  test(
    'observer remains inert after run is disposed',
    () async {
      var callbackCount = 0;
      final observer = ISpectNavigatorObserver(
        onPush: (_, __) => callbackCount++,
      );
      ISpect.run(
        () {},
        logger: ISpectLogger(
          options: ISpectLoggerOptions(useConsoleLogs: false),
        ),
      );
      await ISpect.dispose();
      final route = _ThrowingSettingsRoute();

      expect(() => observer.didPush(route, null), returnsNormally);
      observer.addTransition(
        RouteTransition(
          id: 'external',
          from: null,
          to: null,
          type: TransitionType.push,
          timestamp: DateTime(2026),
          arguments: null,
        ),
      );

      expect(callbackCount, 0);
      expect(route.calls, 0);
      expect(observer.transitions, isEmpty);
    },
    skip: !kISpectEnabled
        ? 'Navigation capture requires ISPECT_ENABLED for this test.'
        : false,
  );

  group('route log message arguments', () {
    test('shows only the map family when redaction is enabled', () {
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

      expect(message, contains('Arguments: Map'));
      expect(message, isNot(contains('token')));
      expect(message, isNot(contains('screen')));
      expect(message, isNot(contains('secret')));
      expect(message, isNot(contains('profile')));
    });

    test('shows only a generic family for typed arguments', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(arguments: const _TypedRouteArguments(id: 'sensitive')),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, contains('Arguments: (Object)'));
      expect(message, isNot(contains('sensitive')));
    });

    test('does not inspect an arbitrary argument runtime type', () {
      final arguments = _HostileRuntimeTypeArguments();

      expect(summarizeRouteDiagnosticArguments(arguments), '(Object)');
      expect(arguments.calls, 0);
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

      expect(message, contains('Arguments: Map'));
      expect(message, isNot(contains('secret-key')));
      expect(message, isNot(contains('secret-value')));
    });

    test('fails closed when a map rejects length inspection', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(arguments: _ThrowingLengthMap()),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, contains('Arguments: Map'));
      expect(message, isNot(contains('MAP_LENGTH_SECRET')));
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

    test('does not execute an opt-out argument formatter', () {
      final arguments = _HostileRouteArguments();
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(arguments: arguments),
        previousRoute: null,
        enableArgumentRedaction: false,
        globalRedactionEnabled: true,
      );

      expect(arguments.calls, 0);
      expect(message, contains(JsonValueNormalizer.unprintableValue));
      expect(message, isNot(contains('HOSTILE_ROUTE_FORMATTER')));
    });

    test('bounds oversized opt-out argument text', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(arguments: 'a' * (4 * 1024 * 1024)),
        previousRoute: null,
        enableArgumentRedaction: false,
        globalRedactionEnabled: true,
      );

      expect(
        LogExportOutput.utf8Length(message),
        lessThan(
          LogExportOutput.maxPreparedValueBytes + 1024,
        ),
      );
      expect(message, endsWith(LogExportOutput.truncatedMarker));
    });

    test('route diagnostics resolve the current global policy', () {
      final configuredService = RedactionService(
        sensitiveKeys: const {'global_field'},
        placeholder: '<global>',
      );
      ISpectRedaction.configure(service: configuredService);

      final sanitized = sanitizeRouteDiagnosticText(
        'global_field=ROUTE_RAW',
      );

      expect(sanitized, 'global_field=<global>');
      expect(ISpectRedaction.service, same(configuredService));
    });
  });

  group('stored route arguments', () {
    setUp(_initializeRouteCapture);

    test(
      'sanitizes transitions supplied through the public storage boundary',
      () {
        final observer = ISpectNavigatorObserver()
          ..addTransition(
            RouteTransition(
              id: 'external',
              from: const RouteMetadata(
                name: '/users/alice@example.com',
                routeType: 'Page',
              ),
              to: const RouteMetadata(
                name: '/orders/123456?token=QUERY_SECRET',
                routeType: 'Page',
              ),
              type: TransitionType.push,
              timestamp: DateTime(2026),
              arguments: const {'token': 'ARGUMENT_SECRET'},
            ),
          );

        final stored = observer.transitions.single;
        expect(stored.from?.name, isNot(contains('alice@example.com')));
        expect(stored.to?.name, isNot(contains('123456')));
        expect(stored.to?.name, isNot(contains('QUERY_SECRET')));
        expect(stored.arguments, 'Map');
        expect(stored.toString(), isNot(contains('ARGUMENT_SECRET')));
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'retains only typed argument metadata when redaction is enabled',
      () {
        const arguments = _TypedRouteArguments(id: 'ROUTE_SECRET');
        final observer = ISpectNavigatorObserver()
          ..didPush(_route(arguments: arguments), null);

        final stored = observer.transitions.single.arguments;
        expect(stored, '(Object)');
        expect('$stored', isNot(contains('ROUTE_SECRET')));
        expect(stored, isNot(same(arguments)));
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'retains only the map family',
      () {
        final observer = ISpectNavigatorObserver()
          ..didPush(
            _route(
              arguments: const <String, dynamic>{
                'token': 'ROUTE_SECRET',
                'screen': 'profile',
              },
            ),
            null,
          );

        final stored = observer.transitions.single.arguments;
        expect(stored, 'Map');
        expect('$stored', isNot(contains('token')));
        expect('$stored', isNot(contains('screen')));
        expect('$stored', isNot(contains('ROUTE_SECRET')));
        expect('$stored', isNot(contains('profile')));
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'snapshots arguments for an explicit observer redaction opt-out',
      () {
        final arguments = _HostileRouteArguments();
        final observer = ISpectNavigatorObserver(
          enableArgumentRedaction: false,
        )..didPush(_route(arguments: arguments), null);

        final stored = observer.transitions.single.arguments;
        expect(stored, isNot(same(arguments)));
        expect(stored, JsonValueNormalizer.unprintableValue);
        expect('$stored', isNot(contains('HOSTILE_ROUTE_FORMATTER')));
        expect(arguments.calls, 0);
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'snapshots arguments after an explicit global redaction opt-out',
      () {
        final arguments = _HostileRouteArguments();
        final observer = ISpectNavigatorObserver();
        ISpectRedaction.enabled = false;

        observer.didPush(_route(arguments: arguments), null);

        final stored = observer.transitions.single.arguments;
        expect(stored, isNot(same(arguments)));
        expect(stored, JsonValueNormalizer.unprintableValue);
        expect('$stored', isNot(contains('HOSTILE_ROUTE_FORMATTER')));
        expect(arguments.calls, 0);
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'preserves safe bounded map content after an argument opt-out',
      () {
        final arguments = <String, Object?>{
          'screen': 'profile',
          'items': List<String>.filled(2000, 'x' * 100),
        };
        final observer = ISpectNavigatorObserver(
          enableArgumentRedaction: false,
        )..didPush(_route(arguments: arguments), null);

        final stored = observer.transitions.single.arguments;
        expect(stored, isA<Map<String, Object?>>());
        expect(stored, isNot(same(arguments)));
        expect((stored! as Map<String, Object?>)['screen'], 'profile');
        expect(
          LogExportOutput.utf8Length(jsonEncode(stored)),
          lessThan(LogExportOutput.maxPreparedValueBytes + 16 * 1024),
        );
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'external transitions are copied and bounded after global opt-out',
      () {
        ISpectRedaction.enabled = false;
        final arguments = _HostileRouteArguments();
        final transition = RouteTransition(
          id: 'i' * (4 * 1024 * 1024),
          from: RouteMetadata(
            name: 'n' * (4 * 1024 * 1024),
            routeType: 't' * (4 * 1024 * 1024),
          ),
          to: null,
          type: TransitionType.push,
          timestamp: DateTime(2026),
          arguments: arguments,
        );
        final observer = ISpectNavigatorObserver(
          enableArgumentRedaction: false,
        )..addTransition(transition);

        final stored = observer.transitions.single;
        expect(stored, isNot(same(transition)));
        expect(stored.arguments, isNot(same(arguments)));
        expect(arguments.calls, 0);
        for (final value in [
          stored.id,
          stored.from!.name,
          stored.from!.routeType,
        ]) {
          expect(
            LogExportOutput.utf8Length(value),
            lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
          );
          expect(value, endsWith(LogExportOutput.truncatedMarker));
        }
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );

    test(
      'stored opt-out maps fail closed when traversal throws',
      () {
        final arguments = _ThrowingEntriesMap();
        final observer = ISpectNavigatorObserver(
          enableArgumentRedaction: false,
        )..didPush(_route(arguments: arguments), null);

        expect(arguments.calls, 2);
        expect(observer.transitions.single.arguments, {
          JsonValueNormalizer.traversalMarkerKey:
              JsonValueNormalizer.unprintableValue,
        });
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );
  });

  group('route-name minimization', () {
    setUp(_initializeRouteCapture);

    test('route fallbacks do not inspect a custom route runtime type', () {
      final route = _HostileRuntimeTypeRoute();

      expect(route.routeName, 'Unnamed Route');
      expect(route.routeType, 'Other');
      expect(route.calls, 0);
    });

    test('removes email, identifier, query, and fragment values', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(
          name: '/users/alice@example.com/orders/123456?token=QUERY_SECRET',
        ),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, isNot(contains('alice@example.com')));
      expect(message, isNot(contains('123456')));
      expect(message, isNot(contains('QUERY_SECRET')));
      expect(message, contains('[REDACTED]'));
    });

    test('removes short human-readable route slugs', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(name: '/users/alice'),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: true,
      );

      expect(message, isNot(contains('users')));
      expect(message, isNot(contains('alice')));
      expect(message, contains('[REDACTED]'));
    });

    test('keeps the raw route name after global redaction opt-out', () {
      final message = buildRouteLogMessage(
        type: TransitionType.push,
        route: _route(name: '/users/alice@example.com'),
        previousRoute: null,
        enableArgumentRedaction: true,
        globalRedactionEnabled: false,
      );

      expect(message, contains('alice@example.com'));
    });

    test('bounds an oversized route name after an explicit opt-out', () {
      final result = sanitizeRouteDiagnosticName(
        '/'.padRight(4 * 1024 * 1024, 'a'),
        enableRedaction: false,
      );

      expect(
        LogExportOutput.utf8Length(result),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(result, endsWith(LogExportOutput.truncatedMarker));
    });

    test(
      'stores a minimized route name in transition history',
      () {
        final observer = ISpectNavigatorObserver()
          ..didPush(_route(name: '/users/alice@example.com'), null);

        expect(
          observer.transitions.single.to?.name,
          isNot(contains('alice@example.com')),
        );
      },
      skip: !kISpectEnabled
          ? 'Navigation capture requires ISPECT_ENABLED for this test.'
          : false,
    );
  });
}

void _initializeRouteCapture() {
  if (!kISpectEnabled) return;
  final initialized = ISpect.initialize(
    ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    ),
  );
  expect(initialized, isTrue);
}

Route<dynamic> _route({Object? arguments, String name = '/target'}) =>
    MaterialPageRoute<void>(
      settings: RouteSettings(name: name, arguments: arguments),
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

final class _HostileRouteArguments {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_ROUTE_FORMATTER');
  }
}

final class _HostileRuntimeTypeArguments {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('HOSTILE_ROUTE_RUNTIME_TYPE');
  }
}

final class _HostileRuntimeTypeRoute extends Route<void> {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('HOSTILE_ROUTE_RUNTIME_TYPE');
  }
}

final class _ThrowingSettingsRoute extends Route<void> {
  int calls = 0;

  @override
  RouteSettings get settings {
    calls++;
    throw StateError('HOSTILE_ROUTE_SETTINGS');
  }
}

final class _ThrowingLengthMap extends MapBase<Object?, Object?> {
  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(Object? key, Object? value) {}

  @override
  void clear() {}

  @override
  Iterable<Object?> get keys => const <Object?>[];

  @override
  int get length => throw StateError('MAP_LENGTH_SECRET');

  @override
  Object? remove(Object? key) => null;
}

final class _ThrowingEntriesMap extends MapBase<Object?, Object?> {
  int calls = 0;

  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(Object? key, Object? value) {}

  @override
  void clear() {}

  @override
  Iterable<MapEntry<Object?, Object?>> get entries {
    calls++;
    throw StateError('ROUTE_MAP_SECRET');
  }

  @override
  Iterable<Object?> get keys => const <Object?>[];

  @override
  Object? remove(Object? key) => null;
}
