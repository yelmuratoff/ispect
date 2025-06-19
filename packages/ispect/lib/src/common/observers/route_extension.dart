import 'package:flutter/material.dart';

extension ISpectRouteExtension on Route<dynamic>? {
  /// Retrieves the route name with proper fallback handling.
  ///
  /// Returns the route name or a meaningful default based on route type.
  String get routeName {
    if (this == null) return 'Unknown';

    final name = this?.settings.name;
    if (name != null && name.isNotEmpty) return name;

    // Provide meaningful defaults based on route type
    if (this is PageRoute) return 'UnnamedPage';
    if (this is ModalRoute) return 'UnnamedModal';

    return 'Unknown';
  }
}
