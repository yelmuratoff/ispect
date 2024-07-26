// ignore_for_file: avoid_final_parameters, lines_longer_than_80_chars, inference_failure_on_untyped_parameter

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/src/common/services/talker/bloc/observer.dart';
import 'package:ispect/src/common/services/talker/talker_options.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_settings.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class ISpectTalker {
  factory ISpectTalker() => _instance;
  // ignore: prefer_const_constructor_declarations
  ISpectTalker._();

  late final Talker _talker;

  static final ISpectTalker _instance = ISpectTalker._();

  static ISpectTalker get instance => _instance;

  static Talker get talker => _instance._talker;
  static set talker(Talker talker) => _instance._talker = talker;

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
    info('🚀 ISpectTalker: Initialize started.');
    FlutterError.presentError = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPresentError?.call(details, details.stack);
        final exceptionAsString = details.exceptionAsString();
        final isFilterContains = filters.any(exceptionAsString.contains);
        if (options.isFlutterPresentHandlingEnabled && !isFilterContains) {
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

      final isFilterContains = filters.any(exceptionAsString.contains);

      if (options.isPlatformDispatcherHandlingEnabled && !isFilterContains) {
        _instance._talker.handle(error, stack);
      }
      return true;
    };

    FlutterError.onError = (details) {
      onFlutterError?.call(details, details.stack);
      final exceptionAsString = details.exceptionAsString();

      final isFilterContains = filters.any(exceptionAsString.contains);

      if (options.isFlutterErrorHandlingEnabled && !isFilterContains) {
        _instance._talker.error(
          'FlutterErrorDetails',
          details,
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

    good('✅ ISpectTalker: Success initialized.');
  }

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

  static void good(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.logTyped(
      _GoodLog(
        message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  static void print(String message) {
    _instance._talker.logTyped(
      _PrintLog(
        message,
      ),
    );
  }

  static void route(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.logTyped(
      _RouteLog(
        message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  static void provider(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._talker.logTyped(
      _ProviderLog(
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

/// `GoodLog` - This class contains the basic structure of the log.
class _GoodLog extends TalkerLog {
  _GoodLog(String super.message, {super.exception, super.stackTrace});

  /// Your custom log title
  @override
  String get title => 'good';

  /// Your custom log color
  @override
  AnsiPen get pen => AnsiPen()..xterm(121);
}

/// `RouteLog` - This class contains the route log.
class _RouteLog extends TalkerLog {
  _RouteLog(String super.message, {super.exception, super.stackTrace});

  /// Your custom log title
  @override
  String get title => 'route';

  /// Your custom log color
  @override
  AnsiPen get pen => AnsiPen()..rgb(r: 0.5, g: 0.5);
}

/// `ProviderLog` - This class contains the provider log.

class _ProviderLog extends TalkerLog {
  _ProviderLog(String super.message, {super.exception, super.stackTrace});

  /// Your custom log title
  @override
  String get title => 'provider';

  /// Your custom log color
  @override
  AnsiPen get pen => AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9);
}

class _PrintLog extends TalkerLog {
  _PrintLog(String super.message);

  @override
  String get title => 'print';

  @override
  AnsiPen get pen => AnsiPen()..blue();
}

AnsiPen getAnsiPenFromColor(Color color) =>
    AnsiPen()..rgb(r: color.red, g: color.green, b: color.blue);
