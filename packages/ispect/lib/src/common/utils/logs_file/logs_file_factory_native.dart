import 'package:ispect/src/common/utils/logs_file/base_logs_file.dart';
import 'package:ispect/src/common/utils/logs_file/native_logs_file.dart';

/// Native-specific factory implementation.
BaseLogsFile createPlatformLogsFile() => NativeLogsFile();
