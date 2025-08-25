import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispectify/ispectify.dart';

final _routeTimestampFormatter = DateFormat('dd.MM.yy, HH:mm:ss');

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
    if (route is ModalRoute) return 'Unnamed Modal';
    if (route is PopupRoute) return 'Unnamed Popup';

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

extension ISpectTransitionListExtension on List<RouteTransition> {
  /// Returns either full transitions text or truncated (ID-based) description.
  ///
  /// - [isTruncated]: if true, returns truncated description (like transitionsToId)
  /// - [id]: required if [isTruncated] is true
  String transitionsDescription({bool isTruncated = false, String? id}) {
    if (isEmpty) {
      return 'No transitions recorded';
    }
    if (isTruncated) {
      if (id == null) {
        throw ArgumentError('id must be provided when isTruncated is true');
      }
      return _truncatedTransitionsToId(id);
    }
    return _fullTransitionsText();
  }

  String transitionsText({
    bool isTruncated = false,
  }) =>
      transitionsDescription(isTruncated: isTruncated);

  String transitionsToId(
    String id, {
    bool isTruncated = true,
  }) =>
      transitionsDescription(isTruncated: isTruncated, id: id);

  String _fullTransitionsText() {
    final buffer = StringBuffer();
    final lastIndex = length - 1;
    for (var i = 0; i < length; i++) {
      final transition = this[i];
      buffer
        ..writeln(
          _transitionSuffix(i, i == lastIndex),
        )
        ..writeln(
          _routeTimestampFormatter.format(transition.timestamp),
        )
        ..writeln(
          '${transition.transitionText} (${transition.type.title})',
        );
      if (transition.arguments != null) {
        buffer.writeln('Arguments: ${transition.prettyArguments}');
      }
      buffer.writeln('\n${ConsoleUtils.bottomLine(20)}');
    }
    return buffer.toString();
  }

  String _truncatedTransitionsToId(String id) {
    final routeNames = <String>[];
    String? lastAdded;
    var found = false;

    for (var i = length - 1; i >= 0; i--) {
      final transition = this[i];
      final fromName = transition.from.routeName;
      final toName = transition.to.routeName;

      if (routeNames.isEmpty) {
        routeNames.add(fromName);
        lastAdded = fromName;
      }
      if (lastAdded != toName) {
        routeNames.add(toName);
        lastAdded = toName;
      }

      if (transition.id == id) {
        found = true;
        break;
      }
    }

    if (!found) {
      return 'Transition with id $id not found';
    }
    return routeNames.join(' → ');
  }

  String _transitionSuffix(int index, bool isLast) {
    if (index == 0) return 'Current: ';
    if (isLast) return 'Start: ';
    return '';
  }
}
