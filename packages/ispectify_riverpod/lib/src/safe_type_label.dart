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
