part of 'http_body.dart';

class HttpRequestBody extends StatefulWidget {
  const HttpRequestBody({required this.log, required this.jsonController});
  final HttpRequestLog log;
  final JsonController jsonController;

  @override
  State<HttpRequestBody> createState() => HttpRequestBodyState();
}

class HttpRequestBodyState extends State<HttpRequestBody> {
  Map<String, dynamic>? _requestHeaders;

  @override
  void initState() {
    super.initState();
    _requestHeaders = widget.log.request.headers;
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.log.request as Request;

    final data = request.body;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: HTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: request.url.path,
        fullUrl: request.url.toString(),
        statusCode: null,
        statusMessage: null,
        requestHeaders: _requestHeaders,
        data: data,
        headers: null,
        jsonController: widget.jsonController,
      ),
    );
  }
}
