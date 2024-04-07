import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum TalkerLogType {
  /// Base logs section
  error('error'),
  critical('critical'),
  info('info'),
  debug('debug'),
  verbose('verbose'),
  warning('warning'),
  exception('exception'),
  good('good'),
  provider('provider'),

  /// Http section
  httpError('http-error'),
  httpRequest('http-request'),
  httpResponse('http-response'),

  /// Bloc section
  blocEvent('bloc-event'),
  blocTransition('bloc-transition'),
  blocClose('bloc-close'),
  blocCreate('bloc-create'),

  /// Flutter section
  route('route');

  const TalkerLogType(this.key);
  final String key;

  static TalkerLogType fromLogLevel(LogLevel logLevel) =>
      TalkerLogType.values.firstWhere((e) => e.logLevel == logLevel);

  static TalkerLogType fromKey(String key) =>
      TalkerLogType.values.firstWhere((e) => e.key == key);
}

extension TalkerTalkerLogTypeExt on TalkerLogType {
  /// Mapping [TalkerLogType] into [LogLevel]
  LogLevel get logLevel {
    switch (this) {
      case TalkerLogType.error:
        return LogLevel.error;
      case TalkerLogType.critical:
        return LogLevel.critical;
      case TalkerLogType.info:
        return LogLevel.info;
      case TalkerLogType.debug:
        return LogLevel.debug;
      case TalkerLogType.verbose:
        return LogLevel.verbose;
      case TalkerLogType.warning:
        return LogLevel.warning;
      default:
        return LogLevel.debug;
    }
  }
}

extension ColorDataFlutterExt on TalkerData {
  Color getTypeColor(TalkerScreenTheme theme) {
    // final colorFromAnsi = _getColorFromAnsi();
    // if (colorFromAnsi != null) return logsColors.colorFromAnsi;

    final key = this.key;

    if (key == null) return Colors.grey;
    final type = TalkerLogType.fromKey(key);
    return _typeColors[type] ?? Colors.grey;
  }
}

const _typeColors = {
  /// Base logs section
  TalkerLogType.error: Color.fromARGB(255, 239, 83, 80),
  TalkerLogType.critical: Color.fromARGB(255, 198, 40, 40),
  TalkerLogType.info: Color.fromARGB(255, 66, 165, 245),
  TalkerLogType.debug: Color.fromARGB(255, 158, 158, 158),
  TalkerLogType.verbose: Color.fromARGB(255, 189, 189, 189),
  TalkerLogType.warning: Color.fromARGB(255, 239, 108, 0),
  TalkerLogType.exception: Color.fromARGB(255, 239, 83, 80),
  TalkerLogType.good: Color.fromARGB(255, 120, 230, 129),
  TalkerLogType.provider: Color.fromARGB(255, 120, 180, 190),

  /// Http section
  TalkerLogType.httpError: Color.fromARGB(255, 239, 83, 80),
  TalkerLogType.httpRequest: Color(0xFFF602C1),
  TalkerLogType.httpResponse: Color(0xFF26FF3C),

  /// Bloc section
  TalkerLogType.blocEvent: Color(0xFF63FAFE),
  TalkerLogType.blocTransition: Color(0xFF56FEA8),
  TalkerLogType.blocClose: Color(0xFFFF005F),
  TalkerLogType.blocCreate: Color.fromARGB(255, 120, 230, 129),

  /// Flutter section
  TalkerLogType.route: Color(0xFFAF5FFF),
};
