/// Carries ISpect logs from background isolates to the main logger.
///
/// Requires `dart:isolate`, so it is not available on the web.
library;

export 'src/isolate/isolate_log_bridge.dart';
