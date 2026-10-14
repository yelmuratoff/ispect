import 'package:flutter/material.dart';

extension ISpectRouteExtension on Route<dynamic>? {
  /// Retrieves the route name with meaningful fallbacks based on route type.
  ///
  /// - Returns explicit name from `RouteSettings` if available.
  /// - Otherwise, returns a label based on route type (`PageRoute`, `ModalRoute`, `PopupRoute`).
  /// - Returns a generic label for other route implementations.
  String get routeName => switch (this) {
    null => 'Unknown',
    final Route<dynamic> route => switch ((
      route.settings.name?.trim(),
      route,
    )) {
      (final String name, _) when name.isNotEmpty => name,
      (_, PageRoute()) => 'Unnamed Page',
      (_, PopupRoute()) => 'Unnamed Popup',
      (_, ModalRoute()) => 'Unnamed Modal',
      _ => 'Unnamed Route',
    },
  };

  /// Returns a bounded route family or 'Null' if the route is null.
  String get routeType => switch (this) {
    null => 'Null',
    PageRoute() => 'Page',
    PopupRoute() => 'Popup',
    ModalRoute() => 'Modal',
    _ => 'Other',
  };
}
