import 'package:flutter/foundation.dart';

/// Reports a background failure in debug builds only.
///
/// Release builds stay silent: the failure is already contained and the
/// diagnostics toolkit must not emit output of its own there.
void debugReportFailure(String context, Object error) {
  assert(() {
    debugPrint('$context: $error');
    return true;
  }());
}
