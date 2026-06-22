import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:ispectify/ispectify.dart';

/// Sends composed/replayed requests through an app-owned [http.Client].
///
/// Register the same client the app uses (typically an `InterceptedClient`
/// carrying `ISpectHttpInterceptor`), so the request reuses its interceptors and
/// is captured in the logs. Sending goes through [http.Client.send], which the
/// interceptor pipeline runs end-to-end. Unlike Dio, `http` does not throw on a
/// non-2xx status, so 4xx/5xx responses are returned with their status and body
/// and a `null` error.
final class HttpClientRequestSender implements NetworkRequestSender {
  HttpClientRequestSender(this.client, {this.id = 'http', this.label = 'HTTP'});

  final http.Client client;

  @override
  final String id;

  @override
  final String label;

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final streamed = await client.send(_buildRequest(request));
      final response = await http.Response.fromStream(streamed);
      return NetworkReplayResult(
        statusCode: response.statusCode,
        headers: response.headers,
        body: NetworkPayloadSanitizer.decodeJsonGracefully(response.body),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on http.ClientException catch (e) {
      return NetworkReplayResult(
        durationMs: stopwatch.elapsedMilliseconds,
        error: e,
      );
    }
  }

  http.BaseRequest _buildRequest(NetworkReplayRequest request) {
    final body = request.body;
    if (body is MultipartReplayBody) {
      return _buildMultipart(request, body);
    }

    final req = http.Request(request.method, request.uri);
    _applyHeaders(req, request.headers);
    switch (body) {
      case null:
        break;
      case JsonReplayBody(:final value):
        req.headers.putIfAbsent('content-type', () => 'application/json');
        req.body = jsonEncode(value);
      case TextReplayBody(:final text, :final contentType):
        if (contentType != null) {
          req.headers.putIfAbsent('content-type', () => contentType);
        }
        req.body = text;
      case FormUrlEncodedReplayBody(:final fields):
        req.headers['content-type'] = 'application/x-www-form-urlencoded';
        req.body = fields.entries
            .map(
              (e) =>
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
            )
            .join('&');
      case MultipartReplayBody():
        break;
    }
    return req;
  }

  http.MultipartRequest _buildMultipart(
    NetworkReplayRequest request,
    MultipartReplayBody body,
  ) {
    final req = http.MultipartRequest(request.method, request.uri);
    _applyHeaders(req, request.headers, dropContentType: true);
    for (final field in body.fields) {
      req.fields[field.name] = field.value;
    }
    for (final part in body.files) {
      final file = part.file;
      req.files.add(
        http.MultipartFile.fromBytes(
          part.field,
          file.bytes,
          filename: file.filename,
          contentType: file.contentType == null
              ? null
              : MediaType.parse(file.contentType!),
        ),
      );
    }
    return req;
  }

  /// Copies [headers] onto [request] with lower-cased names so a body-derived
  /// `content-type` can't collide with a differently-cased captured one.
  void _applyHeaders(
    http.BaseRequest request,
    Map<String, String> headers, {
    bool dropContentType = false,
  }) {
    headers.forEach((name, value) {
      final key = name.toLowerCase();
      if (dropContentType && key == 'content-type') return;
      request.headers[key] = value;
    });
  }
}
