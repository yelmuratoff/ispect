import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Returns a non-dispatching descriptor for an arbitrary diagnostic object.
///
/// Diagnostics can implement SDK interfaces and override `runtimeType`,
/// `toString`, and detail getters. Type tests are safe, while reading those
/// members is not. The descriptor therefore retains only a coarse type family
/// and never caller-supplied diagnostic text.
String safeDiagnosticDescriptor(Object value) =>
    JsonValueNormalizer.diagnosticDescriptor(value);

/// Returns the concrete class name of [value], bounded by [resourceLimits].
///
/// `runtimeType` is an overridable getter, so [DiagnosticCaptureMode.balanced]
/// dispatches into caller code to read it while
/// [DiagnosticCaptureMode.strict] does not. Returns [fallback] under strict
/// capture, for a null [value], and when the getter throws or yields an empty
/// name.
String describeRuntimeType(
  Object? value, {
  required DiagnosticCaptureMode captureMode,
  required String fallback,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) {
  if (value == null || captureMode != DiagnosticCaptureMode.balanced) {
    return fallback;
  }
  try {
    final name = value.runtimeType.toString().trim();
    if (name.isEmpty) return fallback;
    return LogExportOutput.truncateUtf8(
      name,
      maxBytes: resourceLimits.maxCapturedValueBytes,
    );
  } on Object {
    return fallback;
  }
}

/// Returns the concrete class name of [value], falling back to a coarse type
/// family.
///
/// [DiagnosticCaptureMode.strict] collapses unknown caller-owned objects to
/// `Object` rather than reading the overridable `runtimeType` getter.
String safeValueTypeLabel(
  Object? value, {
  DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) =>
    describeRuntimeType(
      value,
      captureMode: captureMode,
      resourceLimits: resourceLimits,
      fallback: _valueFamilyLabel(value),
    );

String _valueFamilyLabel(Object? value) {
  if (value == null) return 'null';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is num) return 'num';
  if (value is Enum) return 'Enum';
  if (value is Map) return 'Map';
  if (value is List) return 'List';
  if (value is Set) return 'Set';
  if (value is Iterable) return 'Iterable';
  if (value is Error) return 'Error';
  if (value is Exception) return 'Exception';
  if (value is StackTrace) return 'StackTrace';
  if (value is Type) return 'Type';
  if (value is Record) return 'Record';
  return 'Object';
}

/// Converts only closed, non-dispatching scalar families to text.
///
/// Unknown objects deliberately become an opaque marker instead of invoking a
/// caller-controlled formatter.
String? safeScalarText(Object? value) => switch (value) {
      null => null,
      final String text => text,
      final bool primitive => primitive ? 'true' : 'false',
      final num primitive => primitive.toString(),
      final Enum primitive => primitive.name,
      _ => JsonValueNormalizer.unprintableValue,
    };
