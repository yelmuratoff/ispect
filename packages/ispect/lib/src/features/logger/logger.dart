import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract class ILogFormatter {
  const ILogFormatter();

  String format(String message, LogObject logObject, String name);
}

abstract class IColorizer {
  const IColorizer();

  String apply(String message, LogObject logObject);
}

abstract class ILoggerConfig {
  const ILoggerConfig();

  bool get showTimestamp;
  bool get showLevel;
  bool get showName;
}

class DefaultLogFormatter implements ILogFormatter {
  const DefaultLogFormatter(this.config);
  final ILoggerConfig config;

  @override
  String format(String message, LogObject logObject, String name) {
    final buffer = StringBuffer();
    final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    if (config.showTimestamp) buffer.write('| $dateTime');
    if (config.showLevel) buffer.write(' | ${logObject.title} | ');
    if (config.showName && name.isNotEmpty) buffer.write('| $name] | ');
    buffer.write(message);
    return buffer.toString();
  }
}

class DefaultColorizer implements IColorizer {
  const DefaultColorizer();

  @override
  String apply(String message, LogObject logObject) => '${logObject.colorCode}$message\x1B[0m';
}

class DefaultLoggerConfig implements ILoggerConfig {
  const DefaultLoggerConfig({
    this.showTimestamp = true,
    this.showLevel = true,
    this.showName = true,
  });
  @override
  final bool showTimestamp;

  @override
  final bool showLevel;

  @override
  final bool showName;
}

class Logger {
  Logger({
    this.name = '',
    this.formatter = const DefaultLogFormatter(DefaultLoggerConfig()),
    this.colorizer = const DefaultColorizer(),
    this.customLogs = const {},
  });

  final String name;
  final ILogFormatter formatter;
  final IColorizer colorizer;
  final Map<String, LogObject> customLogs;

  void log(String message, {LogObject logObject = const InfoLog()}) {
    final formattedMessage = formatter.format(message, logObject, name);
    final coloredMessage = colorizer.apply(formattedMessage, logObject);

    if (_isAnsiSupported()) {
      debugPrint(coloredMessage);
    } else {
      developer.log(
        coloredMessage,
        name: name,
      );
    }
  }

  bool _isAnsiSupported() => stdout.supportsAnsiEscapes;
}

/// Base class for log objects
abstract class LogObject {
  const LogObject();

  String get title;

  String get colorCode;
}

class InfoLog extends LogObject {
  const InfoLog();

  @override
  String get title => 'INFO';

  @override
  String get colorCode => '\x1B[32m';
}

class WarningLog extends LogObject {
  const WarningLog();

  @override
  String get title => 'WARNING';

  @override
  String get colorCode => '\x1B[33m';
}

class ErrorLog extends LogObject {
  const ErrorLog();

  @override
  String get title => 'ERROR';

  @override
  String get colorCode => '\x1B[31m';
}

class SuccessLog extends LogObject {
  const SuccessLog();

  @override
  String get title => 'SUCCESS';

  @override
  String get colorCode => '\x1B[32m';
}
