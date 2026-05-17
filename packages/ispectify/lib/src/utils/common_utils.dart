import 'dart:math';

import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';

/// Returns [stackTrace] as-is unless it is `null` or [StackTrace.empty],
/// in which case `null` is returned.
///
/// Some frameworks pass [StackTrace.empty] instead of `null`, and logging
/// an empty stack trace adds noise.
StackTrace? normalizeStackTrace(StackTrace? stackTrace) =>
    stackTrace != null && stackTrace != StackTrace.empty ? stackTrace : null;

/// Removes entries with `null` values or empty-string values from [map].
///
/// Returns a new map containing only entries where the value is non-null
/// and (if a [String]) non-empty.
Map<String, Object?> cleanMap(Map<String, Object?> map) {
  final out = <String, Object?>{};
  map.forEach((k, v) {
    if (v == null) return;
    if (v is String && v.isEmpty) return;
    out[k] = v;
  });
  return out;
}

/// Returns `true` when the operation should proceed based on a probabilistic
/// sampling rate.
///
/// - `null` or `>= 1.0` → always passes (returns `true`).
/// - `<= 0.0` → never passes (returns `false`).
/// - Otherwise, passes with the given probability.
bool samplePass(double? rate) {
  if (rate == null) return true;
  if (rate <= 0) return false;
  if (rate >= 1) return true;
  return _random.nextDouble() < rate;
}

final Random _random = _createRandom();

Random _createRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}

/// Formats a byte count as a human-readable string (B, KB, MB, GB).
String formatBytes(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(1)} GB';
}

/// Generates a 16-character hex trace ID from the current timestamp
/// and a random component.
///
/// Not cryptographically secure — suitable for log correlation only.
String generateTraceId() {
  const timestampMask = 0xffffffff;
  const randomBound = 0x7fffffff;
  const hexPadLen = 8;

  final now = DateTime.now().microsecondsSinceEpoch;
  final r = _random.nextInt(randomBound);

  return (now & timestampMask).toRadixString(16).padLeft(hexPadLen, '0') +
      r.toRadixString(16).padLeft(hexPadLen, '0');
}

/// Extension on [ISpectLogger] providing safe logging helpers.
extension SafeLogExtension on ISpectLogger {
  /// Logs [data] inside a try-catch, preventing logger exceptions from
  /// propagating into the caller's framework.
  void safeLogData(ISpectLogData data) {
    try {
      logData(data);
    } catch (_) {
      // Prevent logging failure from propagating.
    }
  }
}
