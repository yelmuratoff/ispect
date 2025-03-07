// ignore_for_file: avoid_final_parameters, lines_longer_than_80_chars, inference_failure_on_untyped_parameter

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

/// `ISpect` - This class contains the main functionality of the library.
final class ISpect {
  factory ISpect() => _instance;
  ISpect._();

  static final ISpect _instance = ISpect._();
  static late ISpectify logger;

  static ISpectify get iSpectify => logger;
  static set iSpectify(ISpectify iSpectify) => logger = iSpectify;

  static ISpectScopeModel read(BuildContext context) =>
      ISpectScopeController.of(context);

  /// `run` - This function runs the callback function with the specified parameters.
  /// It initializes the handling of the app.
  static void run<T>(
    T Function() callback, {
    required ISpectify iSpectify,
    void Function(ISpectify iSpectify)? onInit,
    VoidCallback? onInitialized,
    void Function(Object error, StackTrace stackTrace)? onZonedError,
    bool isPrintLoggingEnabled = !kReleaseMode,
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
          ISpect.logger.handle(
            error,
            stackTrace,
            'Error from zoned handler',
          );
        } else if (!isFilterNotEmpty) {
          ISpect.logger.handle(
            error,
            stackTrace,
            'Error from zoned handler',
          );
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, parent, zone, line) {
          if (isPrintLoggingEnabled && !line.contains('\x1b')) {
            ISpect.logger.print(line);
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
    logger = iSpectify;
    ISpect.logger.info('🚀 ISpect: Initialize started.');

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
          logger.handle(details, details.stack); // Используем logger напрямую
        } else if (!isFilterNotEmpty) {
          logger.handle(details, details.stack);
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
        logger.handle(error, stack); // Используем logger напрямую
      } else if (!isFilterNotEmpty) {
        logger.handle(error, stack);
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
          logger.error(
            'FlutterErrorDetails',
            details.toString(),
            details.stack,
          );
        }
      } else {
        logger.error(
          'FlutterErrorDetails',
          details.toString(),
          details.stack,
        );
      }
    };

    ISpect.logger.good('✅ ISpect: Success initialized.');
  }
}
