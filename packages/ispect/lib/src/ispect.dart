// ignore_for_file: avoid_final_parameters, lines_longer_than_80_chars, inference_failure_on_untyped_parameter

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/extensions/pretty_json.dart';
import 'package:ispect/src/features/ispect/logs.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

/// `ISpect` - This class contains the main functionality of the library.
final class ISpect {
  factory ISpect() => _instance;
  // ignore: prefer_const_constructor_declarations
  ISpect._();

  late final ISpectify _iSpectify;

  static final ISpect _instance = ISpect._();

  static ISpect get instance => _instance;

  static ISpectify get iSpectify => _instance._iSpectify;
  static set iSpectify(ISpectify iSpectify) => _instance._iSpectify = iSpectify;

  static ISpectScopeModel read(BuildContext context) =>
      ISpectScopeController.of(
        context,
      );

  /// `run` - This function runs the callback function with the specified parameters.
  /// It initializes the handling of the app.
  static void run<T>(
    T Function() callback, {
    required ISpectify iSpectify,
    void Function(ISpectify iSpectify)? onInit,
    VoidCallback? onInitialized,
    void Function(Object error, StackTrace stackTrace)? onZonedError,

    /// Print logging in ISpect.
    bool isPrintLoggingEnabled = !kReleaseMode,

    /// Flutter print logs.
    bool isFlutterPrintEnabled = true,
    bool isZoneErrorHandlingEnabled = true,
    void Function(Object error, StackTrace stackTrace)?
        onPlatformDispatcherError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onFlutterError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onPresentError,
    void Function(List<dynamic> pair)? onUncaughtErrors,
    ISpectLogOptions options = const ISpectLogOptions(),
    List<String> filters = const [],
  }) {
    ISpect.initHandling(
      iSpectify: iSpectify,
      onPlatformDispatcherError: onPlatformDispatcherError,
      onFlutterError: onFlutterError,
      onPresentError: onPresentError,
      onUncaughtErrors: onUncaughtErrors,
      options: options,
      filters: filters,
    );
    onInit?.call(iSpectify);
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
    required ISpectify iSpectify,
    void Function(Object error, StackTrace stackTrace)?
        onPlatformDispatcherError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onFlutterError,
    void Function(FlutterErrorDetails details, StackTrace? stackTrace)?
        onPresentError,
    void Function(List<dynamic> pair)? onUncaughtErrors,
    final ISpectLogOptions options = const ISpectLogOptions(),
    final List<String> filters = const [],
  }) async {
    _instance._iSpectify = iSpectify;
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
          _instance._iSpectify.handle(details, details.stack);
        } else if (!isFilterNotEmpty) {
          _instance._iSpectify.handle(details, details.stack);
        }
      });
    };

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
        _instance._iSpectify.handle(error, stack);
      } else if (!isFilterNotEmpty) {
        _instance._iSpectify.handle(error, stack);
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
          _instance._iSpectify.error(
            'FlutterErrorDetails',
            details.toString(),
            details.stack,
          );
        }
      } else {
        _instance._iSpectify.error(
          'FlutterErrorDetails',
          details.toString(),
          details.stack,
        );
      }
    };

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
    _instance._iSpectify.log(
      message,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: level ?? LogLevel.info,
      pen: pen,
    );
  }

  static void logTyped(ISpectifyLog log) {
    _instance._iSpectify.logCustom(log);
  }

  static void good(String message) {
    _instance._iSpectify.logCustom(
      GoodLog(message),
    );
  }

  static void track(
    String message, {
    String? event,
    String? analytics,
    Map<String, dynamic>? parameters,
  }) {
    _instance._iSpectify.logCustom(
      AnalyticsLog(
        analytics: analytics,
        '${event ?? 'Event'}: $message\nParameters: ${prettyJson(parameters)}',
      ),
    );
  }

  static void print(String message) {
    _instance._iSpectify.logCustom(
      PrintLog(
        message,
      ),
    );
  }

  static void route(String message) {
    _instance._iSpectify.logCustom(
      RouteLog(message),
    );
  }

  static void provider(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _instance._iSpectify.logCustom(
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
    _instance._iSpectify.debug(
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
    _instance._iSpectify.info(
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
    _instance._iSpectify.warning(
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
    _instance._iSpectify.error(
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
    _instance._iSpectify.critical(
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
      _instance._iSpectify.handle(exception, stackTrace, message);
    }
  }
}
