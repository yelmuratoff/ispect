import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/riverpod_json_keys.dart';
import 'package:ispectify_riverpod/src/safe_type_label.dart';
import 'package:riverpod/riverpod.dart';

/// Snapshot of a Riverpod `didAddProvider` event.
class RiverpodAddData {
  RiverpodAddData({
    required this.provider,
    required this.value,
    required this.includeValue,
  });

  final ProviderBase<Object?> provider;
  final Object? value;

  /// Whether [value] should be surfaced in [toJson] or reduced to its
  /// coarse type label. Mirrors `ISpectRiverpodSettings.printValues`.
  final bool includeValue;

  /// Human-readable provider label.
  String get providerName =>
      provider.name ?? safeRiverpodProviderTypeLabel(provider);

  /// Returns a raw, JSON-compatible map of the event.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson() => <String, dynamic>{
        RiverpodJsonKeys.providerName: providerName,
        RiverpodJsonKeys.providerType: safeRiverpodProviderTypeLabel(provider),
        if (provider.argument != null)
          RiverpodJsonKeys.argument: includeValue
              ? provider.argument
              : safeRiverpodValueTypeLabel(provider.argument),
        if (includeValue) RiverpodJsonKeys.value: value,
        if (!includeValue)
          RiverpodJsonKeys.valueType: safeRiverpodValueTypeLabel(value),
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
