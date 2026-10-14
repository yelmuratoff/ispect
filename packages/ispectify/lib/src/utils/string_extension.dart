import 'dart:collection';

import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Default truncation limit for strings across the package.
const int kDefaultStringTruncateLimit = 10000;

/// Default maximum stack frames passed to the console logger.
///
/// Frames beyond this limit are dropped from the console view; the full
/// trace is still stored in [ISpectLogData.stackTrace] and visible in the
/// ISpect UI.
const int kDefaultStackFrameLimit = 30;

/// Truncates [stackTrace] to [maxFrames] frames while keeping it a proper
/// [StackTrace] so that tools like Flutter DevTools can still parse and
/// display clickable frame links.
///
/// Returns the original object when it is already within the limit, so no
/// allocation occurs in the common case.
StackTrace? truncateStackTrace(
  StackTrace? stackTrace, {
  int maxFrames = kDefaultStackFrameLimit,
}) {
  if (stackTrace == null) return null;
  final lines = stackTrace
      .toString()
      .split('\n')
      .where((l) => l.isNotEmpty)
      .toList(growable: false);
  if (lines.length <= maxFrames) return stackTrace;
  final truncated = [
    ...lines.take(maxFrames),
    '... (${lines.length - maxFrames} more frames)',
  ].join('\n');
  return StackTrace.fromString(truncated);
}

/// Matches standard ANSI SGR / cursor escape sequences.
final RegExp ansiEscapePattern = RegExp(r'\x1B\[[0-9;]*[mGKH]');

/// Returns [value] with all ANSI escape sequences removed.
String stripAnsi(String value) => value.replaceAll(ansiEscapePattern, '');

/// Returns `true` if [value] contains any ANSI escape sequence.
bool containsAnsi(String value) => value.contains(ansiEscapePattern);

/// Truncates [value] to [maxLength], avoiding surrogate pair splits.
///
/// Appends `...` if the string was truncated.
String truncateString(
  String value, {
  int maxLength = kDefaultStringTruncateLimit,
}) {
  if (value.length <= maxLength) return value;
  var end = maxLength;
  // Avoid splitting a surrogate pair at the truncation boundary.
  if (end > 0 &&
      value.codeUnitAt(end - 1) >= 0xD800 &&
      value.codeUnitAt(end - 1) <= 0xDBFF) {
    end--;
  }
  return '${value.substring(0, end)}...';
}

/// Recursively truncates string leaves in nested [Map]/[Iterable] structures.
///
/// Non-string, non-collection values pass through unchanged.
/// Returns `null` for `null` input.
///
/// A collection nested [maxDepth] levels deep (default
/// [DiagnosticResourceLimits.maxTraversalDepth] of
/// [DiagnosticResourceLimits.balanced]) is replaced with
/// [JsonValueNormalizer.maxDepthReached], and a collection that contains
/// itself with [JsonValueNormalizer.circularReference].
Object? truncateLeaves(
  Object? input, {
  required int maxLength,
  int? maxDepth,
}) =>
    _truncateLeaves(
      input,
      maxLength: maxLength,
      depth: 0,
      maxDepth: maxDepth ?? DiagnosticResourceLimits.balanced.maxTraversalDepth,
      ancestors: HashSet<Object>.identity(),
    );

Object? _truncateLeaves(
  Object? input, {
  required int maxLength,
  required int depth,
  required int maxDepth,
  required Set<Object> ancestors,
}) {
  if (input == null) return null;
  if (input is String) return truncateString(input, maxLength: maxLength);
  if (input is! Map && input is! Iterable) return input;
  if (depth >= maxDepth) return JsonValueNormalizer.maxDepthReached;
  if (!ancestors.add(input)) return JsonValueNormalizer.circularReference;
  Object? child(Object? value) => _truncateLeaves(
        value,
        maxLength: maxLength,
        depth: depth + 1,
        maxDepth: maxDepth,
        ancestors: ancestors,
      );
  try {
    if (input is Map) {
      return input.map((k, v) => MapEntry(k.toString(), child(v)));
    }
    return (input as Iterable<Object?>).map(child).toList();
  } finally {
    ancestors.remove(input);
  }
}

/// An extension on nullable [String] providing truncation.
extension ISpectStringExtension on String? {
  /// Truncates the string to [maxLength] characters.
  ///
  /// Returns `null` if the original string is `null`.
  /// Appends `...` if the string was truncated.
  String? truncate({int maxLength = kDefaultStringTruncateLimit}) {
    final original = this;
    if (original == null) return null;
    return truncateString(original, maxLength: maxLength);
  }
}
