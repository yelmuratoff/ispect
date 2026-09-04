import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/riverpod_json_keys.dart';
import 'package:ispectify_riverpod/src/safe_type_label.dart';
import 'package:riverpod/riverpod.dart';

/// Snapshot of a Riverpod `didUpdateProvider` event.
class RiverpodUpdateData {
  RiverpodUpdateData({
    required this.provider,
    required this.previousValue,
    required this.newValue,
    required this.includeValue,
    this.captureMode = DiagnosticCaptureMode.balanced,
    this.resourceLimits = DiagnosticResourceLimits.balanced,
  });

  final ProviderBase<Object?> provider;
  final Object? previousValue;
  final Object? newValue;

  /// Whether raw values should be surfaced in [toJson] alongside their runtime
  /// type labels. Mirrors `ISpectRiverpodSettings.printValues`.
  final bool includeValue;

  /// Capture policy applied to type labels.
  /// Mirrors `ISpectRiverpodSettings.captureMode`.
  final DiagnosticCaptureMode captureMode;

  /// Budgets applied to type labels.
  /// Mirrors `ISpectRiverpodSettings.resourceLimits`.
  final DiagnosticResourceLimits resourceLimits;

  /// Human-readable provider label.
  String get providerName => provider.name ?? providerType;

  /// Provider class name under the configured capture policy.
  String get providerType => safeRiverpodProviderTypeLabel(
        provider,
        captureMode: captureMode,
        resourceLimits: resourceLimits,
      );

  String _valueType(Object? value) => safeValueTypeLabel(
        value,
        captureMode: captureMode,
        resourceLimits: resourceLimits,
      );

  /// Returns a raw, JSON-compatible map of the event.
  ///
  /// No redaction is applied. Call `redact` on the result when redaction
  /// is required.
  Map<String, dynamic> toJson() => <String, dynamic>{
        RiverpodJsonKeys.providerName: providerName,
        RiverpodJsonKeys.providerType: providerType,
        RiverpodJsonKeys.previousValueType: _valueType(previousValue),
        RiverpodJsonKeys.newValueType: _valueType(newValue),
        if (includeValue) ...{
          RiverpodJsonKeys.previousValue: previousValue,
          RiverpodJsonKeys.newValue: newValue,
        },
      };

  /// Applies in-place redaction to a map produced by [toJson].
  @Deprecated(
    'Observers prepare payloads through StateTracePreparer. '
    'Will be removed in 8.0.0.',
  )
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
