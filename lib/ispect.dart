import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/services/talker/talker_options.dart';
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
export 'src/features/ispect/ispect_page.dart';

final class ISpect {
  static ISpectScopeModel read(BuildContext context) =>
      Provider.of<ISpectScopeModel>(context, listen: false);

  static ISpectScopeModel watch(BuildContext context) =>
      Provider.of<ISpectScopeModel>(context);

  late final GlobalKey<NavigatorState> navigatorKey;

  static void run<T>(
    T Function() callback, {
    required Talker talker,
    VoidCallback? onInit,
    VoidCallback? onInitialized,
    void Function(Object error, StackTrace stackTrace)? onError,
    bool isPrintLoggingEnabled = true,
    bool isZoneErrorHandlingEnabled = true,
    void Function(Object error, StackTrace stackTrace)?
        onPlatformDispatcherError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onFlutterError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onPresentError,
    void Function(Bloc<dynamic, dynamic> bloc, Object? event)? onBlocEvent,
    void Function(
      Bloc<dynamic, dynamic> bloc,
      Transition<dynamic, dynamic> transition,
    )? onBlocTransition,
    void Function(BlocBase<dynamic> bloc, Change<dynamic> change)? onBlocChange,
    void Function(
      BlocBase<dynamic> bloc,
      Object error,
      StackTrace stackTrace,
    )? onBlocError,
    void Function(BlocBase<dynamic> bloc)? onBlocCreate,
    void Function(BlocBase<dynamic> bloc)? onBlocClose,
    void Function(List<dynamic> pair)? onUncaughtErrors,
    ISpectTalkerOptions options = const ISpectTalkerOptions(),
    List<String> filters = const [],
  }) {
    ISpectTalker.initHandling(
      talker: talker,
      onPlatformDispatcherError: onPlatformDispatcherError,
      onFlutterError: onFlutterError,
      onPresentError: onPresentError,
      onBlocEvent: onBlocEvent,
      onBlocTransition: onBlocTransition,
      onBlocChange: onBlocChange,
      onBlocError: onBlocError,
      onBlocCreate: onBlocCreate,
      onBlocClose: onBlocClose,
      onUncaughtErrors: onUncaughtErrors,
      options: options,
      filters: filters,
    );
    onInit?.call();
    runZonedGuarded(
      () {
        callback();
      },
      (error, stackTrace) {
        onError?.call(error, stackTrace);
        final exceptionAsString = error.toString();
        final stackAsString = stackTrace.toString();

        final isFilterNotEmpty =
            filters.isNotEmpty && filters.any((element) => element.isNotEmpty);
        final isFilterContains = filters.any(
          (filter) =>
              exceptionAsString.contains(filter) ||
              stackAsString.contains(filter),
        );

        if (isZoneErrorHandlingEnabled &&
            (!isFilterNotEmpty || !isFilterContains)) {
          ISpectTalker.handle(
            exception: error,
            stackTrace: stackTrace,
            message: 'Error from zoned handler: $error\n$stackTrace',
          );
        } else if (!isFilterNotEmpty) {
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
