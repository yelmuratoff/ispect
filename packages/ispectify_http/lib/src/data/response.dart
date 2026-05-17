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

  Map<String, dynamic> toJson() {
    final resp = response;
    final preDecoded = preDecodedBody;
    final multipart = multipartRequest;
    return <String, dynamic>{
      // --- Status: first thing you check ---
      NetworkJsonKeys.statusCode: baseResponse.statusCode,
      NetworkJsonKeys.statusMessage: baseResponse.reasonPhrase,

      // --- Identity ---
      NetworkJsonKeys.method: baseResponse.request?.method,
      NetworkJsonKeys.url: baseResponse.request?.url.toString(),

      // --- Payload ---
      NetworkJsonKeys.headers: baseResponse.headers,
      if (resp != null)
        NetworkJsonKeys.body: preDecoded ?? _tryDecodeJson(resp.body),
      if (resp != null)
        NetworkJsonKeys.bodyBytes: resp.bodyBytes.length.toString(),
      NetworkJsonKeys.contentLength: baseResponse.contentLength,

      // --- Redirects ---
      NetworkJsonKeys.isRedirect: baseResponse.isRedirect,

      // --- Behaviour ---
      NetworkJsonKeys.persistentConnection: baseResponse.persistentConnection,

      // --- Multipart (if applicable) ---
      if (multipart != null)
        NetworkJsonKeys.multipartRequest:
            HttpMultipartSerializer.serialize(multipart),

      // --- Original request (reference) ---
      NetworkJsonKeys.request: requestData.toJson(),
    };
  }

  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
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

    final body = map[NetworkJsonKeys.body];
    if (body != null) {
      map[NetworkJsonKeys.body] = redactor.redact(
            body,
            ignoredValues: ignoredValues,
            ignoredKeys: ignoredKeys,
          ) ??
          body;
    }

    final requestMap = map[NetworkJsonKeys.request];
    if (requestMap is Map<String, dynamic>) {
      HttpRequestData.redact(
        requestMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
  }

  static Object _tryDecodeJson(String body) =>
      NetworkPayloadSanitizer.decodeJsonGracefully(body) ?? body;
}
