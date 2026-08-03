import 'package:ispectify/ispectify.dart';
import 'package:riverpod/riverpod.dart';

/// Returns the concrete provider class name, falling back to `Provider`.
///
/// [DiagnosticCaptureMode.strict] never dispatches through the overridable
/// `runtimeType` getter.
String safeRiverpodProviderTypeLabel(
  ProviderBase<Object?> provider, {
  DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) =>
    describeRuntimeType(
      provider,
      captureMode: captureMode,
      resourceLimits: resourceLimits,
      fallback: 'Provider',
    );

/// Returns the concrete value class name, falling back to a coarse family.
///
/// [DiagnosticCaptureMode.strict] collapses unknown caller-owned objects to
/// `Object` rather than reading the overridable `runtimeType` getter.
String safeRiverpodValueTypeLabel(
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
