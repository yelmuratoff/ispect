import 'package:ispectify/ispectify.dart';

class ISpectiyData {
  ISpectiyData(
    this.message, {
    this.logLevel,
    this.exception,
    this.error,
    this.stackTrace,
    this.title = 'log',
    DateTime? time,
    this.pen,
    this.key,
  }) {
    _time = time ?? DateTime.now();
  }

  late DateTime _time;
  final String? message;
  final String? key;
  final LogLevel? logLevel;
  final Object? exception;
  final Error? error;
  String? title;
  final StackTrace? stackTrace;
  DateTime get time => _time;
  AnsiPen? pen;

  String generateTextMessage({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    return '${displayTitleWithTime(timeFormat: timeFormat)}$message$displayStackTrace';
  }
}

/// Extension to get
/// display text of [ISpectiyData] fields
extension FieldsToDisplay on ISpectiyData {
  /// Displayed title of [ISpectiyData]

  String displayTitleWithTime({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    return '[$title] | ${displayTime(timeFormat: timeFormat)} | ';
  }

  /// Displayed stackTrace of [ISpectiyData]
  String get displayStackTrace {
    if (stackTrace == null || stackTrace == StackTrace.empty) {
      return '';
    }
    return '\nStackTrace: $stackTrace}';
  }

  /// Displayed exception of [ISpectiyData]
  String get displayException {
    if (exception == null) {
      return '';
    }
    return '\n$exception';
  }

  /// Displayed error of [ISpectiyData]
  String get displayError {
    if (error == null) {
      return '';
    }
    return '\n$error';
  }

  /// Displayed message of [ISpectiyData]
  String get displayMessage {
    if (message == null) {
      return '';
    }
    return '$message';
  }

  /// Displayed tile of [ISpectiyData]
  String displayTime({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) =>
      TalkerDateTimeFormatter(time, timeFormat: timeFormat).format;
}
