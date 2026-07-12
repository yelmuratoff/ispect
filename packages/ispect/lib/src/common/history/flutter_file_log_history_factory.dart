import 'package:flutter/foundation.dart';
import 'package:ispect/src/core/platform/platform_directory.dart';
import 'package:ispectify/ispectify.dart';

FileLogHistory? createFlutterFileLogHistory({
  required ISpectLoggerOptions loggerOptions,
  required FileLogHistoryOptions fileHistoryOptions,
  FileLogDirectoryProvider? directoryProvider,
  bool isEnabled = kISpectEnabled,
  bool isWeb = kIsWeb,
}) {
  if (!isEnabled || isWeb) return null;
  return RollingFileLogHistory(
    loggerOptions,
    options: fileHistoryOptions,
    directoryProvider:
        directoryProvider ?? platformDirectoryProvider.cacheDirectoryPath,
  );
}
