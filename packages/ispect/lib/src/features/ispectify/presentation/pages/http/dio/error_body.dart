part of 'dio_body.dart';

class DioErrorBody extends StatefulWidget {
  const DioErrorBody({
    required this.log,
    required this.jsonController,
  });
  final DioErrorLog log;
  final JsonController jsonController;

  @override
  State<DioErrorBody> createState() => DioErrorBodyState();
}

class DioErrorBodyState extends State<DioErrorBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.log.dioException.response;
    final data = response?.data;
    final headers = response?.headers;
    final statusCode = response?.statusCode;
    final statusMessage = response?.statusMessage;
    final request = widget.log.dioException.requestOptions;
    final errorMessage = widget.log.dioException.message;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DioHTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: request.path,
        fullUrl: request.uri.toString(),
        statusCode: statusCode,
        statusMessage: statusMessage,
        requestHeaders: request.headers,
        data: data,
        headers: headers,
        errorMessage: errorMessage,
        jsonController: widget.jsonController,
      ),
    );
  }
}
