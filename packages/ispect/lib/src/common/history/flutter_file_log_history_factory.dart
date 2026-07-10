import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';
import 'package:path_provider/path_provider.dart';

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
    directoryProvider: directoryProvider ??
        () async {
          final directory = await getApplicationCacheDirectory();
          return directory.path;
        },
  );
}
