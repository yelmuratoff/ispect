part of 'http_body.dart';

class HttpRequestBody extends StatefulWidget {
  const HttpRequestBody({
    required this.method,
    required this.url,
    required this.path,
    required this.headers,
    required this.body,
    required this.jsonController,
  });

  final String? method;
  final String? url;
  final String? path;
  final Map<String, dynamic>? headers;
  final Object? body;
  final JsonController jsonController;

  @override
  State<HttpRequestBody> createState() => HttpRequestBodyState();
}

class HttpRequestBodyState extends State<HttpRequestBody> {
  Map<String, dynamic>? _requestHeaders;

  @override
  void initState() {
    super.initState();
    _requestHeaders = widget.headers;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: HTTPBody(
          method: widget.method,
          path: widget.path,
          fullUrl: widget.url,
          statusCode: null,
          statusMessage: null,
          requestHeaders: _requestHeaders,
          requestBody: widget.body,
          responseBody: null,
          headers: null,
          jsonController: widget.jsonController,
        ),
      );
}
