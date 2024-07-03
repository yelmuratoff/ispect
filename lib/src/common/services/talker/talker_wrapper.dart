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
  ISpectTalker._();

  late final Talker _talker;

  static final ISpectTalker _instance = ISpectTalker._();

  static ISpectTalker get instance => _instance;

  static Talker get talker => _instance._talker;
  static set talker(Talker talker) => _instance._talker = talker;

  /// `initHandling` - This function initializes handling of the app.
  static Future<void> initHandling({
    required Talker talker,
    void Function()? onPlatformDispatcherError,
    void Function()? onFlutterError,
    void Function()? onPresentError,
    void Function()? onBlocError,
    void Function()? onBlocTransition,
    void Function()? onBlocEvent,
    void Function()? onBlocChange,
    void Function()? onBlocCreate,
    void Function()? onBlocClose,
    void Function()? onUncaughtErrors,
    final ISpectTalkerOptions options = const ISpectTalkerOptions(),
  }) async {
    _instance._talker = talker;
    info('🚀 ISpectTalker: Initialize started.');
    FlutterError.presentError = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPresentError?.call();
        if (options.isFlutterPresentHandlingEnabled) {
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
    );

    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call();
      if (options.isPlatformDispatcherHandlingEnabled) {
        _instance._talker.handle(error, stack);
      }
      return true;
    };

    FlutterError.onError = (details) {
      onFlutterError?.call();
      if (options.isFlutterErrorHandlingEnabled) {
        _instance._talker.handle(details, details.stack);
      }
    };

    Isolate.current
      ..setErrorsFatal(false)
      ..addErrorListener(
        RawReceivePort(
          (List<dynamic> pair) {
            onUncaughtErrors?.call();
            if (options.isUncaughtErrorsHandlingEnabled) {
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
    String? message,
    Object? exception,
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

AnsiPen getAnsiPenFromColor(Color color) =>
    AnsiPen()..rgb(r: color.red, g: color.green, b: color.blue);
