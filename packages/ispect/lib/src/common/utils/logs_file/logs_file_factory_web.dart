import 'package:ispect/src/common/utils/logs_file/base_logs_file.dart';
import 'package:ispect/src/common/utils/logs_file/web_logs_file.dart';

/// Web-specific factory implementation.
BaseLogsFile createPlatformLogsFile() => WebLogsFile();
