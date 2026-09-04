import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

class HttpRequestData {
  HttpRequestData(
    this.requestOptions, {
    this.resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
  }

  final BaseRequest? requestOptions;
  final DiagnosticResourceLimits resourceLimits;

  Map<String, dynamic> toJson({
    bool includeData = true,
    bool includeHeaders = true,
    bool redactionActive = false,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  }) {
    final request = requestOptions;
    final uriSnapshot = request == null
        ? null
        : NetworkUriSnapshot.fromUri(
            request.url,
            captureMode: captureMode,
            resourceLimits: resourceLimits,
          );
    final queryParameters = _queryParameters(
      uriSnapshot,
      captureMode: captureMode,
      resourceLimits: resourceLimits,
    );
    return <String, dynamic>{
      // --- Identity: what & where ---
      NetworkJsonKeys.method: request?.method,
      NetworkJsonKeys.url: uriSnapshot?.url,
      NetworkJsonKeys.queryParameters: queryParameters,

      // --- Payload ---
      if (includeHeaders)
        NetworkJsonKeys.headers: NetworkPayloadSanitizer.toStringKeyMap(
          requestOptions?.headers,
          captureMode: captureMode,
          resourceLimits: resourceLimits,
          maxEntries: resourceLimits.maxNetworkHeaders,
        ),
      NetworkJsonKeys.encoding: switch (requestOptions) {
        final Request request => _encodingName(request),
        _ => null,
      },
      if (includeData)
        NetworkJsonKeys.data: switch (requestOptions) {
          final Request request => _boundedBody(
              request,
              redactionActive: redactionActive,
            ),
          _ => null,
        },
      NetworkJsonKeys.contentLength: _contentLength(requestOptions),

      // --- Behaviour ---
      NetworkJsonKeys.followRedirects: requestOptions?.followRedirects,
      NetworkJsonKeys.maxRedirects: requestOptions?.maxRedirects,
      NetworkJsonKeys.persistentConnection:
          requestOptions?.persistentConnection,

      // --- State ---
      NetworkJsonKeys.finalized: requestOptions?.finalized,
    };
  }

  static int? _contentLength(BaseRequest? request) {
    if (request == null || request is MultipartRequest) return null;
    try {
      return request.contentLength;
    } on Object {
      return null;
    }
  }

  static String _encodingName(Request request) {
    try {
      return request.encoding.name;
    } on Object {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  String _boundedBody(
    Request request, {
    required bool redactionActive,
  }) {
    try {
      return BoundedByteBody.decode(
        request.bodyBytes,
        request.encoding,
        resourceLimits: resourceLimits,
        redactionActive: redactionActive,
      );
    } on Object {
      return LogExportOutput.truncatedMarker;
    }
  }

  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    NetworkMapRedactor.redactMethod(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.encoding,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactUrl(
      map,
      redactor,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactMapField(
      map,
      redactor,
      key: NetworkJsonKeys.queryParameters,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    final redactedHeaders = NetworkMapRedactor.redactHeaders(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    if (redactedHeaders != null) {
      map[NetworkJsonKeys.headers] =
          redactedHeaders.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    NetworkMapRedactor.redactData(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
  }

  static Map<String, dynamic> _queryParameters(
    NetworkUriSnapshot? snapshot, {
    required DiagnosticCaptureMode captureMode,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (snapshot == null || !snapshot.isTrusted) return <String, dynamic>{};
    try {
      final uri = Uri.tryParse(snapshot.url);
      if (uri == null) return <String, dynamic>{};
      final query = <String, Object?>{
        for (final entry in uri.queryParametersAll.entries)
          entry.key: entry.value.length == 1 ? entry.value.single : entry.value,
      };
      return NetworkPayloadSanitizer.toStringKeyMap(
        query,
        captureMode: captureMode,
        resourceLimits: resourceLimits,
      );
    } on Object {
      return <String, dynamic>{};
    }
  }
}
