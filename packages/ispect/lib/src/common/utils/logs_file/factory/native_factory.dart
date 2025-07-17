import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';
import 'package:ispect/src/common/utils/logs_file/implementations/native_logs_file.dart';

/// Native-specific factory implementation.
BaseLogsFile createPlatformLogsFile() => NativeLogsFile();
