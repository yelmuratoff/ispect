import 'package:ispectify/ispectify.dart';

enum ISpectifyLogType {
  error('error'),
  critical('critical'),
  info('info'),
  debug('debug'),
  verbose('verbose'),
  warning('warning'),
  exception('exception'),

  httpError('http-error'),
  httpRequest('http-request'),
  httpResponse('http-response'),

  blocEvent('bloc-event'),
  blocTransition('bloc-transition'),
  blocClose('bloc-close'),
  blocCreate('bloc-create'),

  riverpodAdd('riverpod-add'),
  riverpodUpdate('riverpod-update'),
  riverpodDispose('riverpod-dispose'),
  riverpodFail('riverpod-fail'),

  route('route');

  const ISpectifyLogType(this.key);
  final String key;

  static ISpectifyLogType fromLogLevel(LogLevel logLevel) {
    return ISpectifyLogType.values.firstWhere((e) => e.level == logLevel);
  }

  static ISpectifyLogType? fromKey(String key) {
    return ISpectifyLogType.values.firstWhereOrNull((e) => e.key == key);
  }
}

extension ISpectifyLogTypeExt on ISpectifyLogType {
  LogLevel get level {
    return switch (this) {
      ISpectifyLogType.error => LogLevel.error,
      ISpectifyLogType.critical => LogLevel.critical,
      ISpectifyLogType.info => LogLevel.info,
      ISpectifyLogType.debug => LogLevel.debug,
      ISpectifyLogType.verbose => LogLevel.verbose,
      ISpectifyLogType.warning => LogLevel.warning,
      _ => LogLevel.debug,
    };
  }
}
