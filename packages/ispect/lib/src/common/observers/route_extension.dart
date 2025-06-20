import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispectify/ispectify.dart';

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
    forEachIndexed((index, transition) {
      buffer
        ..writeln(
          _transitionSuffix(index, index == length - 1),
        )
        ..writeln(
          DateFormat('dd.MM.yy, HH:mm:ss').format(transition.timestamp),
        )
        ..writeln(
          '${transition.transitionText} (${transition.type.title})',
        );
      if (transition.arguments != null) {
        buffer.writeln('Arguments: ${transition.prettyArguments}');
      }
      buffer.writeln('\n${ConsoleUtils.bottomLine(20)}');
    });
    return buffer.toString();
  }

  String _truncatedTransitionsToId(String id) {
    final list = reversed.toList(growable: false);
    final routeNames = <String>[];
    var found = false;
    for (final transition in list) {
      final fromName = transition.from.routeName;
      final toName = transition.to.routeName;
      if (routeNames.isEmpty) {
        routeNames.add(fromName);
      }
      if (routeNames.isEmpty || routeNames.last != toName) {
        routeNames.add(toName);
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
