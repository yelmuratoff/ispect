part of 'http_body.dart';

class HttpResponseBody extends StatefulWidget {
  const HttpResponseBody({
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.requestBody,
    required this.responseBody,
    required this.jsonController,
  });

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Object? requestBody;
  final Object? responseBody;
  final JsonController jsonController;

  @override
  State<HttpResponseBody> createState() => HttpResponseBodyState();
}

class HttpResponseBodyState extends State<HttpResponseBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: HTTPBody(
          method: widget.method,
          path: widget.path,
          fullUrl: widget.url,
          statusCode: widget.statusCode,
          statusMessage: widget.statusMessage,
          requestHeaders: widget.requestHeaders,
          requestBody: widget.requestBody,
          responseBody: widget.responseBody,
          headers: widget.headers,
          jsonController: widget.jsonController,
        ),
      );
}
