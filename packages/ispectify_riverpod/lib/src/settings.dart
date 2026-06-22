import 'package:ispectify/ispectify.dart';
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
  });

  /// Turns off all logging.
  static const ISpectRiverpodSettings silent =
      ISpectRiverpodSettings(enabled: false);

  /// Logs lifecycle creation, disposal, and failures, but skips per-update noise.
  static const ISpectRiverpodSettings minimal = ISpectRiverpodSettings(
    printUpdates: false,
  );

  /// Reduces values to their runtime type only. Useful when provider state
  /// may carry PII and the project still wants lifecycle visibility.
  static const ISpectRiverpodSettings compact = ISpectRiverpodSettings(
    printValues: false,
  );

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

  /// Whether to log full provider values instead of only the runtime type.
  ///
  /// `true` by default — ISpect is gated by `ISPECT_ENABLED` and only runs in
  /// non-production builds, so verbose value capture is the more useful trade.
  /// Set to `false` (or use [compact]) when provider state may carry PII and
  /// you still want lifecycle visibility.
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
  /// Redaction is only applied when this is `true` AND [redactor] is not null.
  final bool enableRedaction;

  /// Optional redaction service for masking sensitive data in provider value
  /// payloads before they are logged.
  final RedactionService? redactor;

  /// Whether redaction is active for this configuration.
  bool get isRedactionActive => enableRedaction && redactor != null;

  /// Applies redaction to a meta map if redaction is active.
  Map<String, dynamic>? redactAdditionalData(
    Map<String, dynamic>? data,
  ) {
    final redactorInstance = redactor;
    if (data == null || !isRedactionActive || redactorInstance == null) {
      return data;
    }
    return data.map(
      (key, value) => MapEntry(
        key,
        redactorInstance.redact(value, keyName: key),
      ),
    );
  }

  /// Formats a provider value for display based on [printValues].
  ///
  /// Returns the full object when verbose, otherwise its runtime type.
  Object formatValue(Object? value) =>
      printValues ? (value ?? 'null') : (value?.runtimeType ?? 'null');

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
      );
}
