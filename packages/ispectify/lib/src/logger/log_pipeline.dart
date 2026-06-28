import 'dart:async';
import 'dart:developer';

import 'package:ispectify/src/filter/filter.dart';
import 'package:ispectify/src/history/history.dart';
import 'package:ispectify/src/logger/logger.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/options.dart';
import 'package:ispectify/src/utils/string_extension.dart';

/// Coordinates fan-out of accepted log entries to the stream, history, and
/// console logger. Owned by `ISpectLogger`; reconfigured via [update].
final class LogPipeline {
  LogPipeline({
    required StreamController<ISpectLogData> streamController,
    required ISpectLoggerOptions options,
    required ISpectBaseLogger consoleLogger,
    required ILogHistory history,
    ISpectFilter? filter,
  })  : _streamController = streamController,
        _options = options,
        _consoleLogger = consoleLogger,
        _history = history,
        _filter = filter;

  final StreamController<ISpectLogData> _streamController;

  ISpectLoggerOptions _options;
  ISpectBaseLogger _consoleLogger;
  ILogHistory _history;
  ISpectFilter? _filter;

  void update({
    ISpectLoggerOptions? options,
    ISpectBaseLogger? consoleLogger,
    ILogHistory? history,
    ISpectFilter? filter,
  }) {
    _options = options ?? _options;
    _consoleLogger = consoleLogger ?? _consoleLogger;
    _history = history ?? _history;
    _filter = filter ?? _filter;
  }

  void clearFilter() {
    _filter = null;
  }

  bool shouldProcess(ISpectLogData data) {
    if (!_options.enabled) return false;
    return _filter?.apply(data) ?? true;
  }

  /// Guards against re-entrant dispatch (e.g. a listener that logs).
  ///
  /// Safe in Dart's single-threaded event loop: only one synchronous call
  /// chain can execute at a time, so no atomic/lock is needed.
  bool _isDispatching = false;

  void dispatch(ISpectLogData data) {
    if (_isDispatching) return;
    _isDispatching = true;
    try {
      // Add to history BEFORE emitting to stream so that listeners
      // (e.g. StreamBuilder) see the new entry when they read history.
      _history.add(data);
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    } catch (e) {
      // Internal error fallback: cannot log via ISpect itself without
      // re-entering this dispatch, so use dart:developer directly.
      log('[ISpect] Log dispatch failed: $e');
    } finally {
      _isDispatching = false;
    }

    if (!_options.useConsoleLogs) return;

    try {
      final level = data.logLevel ?? (data.isError ? LogLevel.error : null);
      final pen = data.pen ?? _options.penByKey(data.key);
      final settings = _consoleLogger.settings;

      final rendered = truncateString(
        settings.formatter.format(data, settings),
        maxLength: _options.logTruncateLength,
      );

      _consoleLogger.log(
        rendered,
        level: level,
        pen: pen,
        time: data.time,
        error: _options.forwardErrorToConsole
            ? data.error ?? data.exception
            : null,
        stackTrace: _options.forwardErrorToConsole
            ? truncateStackTrace(data.stackTrace)
            : null,
      );
    } catch (e) {
      // Same fallback rationale as above.
      log('[ISpect] Console logging failed: $e');
    }
  }
}
