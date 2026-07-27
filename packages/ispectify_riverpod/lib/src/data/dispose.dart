import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/riverpod_json_keys.dart';
import 'package:ispectify_riverpod/src/safe_type_label.dart';
import 'package:riverpod/riverpod.dart';

/// Snapshot of a Riverpod `didDisposeProvider` event.
class RiverpodDisposeData {
  RiverpodDisposeData({required this.provider});

  final ProviderBase<Object?> provider;

  /// Human-readable provider label.
  String get providerName =>
      provider.name ?? safeRiverpodProviderTypeLabel(provider);

  /// Returns a raw, JSON-compatible map of the event.
  Map<String, dynamic> toJson() => <String, dynamic>{
        RiverpodJsonKeys.providerName: providerName,
        RiverpodJsonKeys.providerType: safeRiverpodProviderTypeLabel(provider),
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
