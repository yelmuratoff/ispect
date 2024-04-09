import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

final ISpectTalker talkerWrapper = ISpectTalker.instance;

final class ISpectTalker {
  ISpectTalker._();

  late final Talker _talker;

  static final ISpectTalker _instance = ISpectTalker._();
  static ISpectTalker get instance {
    try {
      return _instance;
    } catch (e) {
      throw Exception('ISpectTalker is not initialized. Please call ISpectTalker.initHandling() first.');
    }
  }

  static Talker get talker => instance._talker;
  static set talker(Talker talker) => instance._talker = talker;

  // static final ISpectTalker _instance = ISpectTalker._();
  // static ISpectTalker get instance => _instance;

  /// `initHandling` - This function initializes handling of the app.
  Future<void> initHandling({
    required Talker talker,
    Function()? onPlatformDispatcherError,
    Function()? onFlutterError,
  }) async {
    ISpectTalker.talker = talker;
    info(message: 'ISpectTalker: Initialize started.');
    FlutterError.presentError = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        instance._talker.handle(details, details.stack);
      });
    };

    Bloc.observer = TalkerBlocObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(
        printStateFullData: false,
      ),
    );

    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call();
      instance._talker.handle(error, stack);
      return true;
    };

    FlutterError.onError = (details) {
      onFlutterError?.call();
      instance._talker.handle(details, details.stack);
    };

    good(message: 'ISpectTalker: Success initialized.');
  }

  void log({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
    LogLevel? level,
    AnsiPen? pen,
  }) {
    instance._talker.log(
      message,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: level ?? LogLevel.info,
      pen: pen,
    );
  }

  void good({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.logTyped(
      _GoodLog(
        message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void route({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.logTyped(
      _RouteLog(
        message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void provider({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.logTyped(
      _ProviderLog(
        message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  void debug({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.debug(
      message,
      exception,
      stackTrace,
    );
  }

  void info({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.info(
      message,
      exception,
      stackTrace,
    );
  }

  void warning({
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.warning(
      message,
      exception,
      stackTrace,
    );
  }

  void error({
    String? message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.error(
      message ?? 'An error occurred.',
      exception,
      stackTrace,
    );
  }

  void critical({
    String? message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    instance._talker.critical(
      message ?? 'A critical error occurred.',
      exception,
      stackTrace,
    );
  }

  void handle({
    String? message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    if (exception != null) {
      instance._talker.handle(exception, stackTrace, message);
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

AnsiPen getAnsiPenFromColor(Color color) => AnsiPen()..rgb(r: color.red, g: color.green, b: color.blue);
