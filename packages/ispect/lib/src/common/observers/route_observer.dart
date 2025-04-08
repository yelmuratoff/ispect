// ignore_for_file: prefer_const_constructor_declarations, cascade_invocations

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Extension on `StringBuffer` to conditionally write a line.
extension StringBufferExtension on StringBuffer {
  /// Writes `value` to the buffer if [condition] is true.
  // ignore: avoid_positional_boolean_parameters
  void writelnIf(bool condition, String value) {
    if (condition) writeln(value);
  }
}

/// A custom `NavigatorObserver` for logging navigation events.
///
/// This observer logs page transitions, modals, gestures, and other navigation events.
/// It provides callbacks for external listeners and allows filtering specific event types.
class ISpectNavigatorObserver extends NavigatorObserver {
  /// Creates an instance of `ISpectNavigatorObserver`.
  ///
  /// - `isLogGestures`: Whether to log user gestures.
  /// - `isLogPages`: Whether to log page navigations.
  /// - `isLogModals`: Whether to log modal transitions.
  /// - `isLogOtherTypes`: Whether to log other navigation types.
  ISpectNavigatorObserver({
    this.isLogGestures = false,
    this.isLogPages = true,
    this.isLogModals = true,
    this.isLogOtherTypes = true,
    this.onPush,
    this.onReplace,
    this.onPop,
    this.onRemove,
    this.onStartUserGesture,
    this.onStopUserGesture,
  });

  final bool isLogGestures;
  final bool isLogPages;
  final bool isLogModals;
  final bool isLogOtherTypes;

  final void Function(Route<dynamic> route, Route<dynamic>? previousRoute)?
      onPush;
  final void Function({Route<dynamic>? newRoute, Route<dynamic>? oldRoute})?
      onReplace;
  final void Function(Route<dynamic> route, Route<dynamic>? previousRoute)?
      onPop;
  final void Function(Route<dynamic> route, Route<dynamic>? previousRoute)?
      onRemove;
  final void Function(Route<dynamic> route, Route<dynamic>? previousRoute)?
      onStartUserGesture;
  final VoidCallback? onStopUserGesture;

  /// Determines the type of a given `route`.
  String _getRouteType(Route<dynamic>? route) {
    if (route is PageRoute) return 'Page';
    if (route is ModalRoute) return 'Modal';
    return route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPush?.call(route, previousRoute);
    _logRouteEvent('Push', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onReplace?.call(newRoute: newRoute, oldRoute: oldRoute);
    _logRouteEvent('Replace', newRoute, oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop?.call(route, previousRoute);
    _logRouteEvent('Pop', previousRoute, route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRemove?.call(route, previousRoute);
    _logRouteEvent('Remove', route, previousRoute);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (isLogGestures) {
      _logRouteEvent('Gesture: User gesture started', route, previousRoute);
    }
    onStartUserGesture?.call(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    if (isLogGestures) {
      ISpect.logger.route('User gesture stopped');
    }
    onStopUserGesture?.call();
  }

  /// Logs navigation events based on event type and route validation.
  void _logRouteEvent(
    String eventType,
    Route<dynamic>? route,
    Route<dynamic>? previousRoute,
  ) {
    if (!_shouldLog(route, previousRoute)) return;

    final logMessage = StringBuffer()
      ..writeln(
        '$eventType: ${_routeName(route)} (Type: ${_getRouteType(route)})',
      )
      ..writelnIf(
        _routeName(previousRoute).isNotEmpty,
        'Previous route: ${_routeName(previousRoute)} (Type: ${_getRouteType(previousRoute)})',
      )
      ..writelnIf(
        route?.settings.arguments != null,
        'Arguments: ${route?.settings.arguments}',
      );

    if (logMessage.isNotEmpty) {
      ISpect.logger.route(logMessage.toString().trim());
    }
  }

  /// Determines whether a route transition should be logged based on route types and configuration.
  ///
  /// This method evaluates the combination of route types in the transition against
  /// logging configuration flags to determine whether logging should occur.
  ///
  /// The logic follows these rules:
  /// 1. If both routes are PageRoutes, log only if `isLogPages` is true
  /// 2. If both routes are ModalRoutes (excluding PageRoutes), log only if `isLogModals` is true
  /// 3. If routes are of mixed types (e.g., one PageRoute and one ModalRoute), do not log
  /// 4. For any other route type combinations, log only if `isLogOtherTypes` is true
  ///
  /// - `route`: The new/current route being navigated to
  /// - `previousRoute`: The previous route being navigated from
  ///
  /// Returns true if the route transition should be logged based on current settings.
  bool _shouldLog(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    final routeIsPage = route is PageRoute;
    final prevRouteIsPage = previousRoute is PageRoute;

    // If both routes are PageRoutes
    if (routeIsPage && prevRouteIsPage) {
      return isLogPages;
    }

    // If one route is PageRoute and the other is not, don't log
    if (routeIsPage != prevRouteIsPage) {
      return false;
    }

    // At this point, neither route is a PageRoute
    final routeIsModal = route is ModalRoute;
    final prevRouteIsModal = previousRoute is ModalRoute;

    // If both routes are ModalRoutes
    if (routeIsModal && prevRouteIsModal) {
      return isLogModals;
    }

    // If one route is ModalRoute and the other is not, don't log
    if (routeIsModal != prevRouteIsModal) {
      return false;
    }

    // At this point, routes are neither PageRoutes nor ModalRoutes
    return isLogOtherTypes;
  }

  /// Retrieves the route name or a default placeholder.
  String _routeName(Route<dynamic>? route) => route?.settings.name ?? 'Unknown';
}
