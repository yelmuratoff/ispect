import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';

extension ISpectifyFlutter on ISpectify {
  static ISpectify init({
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyOptions? options,
    ISpectifyFilter? filter,
  }) =>
      ISpectify(
        logger: (logger ?? ISpectifyLogger()).copyWith(
          output: _defaultFlutterOutput,
        ),
        options: options,
        observer: observer,
        // filter: filter,
      );

  static dynamic _defaultFlutterOutput(String message) {
    if (kIsWeb) {
      // ignore: avoid_print
      print(message);
      return;
    }
    if ([TargetPlatform.iOS, TargetPlatform.macOS]
        .contains(defaultTargetPlatform)) {
      log(message, name: 'ISpectify');
      return;
    }
    debugPrint(message);
  }
}
