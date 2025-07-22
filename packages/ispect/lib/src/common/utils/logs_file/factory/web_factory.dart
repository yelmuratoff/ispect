import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:ispect/src/common/utils/logs_file/implementations/web_logs_file.dart';

/// Web-specific factory implementation.
BaseLogsFile createPlatformLogsFile() => WebLogsFile();
