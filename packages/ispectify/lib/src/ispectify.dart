import 'dart:async';

import 'package:ispectify/ispectify.dart';

class ISpectiy {
  ISpectiy({
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyOptions? options,
    ISpectifyFilter? filter,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  }) {
    _init(filter, options, logger, observer, errorHandler, history);
  }

  void _init(
    ISpectifyFilter? filter,
    ISpectifyOptions? settings,
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  ) {
    _filter = filter;
    this.settings = settings ?? ISpectifyOptions();
    _initLogger(logger);
    _observer = observer;
    _errorHandler = errorHandler ?? ISpectifyErrorHandler(this.settings);
    _history = history ?? DefaultISpectifyHistory(this.settings);
  }

  void _initLogger(ISpectifyLogger? logger) {
    _logger = logger ?? ISpectifyLogger();
    _logger = _logger.copyWith(
      settings: _logger.settings.copyWith(
        colors: {
          LogLevel.critical: settings.penByKey(ISpectifyLogType.critical.key),
          LogLevel.error: settings.penByKey(ISpectifyLogType.error.key),
          LogLevel.warning: settings.penByKey(ISpectifyLogType.warning.key),
          LogLevel.verbose: settings.penByKey(ISpectifyLogType.verbose.key),
          LogLevel.info: settings.penByKey(ISpectifyLogType.info.key),
          LogLevel.debug: settings.penByKey(ISpectifyLogType.debug.key),
        },
      ),
    );
  }

  late ISpectifyOptions settings;
  late ISpectifyLogger _logger;
  late ISpectifyErrorHandler _errorHandler;
  late ISpectifyFilter? _filter;
  late ISpectifyObserver? _observer;
  late LogHistory _history;

  void configure({
    ISpectifyLogger? logger,
    ISpectifyOptions? settings,
    ISpectifyObserver? observer,
    ISpectifyFilter? filter,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  }) {
    if (filter != null) {
      _filter = filter;
    }
    if (settings != null) {
      this.settings = settings;
    }
    _observer = observer ?? _observer;
    _logger = logger ?? _logger;
    _errorHandler = errorHandler ?? ISpectifyErrorHandler(this.settings);
    _history = DefaultISpectifyHistory(this.settings, history: _history.history);
  }

  final _iSpectifyStreamController = StreamController<ISpectiyData>.broadcast();

  Stream<ISpectiyData> get stream => _iSpectifyStreamController.stream.asBroadcastStream();

  List<ISpectiyData> get history => _history.history;

  void handle(
    Object exception, [
    StackTrace? stackTrace,
    dynamic msg,
  ]) {
    final data = _errorHandler.handle(exception, stackTrace, msg?.toString());
    if (data is ISpectifyError) {
      _observer?.onError(data);
      _handleErrorData(data);
      return;
    }
    if (data is ISpectifyException) {
      _observer?.onException(data);
      _handleErrorData(data);
      return;
    }
    if (data is ISpectifyLog) {
      _handleLogData(data);
    }
  }

  void log(
    dynamic message, {
    LogLevel logLevel = LogLevel.debug,
    Object? exception,
    StackTrace? stackTrace,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: message,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: logLevel,
      pen: pen,
    );
  }

  void logCustom(ISpectifyLog log) => _handleLogData(log);

  void critical(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.critical,
    );
  }

  void debug(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  void error(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.error,
    );
  }

  void info(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.info,
    );
  }

  void verbose(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.verbose,
    );
  }

  void warning(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.warning,
    );
  }

  void clearHistory() => _history.clear();

  void enable() => settings.enabled = true;

  void disable() => settings.enabled = false;

  void _handleLog({
    Object? message,
    Object? exception,
    StackTrace? stackTrace,
    LogLevel? logLevel,
    AnsiPen? pen,
  }) {
    final type = ISpectifyLogType.fromLogLevel(logLevel);
    final data = ISpectifyLog(
      key: type.key,
      message?.toString() ?? '',
      title: settings.titleByKey(type.key),
      exception: exception,
      stackTrace: stackTrace,
      pen: pen ?? settings.penByKey(type.key),
      logLevel: logLevel,
    );
    _handleLogData(data);
  }

  void _handleErrorData(ISpectiyData data) {
    if (!settings.enabled) {
      return;
    }
    final isApproved = _isApprovedByFilter(data);
    if (!isApproved) {
      return;
    }
    _iSpectifyStreamController.add(data);
    _handleForOutputs(data);
    if (settings.useConsoleLogs) {
      _logger.log(
        '${data.header}${data.textMessage}',
        level: data.logLevel ?? LogLevel.error,
      );
    }
  }

  void _handleLogData(
    ISpectifyLog data, {
    LogLevel? logLevel,
  }) {
    if (!settings.enabled) {
      return;
    }

    final isApproved = _isApprovedByFilter(data);
    if (!isApproved) {
      return;
    }

    _observer?.onLog(data);
    _iSpectifyStreamController.add(data);
    _handleForOutputs(data);
    if (settings.useConsoleLogs) {
      _logger.log(
        '${data.header}${data.textMessage}',
        level: logLevel ?? data.logLevel,
        pen: data.pen ?? settings.penByKey(data.key),
      );
    }
  }

  void _handleForOutputs(ISpectiyData data) {
    _history.add(data);
  }

  bool _isApprovedByFilter(ISpectiyData data) {
    final approved = _filter?.filter(data);
    return approved ?? true;
  }
}
