import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';

/// Returns the concrete BLoC class name, falling back to its family label.
///
/// [DiagnosticCaptureMode.strict] never dispatches through the overridable
/// `runtimeType` getter and yields `Bloc`, `Cubit`, or `BlocBase`.
String safeBlocTypeLabel(
  BlocBase<dynamic> bloc, {
  DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) =>
    describeRuntimeType(
      bloc,
      captureMode: captureMode,
      resourceLimits: resourceLimits,
      fallback: _blocFamilyLabel(bloc),
    );

String _blocFamilyLabel(BlocBase<dynamic> bloc) {
  if (bloc is Bloc<dynamic, dynamic>) return 'Bloc';
  if (bloc is Cubit<dynamic>) return 'Cubit';
  return 'BlocBase';
}

/// Returns the concrete value class name, falling back to a coarse family.
///
/// [DiagnosticCaptureMode.strict] collapses unknown caller-owned objects to
/// `Object` rather than reading the overridable `runtimeType` getter.
String safeBlocValueTypeLabel(
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
