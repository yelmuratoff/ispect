// ignore_for_file: avoid_final_parameters, lines_longer_than_80_chars, inference_failure_on_untyped_parameter

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/extensions/pretty_json.dart';
import 'package:ispect/src/features/talker/logs.dart';
import 'package:ispect/src/features/talker/observers/bloc_observer.dart';
import 'package:ispect/src/features/talker/talker_options.dart';
import 'package:provider/provider.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_settings.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// `ISpect` - This class contains the main functionality of the library.
final class ISpect {
  factory ISpect() => _instance;
  // ignore: prefer_const_constructor_declarations
  ISpect._();

  late final Talker _talker;

  static final ISpect _instance = ISpect._();

  static ISpect get instance => _instance;

  static Talker get talker => _instance._talker;
  static set talker(Talker talker) => _instance._talker = talker;

  static ISpectScopeModel read(BuildContext context) =>
      Provider.of<ISpectScopeModel>(
        context,
        listen: false,
      );

  static ISpectScopeModel watch(BuildContext context) =>
      Provider.of<ISpectScopeModel>(
        context,
      );

  /// `run` - This function runs the callback function with the specified parameters.
  /// It initializes the handling of the app.
  static void run<T>(
    T Function() callback, {
    required Talker talker,
    VoidCallback? onInit,
    VoidCallback? onInitialized,
    void Function(Object error, StackTrace stackTrace)? onZonedError,

    /// Print logging in ISpect.
    bool isPrintLoggingEnabled = kReleaseMode,

    /// Flutter print logs.
    bool isFlutterPrintEnabled = true,
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
    ISpect.initHandling(
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
        onZonedError?.call(error, stackTrace);
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
          ISpect.handle(
            exception: error,
            stackTrace: stackTrace,
            message: 'Error from zoned handler',
          );
        } else if (!isFilterNotEmpty) {
          ISpect.handle(
            exception: error,
            stackTrace: stackTrace,
            message: 'Error from zoned handler',
          );
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, parent, zone, line) {
          if (isPrintLoggingEnabled && !line.contains('\x1b')) {
            ISpect.print(line);
          } else {
            if (isFlutterPrintEnabled) {
              parent.print(zone, line);
            }
          }
        },
      ),
    );
    onInitialized?.call();
  }

  /// `initHandling` - This function initializes handling of the app.
  ///
  /// Filters works only for `BLoC` and Excetions: `FlutterError`, `PlatformDispatcher`, `UncaughtErrors`.
  /// For riverpod, routes, dio, etc. You need do it manually.
  static Future<void> initHandling({
    required Talker talker,
    void Function(Object error, StackTrace stackTrace)?
        onPlatformDispatcherError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onFlutterError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onPresentError,
    final void Function(Bloc<dynamic, dynamic> bloc, Object? event)?
        onBlocEvent,
    final void Function(
      Bloc<dynamic, dynamic> bloc,
      Transition<dynamic, dynamic> transition,
    )? onBlocTransition,
    final void Function(BlocBase<dynamic> bloc, Change<dynamic> change)?
        onBlocChange,
    final void Function(
      BlocBase<dynamic> bloc,
      Object error,
      StackTrace stackTrace,
    )? onBlocError,
    final void Function(BlocBase<dynamic> bloc)? onBlocCreate,
    final void Function(BlocBase<dynamic> bloc)? onBlocClose,
    void Function(List<dynamic> pair)? onUncaughtErrors,
    final ISpectTalkerOptions options = const ISpectTalkerOptions(),
    final List<String> filters = const [],
  }) async {
    _instance._talker = talker;
    info('🚀 ISpect: Initialize started.');

    FlutterError.presentError = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPresentError?.call(details, details.stack);
        final exceptionAsString = details.exceptionAsString();
        final stackAsString = details.stack.toString();

        final isFilterNotEmpty =
            filters.isNotEmpty && filters.any((element) => element.isNotEmpty);
        final isFilterContains = filters.any(
          (filter) =>
              exceptionAsString.contains(filter) ||
              stackAsString.contains(filter),
        );

        if (options.isFlutterPresentHandlingEnabled &&
            (!isFilterNotEmpty || !isFilterContains)) {
          _instance._talker.handle(details, details.stack);
        } else if (!isFilterNotEmpty) {
          _instance._talker.handle(details, details.stack);
        }
      });
    };

    Bloc.observer = TalkerBlocObserver(
      talker: talker,
      settings: TalkerBlocLoggerSettings(
        enabled: options.isBlocHandlingEnabled,
        printStateFullData: false,
      ),
      onBlocError: onBlocError,
      onBlocTransition: onBlocTransition,
      onBlocEvent: onBlocEvent,
      onBlocChange: onBlocChange,
      onBlocCreate: onBlocCreate,
      onBlocClose: onBlocClose,
      filters: filters,
    );

    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call(error, stack);
      final exceptionAsString = error.toString();
      final stackAsString = stack.toString();

      final isFilterNotEmpty =
          filters.isNotEmpty && filters.any((element) => element.isNotEmpty);
      final isFilterContains = filters.any(
        (filter) =>
            exceptionAsString.contains(filter) ||
            stackAsString.contains(filter),
      );

      if (options.isPlatformDispatcherHandlingEnabled &&
          (!isFilterNotEmpty || !isFilterContains)) {
        _instance._talker.handle(error, stack);
      } else if (!isFilterNotEmpty) {
        _instance._talker.handle(error, stack);
      }
      return true;
    };

    FlutterError.onError = (details) {
      onFlutterError?.call(details, details.stack);

      final isFilterNotEmpty =
          filters.isNotEmpty && filters.any((element) => element.isNotEmpty);

      if (isFilterNotEmpty) {
        final exceptionAsString = details.toString();
        final stackAsString = details.stack.toString();
        final isFilterContains = filters.any(
          (filter) =>
              exceptionAsString.contains(filter) ||
              stackAsString.contains(filter),
        );

        if (options.isFlutterErrorHandlingEnabled && !isFilterContains) {
          _instance._talker.error(
            'FlutterErrorDetails',
            details.toString(),
            details.stack,
          );
        }
      } else {
        _instance._talker.error(
          'FlutterErrorDetails',
          details.toString(),
          details.stack,
        );
      }
    };

    Isolate.current
      ..setErrorsFatal(false)
      ..addErrorListener(
        RawReceivePort(
          // ignore: avoid_types_on_closure_parameters
          (List<dynamic> pair) {
            onUncaughtErrors?.call(pair);
            final exceptionAsString = pair.toString();
            final isFilterContains = filters.any(exceptionAsString.contains);
            if (options.isUncaughtErrorsHandlingEnabled && !isFilterContains) {
              _instance._talker.error(pair);
            }
          },
        ).sendPort,
      );

    good('✅ ISpect: Success initialized.');
  }

  // <--- Logging functions --->

  static void log(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
    LogLevel? level,
    AnsiPen? pen,
  }) {
    _instance._talker.log(
      message,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: level ?? LogLevel.info,
      pen: pen,
    );
  }

  static void logTyped(TalkerLog log) {
    _instance._talker.logCustom(log);
  }

  static void good(String message) {
    _instance._talker.logCustom(
      GoodLog(message),
    );
  }

  static void track(
    String message, {
    String? event,
    String? analytics,
    Map<String, dynamic>? parameters,
  }) {
    _instance._talker.logCustom(
      AnalyticsLog(
        analytics: analytics,
        '${event ?? 'Event'}: $message\nParameters: ${prettyJson(parameters)}',
      ),
    );
  }

  static void print(String message) {
    _instance._talker.logCustom(
      PrintLog(
        message,
      ),
    );
  }

  static void route(String message) {
    _instance._talker.logCustom(
      RouteLog(message),
    );
  }

  static void provider(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.logCustom(
      ProviderLog(
        message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  static void debug(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.debug(
      message,
      exception,
      stackTrace,
    );
  }

  static void info(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.info(
      message,
      exception,
      stackTrace,
    );
  }

  static void warning(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.warning(
      message,
      exception,
      stackTrace,
    );
  }

  static void error({
    String? message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.error(
      message ?? 'An error occurred.',
      exception,
      stackTrace,
    );
  }

  static void critical({
    String? message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.critical(
      message ?? 'A critical error occurred.',
      exception,
      stackTrace,
    );
  }

  static void handle({
    required Object? exception,
    String? message,
    StackTrace? stackTrace,
  }) {
    if (exception != null) {
      _instance._talker.handle(exception, stackTrace, message);
    }
  }
}
