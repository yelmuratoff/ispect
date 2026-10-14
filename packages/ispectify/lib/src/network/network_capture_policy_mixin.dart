import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/network/network_interceptor_settings.dart';
import 'package:ispectify/src/network/network_redaction_mixin.dart';
import 'package:ispectify/src/trace/trace_config.dart';

/// Capture policy shared by network interceptors whose [settings] extend
/// [BaseNetworkInterceptorSettings].
///
/// Derives [enableRedaction], [captureMode], and [resourceLimits] from
/// [settings], so an interceptor only provides its settings and logger.
mixin NetworkCapturePolicyMixin on NetworkRedactionMixin {
  /// The interceptor's current settings.
  BaseNetworkInterceptorSettings get settings;

  /// Whether the logger has an active consumer and [settings] are enabled.
  bool get captureEnabled => logger.hasActiveConsumers && settings.enabled;

  @override
  bool get enableRedaction => settings.enableRedaction;

  @override
  DiagnosticCaptureMode get captureMode => settings.captureMode;

  /// The limits set on [settings], or the attached logger's limits when unset.
  @override
  DiagnosticResourceLimits get resourceLimits =>
      settings.resourceLimits ?? logger.options.resourceLimits;

  /// Trace config for fields the interceptor already bounded and redacted.
  ///
  /// Trace-level redaction is off so the interceptor's own redaction policy is
  /// not replaced by a second generic pass; [resourceLimits] carries through.
  ISpectTraceConfig get capturedTraceConfig => ISpectTraceConfig(
        redact: false,
        resourceLimits: resourceLimits,
      );
}
