// ignore_for_file: prefer_const_constructor_declarations, cascade_invocations

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

extension StringBufferExtension on StringBuffer {
  // ignore: avoid_positional_boolean_parameters
  void writelnIf(bool condition, String value) {
    if (condition) {
      writeln(value);
    }
  }
}

class ISpectNavigatorObserver extends NavigatorObserver {
  ISpectNavigatorObserver({
    this.isLogGestures = false,
  });

  final bool isLogGestures;

  String _getRouteType(Route<dynamic>? route) {
    if (route is PageRoute) {
      return 'Page';
    } else if (route is ModalRoute) {
      return 'Modal';
    } else {
      return route.runtimeType.toString();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeName = route.settings.name ?? 'Unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'None';

    final logMessage = StringBuffer()
      ..writeln('Push: $routeName (Type: ${_getRouteType(route)})')
      ..writelnIf(
        previousRouteName.isNotEmpty,
        'Previous route: $previousRouteName (Type: ${_getRouteType(previousRoute)})',
      )
      ..writelnIf(
        route.settings.arguments != null,
        'Arguments: ${route.settings.arguments}',
      );

    if (logMessage.isNotEmpty) {
      ISpectTalker.route(logMessage.toString().trim());
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final logMessage = StringBuffer();

    final newRouteName = newRoute?.settings.name ?? 'Unknown';
    final oldRouteName = oldRoute?.settings.name ?? 'None';

    logMessage
      ..writeln(
        'Replace: New route after replaced: $newRouteName (Type: ${_getRouteType(newRoute)})',
      )
      ..writelnIf(
        oldRouteName.isNotEmpty,
        'Old route: $oldRouteName (Type: ${_getRouteType(oldRoute)})',
      )
      ..writelnIf(
        newRoute?.settings.arguments != null,
        'Arguments: ${newRoute?.settings.arguments}',
      );

    if (logMessage.isNotEmpty) {
      ISpectTalker.route(logMessage.toString().trim());
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final logMessage = StringBuffer();

    final routeName = previousRoute?.settings.name ?? 'Unknown';
    final previousRouteName = route.settings.name ?? 'None';

    logMessage
      ..writeln(
        'Pop: New route after popped: $routeName (Type: ${_getRouteType(previousRoute)})',
      )
      ..writelnIf(
        previousRouteName.isNotEmpty,
        'Previous route: $previousRouteName (Type: ${_getRouteType(route)})',
      )
      ..writelnIf(
        route.settings.arguments != null,
        'Arguments: ${route.settings.arguments}',
      );

    if (logMessage.isNotEmpty) {
      ISpectTalker.route(logMessage.toString().trim());
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final logMessage = StringBuffer();

    final routeName = route.settings.name ?? 'Unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'None';

    logMessage
      ..writeln(
        'Remove: New route after removed: $routeName (Type: ${_getRouteType(route)})',
      )
      ..writelnIf(
        previousRouteName.isNotEmpty,
        'Previous route: $previousRouteName (Type: ${_getRouteType(previousRoute)})',
      )
      ..writelnIf(
        route.settings.arguments != null,
        'Arguments: ${route.settings.arguments}',
      );

    if (logMessage.isNotEmpty) {
      ISpectTalker.route(logMessage.toString().trim());
    }
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (isLogGestures) {
      final logMessage = StringBuffer();

      final routeName = route.settings.name ?? 'Unknown';
      final previousRouteName = previousRoute?.settings.name ?? 'None';

      logMessage
        ..writeln(
          'Gesture: User gesture started on route: $routeName (Type: ${_getRouteType(route)})',
        )
        ..writelnIf(
          previousRouteName.isNotEmpty,
          'Previous route: $previousRouteName (Type: ${_getRouteType(previousRoute)})',
        )
        ..writelnIf(
          route.settings.arguments != null,
          'Arguments: ${route.settings.arguments}',
        );

      if (logMessage.isNotEmpty) {
        ISpectTalker.route(logMessage.toString().trim());
      }
    }
  }

  @override
  void didStopUserGesture() {
    if (isLogGestures) {
      ISpectTalker.route('User gesture stopped');
    }
  }
}
