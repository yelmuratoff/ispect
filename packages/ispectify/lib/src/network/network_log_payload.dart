/// Structured request or response data prepared for diagnostic presentation.
final class NetworkLogPayload {
  /// Creates a view over values already processed by the capture-time policy.
  NetworkLogPayload({
    this.body,
    Map<String, Object?> headers = const {},
  }) : headers = Map.unmodifiable(headers);

  /// Captured request or response body.
  final Object? body;

  /// Captured headers; ordinary HTTP field names remain visible while
  /// sensitive values reflect the capture-time redaction policy.
  final Map<String, Object?> headers;

  /// Whether [body] contains a renderable value.
  bool get hasBody => switch (body) {
        null => false,
        final String value => value.isNotEmpty,
        final Map<Object?, Object?> value => value.isNotEmpty,
        final Iterable<Object?> value => value.isNotEmpty,
        _ => true,
      };

  /// Whether at least one captured header is available.
  bool get hasHeaders => headers.isNotEmpty;

  /// Whether either body or header content can be presented.
  bool get hasPreview => hasBody || hasHeaders;
}
