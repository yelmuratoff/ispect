import 'package:flutter/material.dart';

extension ISpectRouteExtension on Route<dynamic>? {
  /// Retrieves the route name with meaningful fallbacks based on route type.
  ///
  /// - Returns explicit name from `RouteSettings` if available.
  /// - Otherwise, returns a label based on route type (`PageRoute`, `ModalRoute`, `PopupRoute`).
  /// - Returns `runtimeType` or 'Unknown' as a last resort.
  String get routeName {
    final route = this;
    if (route == null) return 'Unknown';

    final name = route.settings.name?.trim();
    if (name != null && name.isNotEmpty) return name;

    if (route is PageRoute) return 'Unnamed Page';
    if (route is PopupRoute) return 'Unnamed Popup';
    if (route is ModalRoute) return 'Unnamed Modal';

    return route.runtimeType.toString();
  }

  /// Returns the runtime type of the route or 'Null' if the route is null.
  String get routeType {
    if (this is PageRoute) return 'Page';
    if (this is ModalRoute) return 'Modal';
    if (this is PopupRoute) return 'Popup';
    return runtimeType.toString();
  }
}
