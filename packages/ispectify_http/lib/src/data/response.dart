import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/request.dart';
import 'package:ispectify_http/src/utils/multipart_serializer.dart';

class HttpResponseData {
  HttpResponseData({
    required this.response,
    required this.baseResponse,
    required this.requestData,
    required this.multipartRequest,
    this.preDecodedBody,
  });

  final BaseResponse baseResponse;
  final Response? response;
  final MultipartRequest? multipartRequest;
  final HttpRequestData requestData;

  /// Optional pre-decoded body to avoid redundant JSON parsing.
  /// When provided, [toJson] will use this value instead of re-decoding
  /// [response.body].
  final Object? preDecodedBody;

  /// Converts this response data to a JSON-compatible map.
  ///
  /// When [redactor] is null, raw data (including URL query parameters,
  /// headers with auth tokens, body content, and multipart filenames)
  /// is returned without any sanitization. Callers opting out of
  /// redaction accept responsibility for handling sensitive data.
  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final resp = response;
    final preDecoded = preDecodedBody;
    final multipart = multipartRequest;
    final map = <String, dynamic>{
      // --- Status: first thing you check ---
      NetworkJsonKeys.statusCode: baseResponse.statusCode,
      NetworkJsonKeys.statusMessage: baseResponse.reasonPhrase,

      // --- Identity ---
      NetworkJsonKeys.method: baseResponse.request?.method,
      NetworkJsonKeys.url: baseResponse.request?.url.toString(),

      // --- Payload ---
      NetworkJsonKeys.headers: baseResponse.headers,
      if (resp != null)
        NetworkJsonKeys.body: preDecoded != null
            ? (redactor != null
                ? _redactPreDecoded(
                    preDecoded,
                    redactor,
                    ignoredValues,
                    ignoredKeys,
                  )
                : preDecoded)
            : (redactor != null
                ? _getRedactedBody(
                    resp.body,
                    redactor,
                    ignoredValues,
                    ignoredKeys,
                  )
                : _tryDecodeJson(resp.body)),
      if (resp != null && redactor == null)
        NetworkJsonKeys.bodyBytes: resp.bodyBytes.length.toString(),
      NetworkJsonKeys.contentLength: baseResponse.contentLength,

      // --- Redirects ---
      NetworkJsonKeys.isRedirect: baseResponse.isRedirect,

      // --- Behaviour ---
      NetworkJsonKeys.persistentConnection:
          baseResponse.persistentConnection,

      // --- Multipart (if applicable) ---
      if (multipart != null)
        NetworkJsonKeys.multipartRequest:
            HttpMultipartSerializer.serialize(multipart),

      // --- Original request (reference) ---
      NetworkJsonKeys.request: redactor == null
          ? requestData.toJson()
          : requestData.toJson(
              redactor: redactor,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
    };

    if (redactor == null) return map;

    NetworkMapRedactor.redactUrl(map, redactor);
    final redactedHeaders = NetworkMapRedactor.redactHeaders(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    if (redactedHeaders != null) {
      map[NetworkJsonKeys.headers] =
          redactedHeaders.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    NetworkMapRedactor.redactMultipart(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    return map;
  }

  /// Redacts an already-decoded body value without re-parsing JSON.
  static Object _redactPreDecoded(
    Object body,
    RedactionService redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    final redacted = redactor.redact(
      body,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    return redacted is Object ? redacted : body;
  }

  static Object _tryDecodeJson(String body) =>
      NetworkPayloadSanitizer.decodeJsonGracefully(body) ?? body;

  /// Helper method to get redacted body content
  static Object _getRedactedBody(
    String body,
    RedactionService redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    final decoded = NetworkPayloadSanitizer.decodeJsonGracefully(body) ?? body;
    final redacted = redactor.redact(
      decoded,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    return redacted is Object ? redacted : decoded;
  }
}
