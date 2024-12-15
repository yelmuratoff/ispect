part of 'dio_body.dart';

class DioRequestBody extends StatefulWidget {
  const DioRequestBody({required this.log, required this.jsonController});
  final DioRequestLog log;
  final JsonController jsonController;

  @override
  State<DioRequestBody> createState() => DioRequestBodyState();
}

class DioRequestBodyState extends State<DioRequestBody> {
  Map<String, dynamic>? _requestHeaders;

  @override
  void initState() {
    super.initState();
    _requestHeaders = widget.log.requestOptions.headers;
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.log.requestOptions;
    final data = request.data;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DioHTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: request.path,
        fullUrl: request.uri.toString(),
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
