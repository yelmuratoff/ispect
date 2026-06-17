import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/trace/trace_category_ids.dart';
import 'package:ispectify/src/trace/trace_keys.dart';
import 'package:ispectify/src/utils/json_truncator.dart';

/// Builds the verbose body section (status / payload / headers / error info)
/// of a network log entry from its [ISpectLogData.additionalData].
///
/// Pure and stateless. Output is the multi-line text meant to be appended
/// below the log headline by formatters (console, text export, markdown
/// export). Returned lines are unindented — callers apply their own indent.
abstract final class NetworkLogRenderer {
  const NetworkLogRenderer._();

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
    final category = entry.additionalData?[TraceKeys.category];
    return category == TraceCategoryIds.network ||
        category == TraceCategoryIds.ws;
  }

  /// Builds the renderable body for [entry]. See the class doc for the
  /// contract.
  static String renderBody(ISpectLogData entry) {
    final ad = entry.additionalData;
    if (ad == null) return '';
    final category = ad[TraceKeys.category];

    // Trace pipeline nests caller-supplied `meta` under `additionalData['meta']`.
    // Fall back to top-level for entries built without traceCategory (e.g.
    // direct logData with structured payload).
    final payload = _payload(ad);
    final h = _hintsFrom(payload);

    if (category == TraceCategoryIds.network) {
      final errData = payload[NetworkJsonKeys.errorData];
      if (errData is Map<String, dynamic>) {
        return _renderHttpError(errData, h);
      }
      final respData = payload[NetworkJsonKeys.responseData];
      if (respData is Map<String, dynamic>) {
        return _renderHttpResponse(respData, h);
      }
      final reqData = payload[NetworkJsonKeys.requestData];
      if (reqData is Map<String, dynamic>) {
        return _renderHttpRequest(reqData, h);
      }
      return '';
    }

    if (category == TraceCategoryIds.ws) {
      return _renderWs(payload, h);
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
  ) =>
      _joinSections([
        _section(
          enabled: h.printBody,
          label: 'Data',
          value: reqData[NetworkJsonKeys.data],
        ),
        _section(
          enabled: h.printHeaders,
          label: 'Headers',
          value: reqData[NetworkJsonKeys.headers],
          skipEmpty: true,
        ),
      ]);

  static String _renderHttpResponse(
    Map<String, dynamic> respData,
    _RenderHints h,
  ) {
    final statusCode = respData[NetworkJsonKeys.statusCode];
    final statusMessage = respData[NetworkJsonKeys.statusMessage] as String?;
    return _joinSections([
      if (statusCode != null) 'Status: $statusCode',
      if (h.printMessage && statusMessage != null && statusMessage.isNotEmpty)
        'Message: $statusMessage',
      _section(
        enabled: h.printBody,
        label: 'Data',
        value: respData[NetworkJsonKeys.data] ?? respData[NetworkJsonKeys.body],
      ),
      _section(
        enabled: h.printHeaders,
        label: 'Headers',
        value: respData[NetworkJsonKeys.headers],
        skipEmpty: true,
      ),
    ]);
  }

  static String _renderHttpError(
    Map<String, dynamic> errData,
    _RenderHints h,
  ) {
    final response = errData[NetworkJsonKeys.response] as Map<String, dynamic>?;
    final statusCode = response?[NetworkJsonKeys.statusCode];
    final statusMessage = response?[NetworkJsonKeys.statusMessage] as String?;
    final errorMessage = errData[NetworkJsonKeys.message] as String?;
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
        skipEmpty: true,
      ),
      _section(
        enabled: h.printHeaders,
        label: 'Headers',
        value: response?[NetworkJsonKeys.headers],
        skipEmpty: true,
      ),
    ]);
  }

  // ── WS renderer ───────────────────────────────────────────────────────

  static String _renderWs(Map<String, dynamic> ad, _RenderHints h) {
    final data = ad['data'];
    if (data == null || !h.printBody) return '';
    return _section(
          enabled: true,
          label: 'Data',
          value: data,
        ) ??
        '';
  }

  // ── Helpers ───────────────────────────────────────────────────────────

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
    bool skipEmpty = false,
  }) {
    if (!enabled || value == null) return null;
    if (skipEmpty) {
      if (value is Map && value.isEmpty) return null;
      if (value is Iterable && value.isEmpty) return null;
    }
    return '$label: ${JsonTruncator.pretty(value)}';
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
