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
