part of 'http_body.dart';

class HttpResponseBody extends StatefulWidget {
  const HttpResponseBody({
    required this.log,
    required this.jsonController,
  });
  final HttpResponseLog log;
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
  Widget build(BuildContext context) {
    final response = widget.log.response as Response;
    final data = jsonDecode(response.body);
    final headers = response.headers;
    final statusCode = response.statusCode;
    final statusMessage = response.reasonPhrase;
    final request = response.request;
    final requestHeaders = request?.headers;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: HTTPBody(
        dataKey: widget.log.key ?? widget.log.title,
        request: request,
        path: request?.url.path,
        fullUrl: request?.url.toString(),
        statusCode: statusCode,
        statusMessage: statusMessage,
        requestHeaders: requestHeaders,
        data: data,
        headers: headers,
        jsonController: widget.jsonController,
      ),
    );
  }
}
