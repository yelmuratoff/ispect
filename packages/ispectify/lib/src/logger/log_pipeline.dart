import 'dart:async';
import 'dart:developer';

import 'package:ispectify/src/filter/filter.dart';
import 'package:ispectify/src/history/history.dart';
import 'package:ispectify/src/logger/logger.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/options.dart';
import 'package:ispectify/src/utils/safe_object_description.dart';
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

  /// Whether the active filter rejects [key] outright, so the caller can skip
  /// capture and redaction for an entry that would be dropped anyway.
  bool vetoesKey(String? key) {
    final filter = _filter;
    return filter is ISpectFilter && filter.vetoesKey(key);
  }

  bool shouldProcess(ISpectLogData data) {
    if (!_options.enabled) return false;
    try {
      return _filter?.apply(data) ?? true;
    } catch (error) {
      final type = describeRuntimeType(
        error,
        captureMode: _options.captureMode,
        fallback: 'unknown error',
      );
      log('[ISpect] Filter threw $type; entry dropped.');
      return false;
    }
  }

  bool get usesConsoleLogs => _options.useConsoleLogs;

  bool get hasStreamListeners => _streamController.hasListener;

  bool get hasDispatchTarget {
    if (usesConsoleLogs || hasStreamListeners) return true;
    if (_history.runtimeType != DefaultISpectLoggerHistory) return true;
    final history = _history as DefaultISpectLoggerHistory;
    return history.settings.useHistory && history.settings.maxHistoryItems > 0;
  }

  /// Guards against re-entrant dispatch (e.g. a listener that logs).
  ///
  /// Safe in Dart's single-threaded event loop: only one synchronous call
  /// chain can execute at a time, so no atomic/lock is needed.
  bool _isDispatching = false;

  void dispatch(
    ISpectLogData data, {
    ISpectLogData? historyData,
    ISpectLogData? streamData,
    ISpectLogData? consoleData,
  }) {
    if (_isDispatching) return;
    _isDispatching = true;
    try {
      // Add to history BEFORE emitting to stream so that listeners
      // (e.g. StreamBuilder) see the new entry when they read history.
      _history.add(historyData ?? data);
      if (!_streamController.isClosed) {
        _streamController.add(streamData ?? data);
      }
    } catch (_) {
      // Internal error fallback: cannot log via ISpect itself without
      // re-entering this dispatch, so use dart:developer directly.
      log('[ISpect] Log dispatch failed safely.');
    } finally {
      _isDispatching = false;
    }

    if (!_options.useConsoleLogs) return;

    try {
      final outboundData = consoleData ?? data;
      final level = outboundData.logLevel ??
          (outboundData.isError ? LogLevel.error : null);
      final pen = outboundData.pen ?? _options.penByKey(outboundData.key);
      final settings = _consoleLogger.settings;

      final rendered = truncateString(
        settings.formatter.format(outboundData, settings),
        maxLength: _options.logTruncateLength,
      );

      _consoleLogger.log(
        rendered,
        level: level,
        pen: pen,
        time: outboundData.time,
        error: _options.forwardErrorToConsole
            ? outboundData.error ?? outboundData.exception
            : null,
        stackTrace: _options.forwardErrorToConsole
            ? truncateStackTrace(
                outboundData.stackTrace,
                maxFrames: _options.resourceLimits.maxConsoleStackTraceFrames,
              )
            : null,
      );
    } catch (_) {
      // Same fallback rationale as above.
      log('[ISpect] Console logging failed safely.');
    }
  }
}
