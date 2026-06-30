import 'package:ispect/src/common/utils/logs_file/base/base_logs_file.dart';

/// Default import branch, used when neither `dart:io` nor `dart:js_interop` is
/// available — never selected on a real target. It exists so the default import
/// path carries no platform imports, which WASM/platform analysis requires.
BaseLogsFile createPlatformLogsFile() => throw UnsupportedError(
      'No platform implementation of LogsFile is available for this runtime.',
    );
