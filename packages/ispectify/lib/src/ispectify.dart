import 'dart:async';

import 'package:ispectify/ispectify.dart';

class ISpectiy {
  ISpectiy({
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyOptions? settings,
    ISpectifyFilter? filter,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  }) {
    _init(filter, settings, logger, observer, errorHandler, history);
  }

  void _init(
    ISpectifyFilter? filter,
    ISpectifyOptions? settings,
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  ) {
    _filter = filter ?? _DefaultTalkerFilter();
    this.settings = settings ?? ISpectifyOptions();
    _initLogger(logger);
    _observer = observer ?? const _DefaultTalkerObserver();
    _errorHandler = errorHandler ?? ISpectifyErrorHandler(this.settings);
    _history = history ?? DefaultTalkerHistory(this.settings);
  }

  void _initLogger(ISpectifyLogger? logger) {
    _logger = logger ?? ISpectifyLogger();
    _logger = _logger.copyWith(
      settings: _logger.settings.copyWith(
        colors: {
          LogLevel.critical: settings.getAnsiPenByLogType(ISpectifyLogType.critical),
          LogLevel.error: settings.getAnsiPenByLogType(ISpectifyLogType.error),
          LogLevel.warning: settings.getAnsiPenByLogType(ISpectifyLogType.warning),
          LogLevel.verbose: settings.getAnsiPenByLogType(ISpectifyLogType.verbose),
          LogLevel.info: settings.getAnsiPenByLogType(ISpectifyLogType.info),
          LogLevel.debug: settings.getAnsiPenByLogType(ISpectifyLogType.debug),
        },
      ),
    );
  }

  late ISpectifyOptions settings;
  late ISpectifyLogger _logger;
  late ISpectifyErrorHandler _errorHandler;
  late ISpectifyFilter _filter;
  late ISpectifyObserver _observer;
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
    _history = DefaultTalkerHistory(this.settings, history: _history.history);
  }

  final _talkerStreamController = StreamController<ISpectiyData>.broadcast();

  Stream<ISpectiyData> get stream => _talkerStreamController.stream.asBroadcastStream();

  List<ISpectiyData> get history => _history.history;

  void handle(
    Object exception, [
    StackTrace? stackTrace,
    dynamic msg,
  ]) {
    final data = _errorHandler.handle(exception, stackTrace, msg?.toString());
    if (data is TalkerError) {
      _observer.onError(data);
      _handleErrorData(data);
      return;
    }
    if (data is TalkerException) {
      _observer.onException(data);
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
    _handleLog(message, exception, stackTrace, logLevel, pen: pen);
  }

  void logCustom(ISpectifyLog log) => _handleLogData(log);

  void critical(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(msg, exception, stackTrace, LogLevel.critical);
  }

  void debug(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(msg, exception, stackTrace, LogLevel.debug);
  }

  void error(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(msg, exception, stackTrace, LogLevel.error);
  }

  void info(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(msg, exception, stackTrace, LogLevel.info);
  }

  void verbose(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(msg, exception, stackTrace, LogLevel.verbose);
  }

  void warning(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _handleLog(msg, exception, stackTrace, LogLevel.warning);
  }

  void clearHistory() => _history.clear();

  void enable() => settings.enabled = true;

  void disable() => settings.enabled = false;

  void _handleLog(
    dynamic message,
    Object? exception,
    StackTrace? stackTrace,
    LogLevel logLevel, {
    AnsiPen? pen,
  }) {
    final type = ISpectifyLogType.fromLogLevel(logLevel);
    final data = ISpectifyLog(
      key: type.key,
      message?.toString() ?? '',
      title: settings.getTitleByLogKey(type.key),
      exception: exception,
      stackTrace: stackTrace,
      pen: pen ?? settings.getPenByLogKey(type.key),
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
    _talkerStreamController.add(data);
    _handleForOutputs(data);
    if (settings.useConsoleLogs) {
      _logger.log(
        data.generateTextMessage(timeFormat: settings.timeFormat),
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

    final logTypeKey = data.key;
    if (logTypeKey != null) {
      data.title = settings.getTitleByLogKey(logTypeKey);
      data.pen = settings.getPenByLogKey(
        logTypeKey,
        fallbackPen: data.pen,
      );
    }
    _observer.onLog(data);
    _talkerStreamController.add(data);
    _handleForOutputs(data);
    if (settings.useConsoleLogs) {
      _logger.log(
        data.generateTextMessage(timeFormat: settings.timeFormat),
        level: logLevel ?? data.logLevel,
        pen: data.pen,
      );
    }
  }

  void _handleForOutputs(ISpectiyData data) {
    _history.add(data);
  }

  bool _isApprovedByFilter(ISpectiyData data) {
    final approved = _filter.filter(data);
    return approved;
  }
}

class _DefaultTalkerObserver extends ISpectifyObserver {
  const _DefaultTalkerObserver();
}

class _DefaultTalkerFilter extends ISpectifyFilter {
  @override
  bool filter(ISpectiyData item) => true;
}
