part of 'dio_body.dart';

class DioResponseBody extends StatefulWidget {
  const DioResponseBody({
    required this.log,
    required this.jsonController,
  });
  final DioResponseLog log;
  final JsonController jsonController;

  @override
  State<DioResponseBody> createState() => DioResponseBodyState();
}

class DioResponseBodyState extends State<DioResponseBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.log.response;
    final data = response.data;
    final headers = response.headers;
    final statusCode = response.statusCode;
    final statusMessage = response.statusMessage;
    final request = response.requestOptions;
    final requestHeaders = request.headers;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DioHTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: response.requestOptions.path,
        fullUrl: response.requestOptions.uri.toString(),
        statusCode: statusCode,
        statusMessage: statusMessage,
        requestHeaders: requestHeaders,
        data: data as Map<String, dynamic>,
        headers: headers,
        jsonController: widget.jsonController,
      ),
    );
  }
}
