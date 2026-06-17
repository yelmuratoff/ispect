/// Canonical JSON key names used across all network interceptor packages.
///
/// Centralizes string literals so every integration (Dio, http, Chopper,
/// Retrofit, etc.) produces structurally consistent metadata.
///
/// Usage:
/// ```dart
/// final map = <String, dynamic>{
///   NetworkJsonKeys.method: 'GET',
///   NetworkJsonKeys.url: 'https://example.com',
/// };
/// ```
abstract final class NetworkJsonKeys {
  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  static const String method = 'method';
  static const String url = 'url';
  static const String baseUrl = 'base-url';
  static const String path = 'path';
  static const String queryParameters = 'query-parameters';

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  static const String statusCode = 'status-code';
  static const String statusMessage = 'status-message';

  // ---------------------------------------------------------------------------
  // Payload
  // ---------------------------------------------------------------------------

  static const String contentType = 'content-type';
  static const String contentLength = 'content-length';
  static const String headers = 'headers';

  /// Body payload key used by Dio (arbitrary type).
  static const String data = 'data';

  /// Body payload key used by http (String body).
  static const String body = 'body';

  static const String bodyBytes = 'body-bytes';
  static const String encoding = 'encoding';

  // ---------------------------------------------------------------------------
  // Timing
  // ---------------------------------------------------------------------------

  static const String connectTimeout = 'connect-timeout';
  static const String sendTimeout = 'send-timeout';
  static const String receiveTimeout = 'receive-timeout';

  // ---------------------------------------------------------------------------
  // Behaviour
  // ---------------------------------------------------------------------------

  static const String followRedirects = 'follow-redirects';
  static const String maxRedirects = 'max-redirects';
  static const String responseType = 'response-type';
  static const String receiveDataWhenStatusError =
      'receive-data-when-status-error';
  static const String persistentConnection = 'persistent-connection';
  static const String preserveHeaderCase = 'preserve-header-case';
  static const String listFormat = 'list-format';
  static const String cancelToken = 'cancel-token';

  // ---------------------------------------------------------------------------
  // Redirects
  // ---------------------------------------------------------------------------

  static const String isRedirect = 'is-redirect';
  static const String redirects = 'redirects';
  static const String location = 'location';

  // ---------------------------------------------------------------------------
  // Meta
  // ---------------------------------------------------------------------------

  static const String extra = 'extra';
  static const String finalized = 'finalized';

  // ---------------------------------------------------------------------------
  // Meta envelope (top-level keys written inside `meta` by interceptors)
  // ---------------------------------------------------------------------------

  /// Correlation id shared across a request/response/error trio.
  static const String requestId = 'request-id';

  /// Serialized outgoing-request blob.
  static const String requestData = 'request-data';

  /// Serialized response blob.
  static const String responseData = 'response-data';

  /// Serialized error blob.
  static const String errorData = 'error-data';

  // ---------------------------------------------------------------------------
  // Nested references
  // ---------------------------------------------------------------------------

  /// Key for nested original-request blob inside response/error maps.
  static const String request = 'request';

  /// Key for nested response blob inside error maps.
  static const String response = 'response';

  // ---------------------------------------------------------------------------
  // Multipart
  // ---------------------------------------------------------------------------

  static const String multipartRequest = 'multipart-request';
  static const String fields = 'fields';
  static const String files = 'files';

  // ---------------------------------------------------------------------------
  // File metadata (inside multipart `files` entries)
  // ---------------------------------------------------------------------------

  /// The form field name the file was attached to.
  static const String fieldName = 'field';
  static const String filename = 'filename';
  static const String contentTypeValue = 'content-type';
  static const String length = 'length';

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  static const String type = 'type';
  static const String message = 'message';
  static const String error = 'error';
  static const String stackTrace = 'stack-trace';

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  static const String metrics = 'metrics';

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Request ID stored in Dio's `extra` map; preserved during redaction.
  static const String ispectRequestId = '_ispect_rid';

  /// Request start time (microseconds since epoch) stored in Dio's `extra` map
  /// to measure duration; stripped from serialized output.
  static const String ispectRequestStartedAt = '_ispect_started_at';
}
