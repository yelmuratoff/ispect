enum LogLevel {
  critical,
  error,
  warning,
  info,
  debug,
  verbose,
}

extension LogLevelX on LogLevel {
  int get developerLevel {
    switch (this) {
      case LogLevel.verbose:
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
}
