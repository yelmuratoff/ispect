import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/safe_type_label.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

typedef ISpectRiverpodProviderFilter = bool Function(
  ProviderBase<Object?> provider,
);

typedef ISpectRiverpodUpdateFilter = bool Function(
  ProviderBase<Object?> provider,
  Object? previousValue,
  Object? newValue,
);

/// Configuration settings for controlling Riverpod provider lifecycle logging.
@immutable
class ISpectRiverpodSettings {
  /// Creates an instance of `ISpectRiverpodSettings`.
  const ISpectRiverpodSettings({
    this.enabled = true,
    this.printAdds = true,
    this.printUpdates = true,
    this.printDisposes = true,
    this.printFails = true,
    this.printValues = true,
    this.providerFilter,
    this.updateFilter,
    this.enableRedaction = true,
    this.redactor,
    this.captureMode = DiagnosticCaptureMode.balanced,
    this.resourceLimits,
  });

  /// Turns off all logging.
  static const ISpectRiverpodSettings silent =
      ISpectRiverpodSettings(enabled: false);

  /// Logs lifecycle creation, disposal, and failures, but skips per-update noise.
  static const ISpectRiverpodSettings minimal = ISpectRiverpodSettings(
    printUpdates: false,
  );

  /// Reduces values to a coarse type label only. Useful when provider state
  /// may carry PII and the project still wants lifecycle visibility.
  static const ISpectRiverpodSettings compact = ISpectRiverpodSettings(
    printValues: false,
    captureMode: DiagnosticCaptureMode.strict,
  );

  /// Captures full redacted provider values.
  static const ISpectRiverpodSettings verbose = ISpectRiverpodSettings();

  /// Alias for [verbose].
  static const ISpectRiverpodSettings development = verbose;

  /// Whether logging is enabled.
  final bool enabled;

  /// Whether to log provider initialization (`didAddProvider`).
  final bool printAdds;

  /// Whether to log provider updates (`didUpdateProvider`).
  final bool printUpdates;

  /// Whether to log provider disposal (`didDisposeProvider`).
  final bool printDisposes;

  /// Whether to log provider failures (`providerDidFail`).
  final bool printFails;

  /// Whether to log full provider values instead of a coarse type label.
  ///
  /// Defaults to `true`; values remain bounded and redacted by default.
  /// Use [compact] to retain type metadata only.
  final bool printValues;

  /// A filter function applied to every provider event.
  ///
  /// If provided, returning `false` suppresses the log for that provider.
  final ISpectRiverpodProviderFilter? providerFilter;

  /// A filter function applied to update events.
  ///
  /// If provided, returning `false` suppresses the update log.
  final ISpectRiverpodUpdateFilter? updateFilter;

  /// Whether to apply redaction to sensitive data in log payloads.
  ///
  /// When `true`, [redactor] is used when provided; otherwise
  /// [ISpectRedaction.service] is resolved when an operation runs.
  final bool enableRedaction;

  /// Optional redaction service for masking sensitive data in provider value
  /// payloads before they are logged.
  ///
  /// Leave this `null` to follow [ISpectRedaction.service].
  final RedactionService? redactor;

  /// Controls whether guarded application formatters may run during capture.
  final DiagnosticCaptureMode captureMode;

  /// Optional observer-specific budgets. `null` inherits the logger policy.
  final DiagnosticResourceLimits? resourceLimits;

  /// Whether redaction is active for this configuration.
  bool get isRedactionActive => enableRedaction && ISpectRedaction.enabled;

  /// Applies redaction to a meta map if redaction is active.
  ///
  /// Returns a bounded copy using [captureMode]. When redaction is disabled,
  /// values remain unmasked but still cannot bypass outbound byte and
  /// traversal limits. A redaction failure returns an empty map.
  Map<String, dynamic>? redactAdditionalData(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;
    return _prepareAdditionalData(
      data,
      enableRedaction: isRedactionActive,
      redactor: redactor,
      captureMode: captureMode,
      resourceLimits: resourceLimits ?? DiagnosticResourceLimits.balanced,
    );
  }

  /// Formats a provider value for display based on [printValues].
  ///
  /// Returns the full object when verbose, otherwise a coarse type label.
  Object formatValue(Object? value) =>
      printValues ? (value ?? 'null') : safeRiverpodValueTypeLabel(value);

  /// Returns a copy with the provided overrides.
  ISpectRiverpodSettings copyWith({
    bool? enabled,
    bool? printAdds,
    bool? printUpdates,
    bool? printDisposes,
    bool? printFails,
    bool? printValues,
    ISpectRiverpodProviderFilter? providerFilter,
    ISpectRiverpodUpdateFilter? updateFilter,
    bool? enableRedaction,
    RedactionService? redactor,
    DiagnosticCaptureMode? captureMode,
    DiagnosticResourceLimits? resourceLimits,
  }) =>
      ISpectRiverpodSettings(
        enabled: enabled ?? this.enabled,
        printAdds: printAdds ?? this.printAdds,
        printUpdates: printUpdates ?? this.printUpdates,
        printDisposes: printDisposes ?? this.printDisposes,
        printFails: printFails ?? this.printFails,
        printValues: printValues ?? this.printValues,
        providerFilter: providerFilter ?? this.providerFilter,
        updateFilter: updateFilter ?? this.updateFilter,
        enableRedaction: enableRedaction ?? this.enableRedaction,
        redactor: redactor ?? this.redactor,
        captureMode: captureMode ?? this.captureMode,
        resourceLimits: resourceLimits ?? this.resourceLimits,
      );
}

Map<String, dynamic> _prepareAdditionalData(
  Map<String, dynamic> data, {
  required bool enableRedaction,
  required RedactionService? redactor,
  required DiagnosticCaptureMode captureMode,
  required DiagnosticResourceLimits resourceLimits,
}) {
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  try {
    final prepared = LogExportOutput.boundJsonValue(
      data,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
      allowCustomSerialization: captureMode == DiagnosticCaptureMode.balanced,
      allowCustomStringification: captureMode == DiagnosticCaptureMode.balanced,
      resourceLimits: resourceLimits,
    );
    final Object? output;
    if (redactionActive) {
      output = ISpectRedaction.resolveService(
        service: redactor,
      ).redactForExport(
        LogExportOutput.replaceTruncatedPrefixes(
          prepared,
          resourceLimits: resourceLimits,
        ),
        resourceLimits: resourceLimits,
      );
    } else {
      output = prepared;
    }
    final bounded = LogExportOutput.boundJsonValue(
      output,
      replaceOversizedStrings: redactionActive,
      resourceLimits: resourceLimits,
    );
    if (bounded is Map) {
      return <String, dynamic>{
        for (final entry in bounded.entries)
          if (entry.key case final String key) key: entry.value,
      };
    }
  } catch (_) {}
  return <String, dynamic>{};
}
