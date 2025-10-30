import 'dart:async';

import 'package:ispectify/src/filter/filter.dart';
import 'package:ispectify/src/history/history.dart';
import 'package:ispectify/src/logger/logger.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/theme/options.dart';
import 'package:ispectify/src/utils/string_extension.dart';

/// Coordinates the flow of `ISpectLogData` through the logger pipeline.
///
/// This type centralizes the side-effects that happen when a log is accepted:
/// - fan-out through the public stream
/// - persisting into history
/// - forwarding to the console logger
///
/// `ISpectLogger` owns an instance of this class and updates it whenever
/// dependencies change during `configure`.
class LogPipeline {
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

  bool shouldProcess(ISpectLogData data) {
    if (!_options.enabled) return false;
    return _filter?.apply(data) ?? true;
  }

  void dispatch(ISpectLogData data) {
    _streamController.add(data);
    _history.add(data);

    if (!_options.useConsoleLogs) return;

    final level = data.logLevel ?? (data.isError ? LogLevel.error : null);
    final pen = data.pen ?? _options.penByKey(data.key);

    _consoleLogger.log(
      '${data.header}${data.textMessage}'.truncate(
        maxLength: _options.logTruncateLength,
      ),
      level: level,
      pen: pen,
    );
  }
}
