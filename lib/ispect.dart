import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/services/talker/talker_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

export 'package:ispect/src/common/controllers/ispect_scope.dart';
export 'package:ispect/src/common/models/talker_action_item.dart';
export 'package:ispect/src/common/res/ispect_theme.dart';
export 'package:ispect/src/common/services/talker/talker_wrapper.dart';
export 'package:ispect/src/common/utils/ispect_localizations.dart';
export 'package:ispect/src/common/utils/ispect_options.dart';
export 'package:ispect/src/common/widgets/builder/inspector_builder.dart';
export 'package:ispect/src/core/localization/localization.dart';

final class ISpect {
  static ISpectScopeModel read(BuildContext context) =>
      Provider.of<ISpectScopeModel>(context, listen: false);

  static ISpectScopeModel watch(BuildContext context) =>
      Provider.of<ISpectScopeModel>(context);

  static void run<T>(
    T Function() callback, {
    required Talker talker,
    VoidCallback? onInit,
    VoidCallback? onInitialized,
    void Function(Object error, StackTrace stackTrace)? onError,
    bool isPrintLoggingEnabled = true,
    bool isZoneErrorHandlingEnabled = true,
  }) {
    ISpectTalker.initHandling(
      talker: talker,
    );
    onInit?.call();
    runZonedGuarded(
      () {
        callback();
      },
      (error, stackTrace) {
        onError?.call(error, stackTrace);
        if (isZoneErrorHandlingEnabled) {
          ISpectTalker.handle(
            exception: error,
            stackTrace: stackTrace,
            message: 'Error from zoned handler: $error\n$stackTrace',
          );
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, parent, zone, line) {
          parent.print(zone, line);
          if (isPrintLoggingEnabled) {
            ISpectTalker.print(line);
          }
        },
      ),
    );
    onInitialized?.call();
  }
}
