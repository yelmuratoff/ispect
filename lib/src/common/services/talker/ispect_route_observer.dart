// ignore_for_file: prefer_const_constructor_declarations

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

class ISpectNavigatorObserver extends NavigatorObserver {
  ISpectNavigatorObserver({
    this.isLogGustures = false,
  });

  final bool isLogGustures;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final logMessages = <String>[];

    if (route.settings.name != null) {
      logMessages.add('New route pushed: ${route.settings.name}');
    }

    if (previousRoute?.settings.name?.isNotEmpty ?? false) {
      logMessages.add('Previous route: ${previousRoute!.settings.name}');
    }

    if (route.settings.arguments != null) {
      logMessages.add('Arguments: ${route.settings.arguments}');
    }

    if (logMessages.isNotEmpty) {
      ISpectTalker.route(logMessages.join('\n'));
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final logMessages = <String>[];

    if (newRoute?.settings.name != null) {
      logMessages.add('New route after replaced: ${newRoute!.settings.name}');
    }

    if (oldRoute?.settings.name?.isNotEmpty ?? false) {
      logMessages.add('Old route: ${oldRoute!.settings.name}');
    }

    if (newRoute?.settings.arguments != null) {
      logMessages.add('Arguments: ${newRoute!.settings.arguments}');
    }

    if (logMessages.isNotEmpty) {
      ISpectTalker.route(logMessages.join('\n'));
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final logMessages = <String>[];

    if (route.settings.name != null) {
      logMessages.add('New route after popped: ${route.settings.name}');
    }

    if (previousRoute?.settings.name?.isNotEmpty ?? false) {
      logMessages.add('Previous route: ${previousRoute!.settings.name}');
    }

    if (route.settings.arguments != null) {
      logMessages.add('Arguments: ${route.settings.arguments}');
    }

    if (logMessages.isNotEmpty) {
      ISpectTalker.route(logMessages.join('\n'));
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final logMessages = <String>[];

    if (route.settings.name != null) {
      logMessages.add('New route after removed: ${route.settings.name}');
    }

    if (previousRoute?.settings.name?.isNotEmpty ?? false) {
      logMessages.add('Previous route: ${previousRoute!.settings.name}');
    }

    if (route.settings.arguments != null) {
      logMessages.add('Arguments: ${route.settings.arguments}');
    }

    if (logMessages.isNotEmpty) {
      ISpectTalker.route(logMessages.join('\n'));
    }
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (isLogGustures) {
      final logMessages = <String>[];

      if (route.settings.name != null) {
        logMessages
            .add('User gesture started on route: ${route.settings.name}');
      }

      if (previousRoute?.settings.name?.isNotEmpty ?? false) {
        logMessages.add('Previous route: ${previousRoute!.settings.name}');
      }

      if (route.settings.arguments != null) {
        logMessages.add('Arguments: ${route.settings.arguments}');
      }

      if (logMessages.isNotEmpty) {
        ISpectTalker.route(logMessages.join('\n'));
      }
    }
  }

  @override
  void didStopUserGesture() {
    if (isLogGustures) {
      ISpectTalker.route('User gesture stopped');
    }
  }
}
