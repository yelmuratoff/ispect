import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/network/network_log_payload.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/trace/trace_category_ids.dart';
import 'package:ispectify/src/trace/trace_keys.dart';
import 'package:ispectify/src/utils/json_truncator.dart';

/// Extracts and formats network diagnostics for console and UI presentation.
///
/// Structured URL and payload data is reused from the capture-time snapshot;
/// headline message text retains its outbound redaction pass.
abstract final class NetworkLogRenderer {
  const NetworkLogRenderer._();

  static final _encodedDefaultPlaceholder = RegExp(
    Uri.encodeQueryComponent(defaultPlaceholder),
    caseSensitive: false,
  );

  /// Private additionalData key carrying per-entry render preferences set by
  /// the interceptor: a Map<String, bool> with keys [hintPrintBody],
  /// [hintPrintHeaders], [hintPrintMessage]. Kept out of the public
  /// [NetworkJsonKeys] namespace since this is presentation metadata, not a
  /// structural field. The leading underscore marks it as private convention;
  /// downstream consumers (UI, exports) may filter it out.
  static const renderHintsKey = '_render-hints';

  /// Hint key: render the request/response/error body block. Default `true`.
  static const hintPrintBody = 'printBody';

  /// Hint key: render the headers block. Default `false`.
  static const hintPrintHeaders = 'printHeaders';

  /// Hint key: render status / error message line. Default `false`.
  static const hintPrintMessage = 'printMessage';

  /// Whether [entry] is a network or WS log this renderer can format.
  ///
  /// Detection is by category, not by [ISpectLogData.key], so custom client
  /// adapters (gRPC, GraphQL, Chopper, …) opt in automatically as soon as
  /// they tag their entries with `TraceCategoryIds.network`.
  static bool isNetworkLog(ISpectLogData entry) {
    final category = captureISpectLogDataForEgress(
      entry,
    ).additionalData?[TraceKeys.category];
    return category == TraceCategoryIds.network ||
        category == TraceCategoryIds.ws;
  }

  /// Returns the entry headline with separately captured query parameters
  /// appended to its URL.
  static String renderHeadline(ISpectLogData entry) {
    final captured = captureISpectLogDataForEgress(entry);
    final headline = entry.toExportMessageText();
    if (!isNetworkLog(entry)) return headline;

    final additionalData = _additionalData(entry);
    final target = additionalData?[TraceKeys.target];
    if (target is! String || target.isEmpty) return headline;

    final url = _displayUrl(
      additionalData!,
      target,
      captured.resourceLimits.maxCapturedValueBytes,
    );
    return url == target ? headline : headline.replaceFirst(target, url);
  }

  /// Returns a display URL assembled from the trace target and normalized
  /// request query parameters.
  static String? displayUrl(ISpectLogData entry) {
    final captured = captureISpectLogDataForEgress(entry);
    final additionalData = _additionalData(entry);
    if (additionalData == null) return null;

    final request = _requestData(_payload(additionalData));
    final target = additionalData[TraceKeys.target];
    final fallbackUrl = request?[NetworkJsonKeys.url];
    final baseUrl = target is String
        ? target
        : fallbackUrl is String
            ? fallbackUrl
            : null;
    if (baseUrl == null || baseUrl.isEmpty) return baseUrl;
    return _displayUrl(
      additionalData,
      baseUrl,
      captured.resourceLimits.maxCapturedValueBytes,
    );
  }

  /// Returns the request payload embedded in a request, response, or error log.
  static NetworkLogPayload? requestPayload(ISpectLogData entry) {
    final additionalData = _additionalData(entry);
    if (additionalData == null) return null;
    final data = _requestData(_payload(additionalData));
    return data == null ? null : _networkPayload(data);
  }

  /// Returns the response payload embedded in a response or error log.
  static NetworkLogPayload? responsePayload(ISpectLogData entry) {
    final additionalData = _additionalData(entry);
    if (additionalData == null) return null;
    final data = _responseData(_payload(additionalData));
    return data == null ? null : _networkPayload(data);
  }

  /// Returns the payload represented by this log's role.
  static NetworkLogPayload? payload(ISpectLogData entry) {
    final captured = captureISpectLogDataForEgress(entry);
    if (captured.key == ISpectLogType.httpRequest.key) {
      return requestPayload(entry);
    }
    return responsePayload(entry) ?? requestPayload(entry);
  }

  /// Builds the renderable body for [entry]. See the class doc for the
  /// contract.
  static String renderBody(ISpectLogData entry) {
    final captured = captureISpectLogDataForEgress(entry);
    final ad = captured.additionalData;
    if (ad == null) return '';
    final category = ad[TraceKeys.category];
    final maxStringLength = captured.resourceLimits.maxCapturedValueBytes;

    // Trace pipeline nests caller-supplied `meta` under `additionalData['meta']`.
    // Fall back to top-level for entries built without traceCategory (e.g.
    // direct logData with structured payload).
    final payload = _payload(ad);
    final h = _hintsFrom(payload);

    if (category == TraceCategoryIds.network) {
      final errData = payload[NetworkJsonKeys.errorData];
      if (errData is Map<String, dynamic>) {
        return _renderHttpError(errData, h, maxStringLength);
      }
      final respData = payload[NetworkJsonKeys.responseData];
      if (respData is Map<String, dynamic>) {
        return _renderHttpResponse(respData, h, maxStringLength);
      }
      final reqData = payload[NetworkJsonKeys.requestData];
      if (reqData is Map<String, dynamic>) {
        return _renderHttpRequest(reqData, h, maxStringLength);
      }
      return '';
    }

    if (category == TraceCategoryIds.ws) {
      return _renderWs(payload, h, maxStringLength);
    }

    return '';
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> ad) {
    final nested = ad[TraceKeys.meta];
    if (nested is Map<String, dynamic>) return nested;
    return ad;
  }

  // ── HTTP renderers ────────────────────────────────────────────────────

  static String _renderHttpRequest(
    Map<String, dynamic> reqData,
    _RenderHints h,
    int maxStringLength,
  ) =>
      _joinSections([
        _section(
          enabled: h.printBody,
          label: 'Data',
          value: reqData[NetworkJsonKeys.data],
          maxStringLength: maxStringLength,
        ),
        _section(
          enabled: h.printHeaders,
          label: 'Headers',
          value: reqData[NetworkJsonKeys.headers],
          maxStringLength: maxStringLength,
          skipEmpty: true,
        ),
      ]);

  static String _renderHttpResponse(
    Map<String, dynamic> respData,
    _RenderHints h,
    int maxStringLength,
  ) {
    final rawStatusCode = respData[NetworkJsonKeys.statusCode];
    final statusCode = rawStatusCode is int ? rawStatusCode : null;
    final rawStatusMessage = respData[NetworkJsonKeys.statusMessage];
    final statusMessage = rawStatusMessage is String ? rawStatusMessage : null;
    return _joinSections([
      if (statusCode != null) 'Status: $statusCode',
      if (h.printMessage && statusMessage != null && statusMessage.isNotEmpty)
        'Message: $statusMessage',
      _section(
        enabled: h.printBody,
        label: 'Data',
        value: respData[NetworkJsonKeys.data] ?? respData[NetworkJsonKeys.body],
        maxStringLength: maxStringLength,
      ),
      _section(
        enabled: h.printHeaders,
        label: 'Headers',
        value: respData[NetworkJsonKeys.headers],
        maxStringLength: maxStringLength,
        skipEmpty: true,
      ),
    ]);
  }

  static String _renderHttpError(
    Map<String, dynamic> errData,
    _RenderHints h,
    int maxStringLength,
  ) {
    final rawResponse = errData[NetworkJsonKeys.response];
    final response = rawResponse is Map<String, dynamic> ? rawResponse : null;
    final rawStatusCode = response?[NetworkJsonKeys.statusCode];
    final statusCode = rawStatusCode is int ? rawStatusCode : null;
    final rawStatusMessage = response?[NetworkJsonKeys.statusMessage];
    final statusMessage = rawStatusMessage is String ? rawStatusMessage : null;
    final rawErrorMessage = errData[NetworkJsonKeys.message];
    final errorMessage = rawErrorMessage is String ? rawErrorMessage : null;
    return _joinSections([
      if (statusCode != null) 'Status: $statusCode',
      if (h.printMessage && statusMessage != null && statusMessage.isNotEmpty)
        'Message: $statusMessage',
      if (h.printMessage && errorMessage != null && errorMessage.isNotEmpty)
        'Error: $errorMessage',
      _section(
        enabled: h.printBody,
        label: 'Data',
        value:
            response?[NetworkJsonKeys.data] ?? response?[NetworkJsonKeys.body],
        maxStringLength: maxStringLength,
        skipEmpty: true,
      ),
      _section(
        enabled: h.printHeaders,
        label: 'Headers',
        value: response?[NetworkJsonKeys.headers],
        maxStringLength: maxStringLength,
        skipEmpty: true,
      ),
    ]);
  }

  // ── WS renderer ───────────────────────────────────────────────────────

  static String _renderWs(
    Map<String, dynamic> ad,
    _RenderHints h,
    int maxStringLength,
  ) {
    final data = ad['data'];
    if (data == null || !h.printBody) return '';
    return _section(
          enabled: true,
          label: 'Data',
          value: data,
          maxStringLength: maxStringLength,
        ) ??
        '';
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static Map<Object?, Object?>? _queryParameters(
    Map<String, dynamic> data,
  ) {
    final direct = data[NetworkJsonKeys.queryParameters];
    if (direct is Map<Object?, Object?>) return direct;

    final request = data[NetworkJsonKeys.request];
    if (request is Map<Object?, Object?>) {
      final nested = request[NetworkJsonKeys.queryParameters];
      if (nested is Map<Object?, Object?>) return nested;
    }

    final response = data[NetworkJsonKeys.response];
    if (response is Map<String, dynamic>) {
      return _queryParameters(response);
    }
    return null;
  }

  static Map<String, dynamic>? _additionalData(ISpectLogData entry) =>
      captureISpectLogDataForEgress(entry).additionalData;

  static String _displayUrl(
    Map<String, dynamic> additionalData,
    String baseUrl,
    int maxBytes,
  ) {
    if (baseUrl.contains('?')) return _readableRedactionMarkers(baseUrl);
    final request = _requestData(_payload(additionalData));
    final query = request == null ? null : _queryParameters(request);
    if (query == null || query.isEmpty) return baseUrl;

    final pairs = <String>[];
    for (final entry in query.entries) {
      final key = _queryComponent(entry.key);
      final values = entry.value is Iterable<Object?>
          ? entry.value! as Iterable<Object?>
          : <Object?>[entry.value];
      if (values.isEmpty) {
        pairs.add('$key=');
        continue;
      }
      for (final value in values) {
        pairs.add('$key=${_queryComponent(value)}');
      }
    }
    if (pairs.isEmpty) return baseUrl;
    return LogExportOutput.truncateUtf8(
      '$baseUrl?${pairs.join('&')}',
      maxBytes: maxBytes,
    );
  }

  static String _queryComponent(Object? value) {
    final text = switch (value) {
      null => '',
      final String value => value,
      final bool value => value.toString(),
      final num value => value.toString(),
      _ => JsonTruncator.pretty(value),
    };
    if (text.startsWith('[') && text.endsWith(']')) return text;
    return Uri.encodeQueryComponent(text);
  }

  static String _readableRedactionMarkers(String url) =>
      url.replaceAll(_encodedDefaultPlaceholder, defaultPlaceholder);

  static Map<String, dynamic>? _requestData(Map<String, dynamic> payload) {
    final direct = _stringMap(payload[NetworkJsonKeys.requestData]);
    if (direct != null) return direct;

    final response = _stringMap(payload[NetworkJsonKeys.responseData]);
    final responseRequest = _stringMap(response?[NetworkJsonKeys.request]);
    if (responseRequest != null) return responseRequest;

    final error = _stringMap(payload[NetworkJsonKeys.errorData]);
    final errorRequest = _stringMap(error?[NetworkJsonKeys.request]);
    if (errorRequest != null) return errorRequest;
    final errorResponse = _stringMap(error?[NetworkJsonKeys.response]);
    return _stringMap(errorResponse?[NetworkJsonKeys.request]);
  }

  static Map<String, dynamic>? _responseData(Map<String, dynamic> payload) {
    final response = _stringMap(payload[NetworkJsonKeys.responseData]);
    if (response != null) return response;
    final error = _stringMap(payload[NetworkJsonKeys.errorData]);
    return _stringMap(error?[NetworkJsonKeys.response]);
  }

  static NetworkLogPayload _networkPayload(Map<String, dynamic> data) =>
      NetworkLogPayload(
        body: data[NetworkJsonKeys.data] ?? data[NetworkJsonKeys.body],
        headers: _objectMap(data[NetworkJsonKeys.headers]),
      );

  static Map<String, dynamic>? _stringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is! Map<Object?, Object?>) return null;
    return <String, dynamic>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key! as String: entry.value,
    };
  }

  static Map<String, Object?> _objectMap(Object? value) {
    final map = _stringMap(value);
    return map == null ? const {} : Map<String, Object?>.from(map);
  }

  static _RenderHints _hintsFrom(Map<String, dynamic> payload) {
    final raw = payload[renderHintsKey];
    if (raw is! Map) return const _RenderHints();
    return _RenderHints(
      printBody: _readBool(raw, hintPrintBody, true),
      printHeaders: _readBool(raw, hintPrintHeaders, false),
      printMessage: _readBool(raw, hintPrintMessage, false),
    );
  }

  static bool _readBool(Map<Object?, Object?> map, String key, bool fallback) {
    final raw = map[key];
    return raw is bool ? raw : fallback;
  }

  static String _joinSections(List<String?> sections) {
    final buf = StringBuffer();
    var first = true;
    for (final section in sections) {
      if (section == null || section.isEmpty) continue;
      if (!first) buf.write('\n');
      buf.write(section);
      first = false;
    }
    return buf.toString();
  }

  static String? _section({
    required bool enabled,
    required String label,
    required Object? value,
    required int maxStringLength,
    bool skipEmpty = false,
  }) {
    if (!enabled || value == null) return null;
    if (skipEmpty) {
      if (value is Map && value.isEmpty) return null;
      if (value is Iterable && value.isEmpty) return null;
    }
    return '$label: ${JsonTruncator.pretty(
      value,
      maxStringLength: maxStringLength,
    )}';
  }
}

/// Render preferences resolved for a single entry. Defaults match the
/// historical interceptor defaults so an entry without any hints (e.g. a
/// custom adapter) prints with body but without headers — matching what Dio
/// and http used to produce.
class _RenderHints {
  const _RenderHints({
    this.printBody = true,
    this.printHeaders = false,
    this.printMessage = false,
  });

  final bool printBody;
  final bool printHeaders;
  final bool printMessage;
}
