import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Bounded URL and path captured from caller-owned URL text.
///
/// [Uri] is implementable, and no cross-platform runtime check can prove that
/// an arbitrary instance was created by the Dart SDK. URI-only boundaries must
/// therefore use [fromUri], which deliberately returns an opaque snapshot
/// without invoking any member on the supplied object. Callers that already
/// own immutable URL text can use [fromTrustedText].
final class NetworkUriSnapshot {
  const NetworkUriSnapshot._({
    required this.url,
    required this.path,
    required this.isTrusted,
  });

  /// Returns an opaque snapshot without inspecting [uri].
  ///
  /// Even `runtimeType` is not read because an implementation can override it.
  factory NetworkUriSnapshot.fromUri(Uri _) => unavailable;

  /// Parses bounded URL text owned by the caller.
  ///
  /// Do not obtain [url] by formatting an arbitrary [Uri]. The parsed [Uri] is
  /// created inside this method, so reading its path does not cross an
  /// implementable-object trust boundary.
  factory NetworkUriSnapshot.fromTrustedText(String url) {
    try {
      final prepared = _bound(url);
      final parsed = Uri.tryParse(prepared);
      if (parsed == null) return unavailable;
      return NetworkUriSnapshot._(
        url: prepared,
        path: _bound(parsed.path),
        isTrusted: true,
      );
    } on Object {
      return unavailable;
    }
  }

  /// Opaque snapshot used when URL text cannot be read safely.
  static const unavailable = NetworkUriSnapshot._(
    url: JsonValueNormalizer.unprintableValue,
    path: JsonValueNormalizer.unprintableValue,
    isTrusted: false,
  );

  /// Full, bounded URI text or [JsonValueNormalizer.unprintableValue].
  final String url;

  /// Bounded URI path or [JsonValueNormalizer.unprintableValue].
  final String path;

  /// Whether the snapshot came from caller-owned URL text.
  final bool isTrusted;

  static String _bound(String value) => LogExportOutput.truncateUtf8(
        value,
        maxBytes: LogExportOutput.maxPreparedValueBytes,
      );
}
