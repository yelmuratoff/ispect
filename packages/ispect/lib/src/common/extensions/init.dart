import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';

extension ISpectifyFlutter on ISpectiy {
  static ISpectiy init({
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyOptions? settings,
    ISpectifyFilter? filter,
  }) =>
      ISpectiy(
        logger: (logger ?? ISpectifyLogger()).copyWith(
          output: _defaultFlutterOutput,
        ),
        settings: settings,
        observer: observer,
        filter: filter,
      );

  static dynamic _defaultFlutterOutput(String message) {
    if (kIsWeb) {
      // ignore: avoid_print
      print(message);
      return;
    }
    if ([TargetPlatform.iOS, TargetPlatform.macOS].contains(defaultTargetPlatform)) {
      log(message, name: 'ISpectiy');
      return;
    }
    debugPrint(message);
  }
}
