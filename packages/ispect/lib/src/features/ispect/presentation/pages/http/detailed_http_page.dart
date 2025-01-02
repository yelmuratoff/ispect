import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/ispect/presentation/pages/http/http/http_body.dart';

class DetailedHTTPPage extends StatefulWidget {
  const DetailedHTTPPage({required this.data, super.key});
  final ISpectiyData data;

  @override
  State<DetailedHTTPPage> createState() => _DetailedHTTPPageState();
}

class _DetailedHTTPPageState extends State<DetailedHTTPPage> {
  final _jsonController = JsonController(
    allNodesExpanded: false,
    uncovered: 3,
  );

  late final ISpectiyData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: iSpect.theme.backgroundColor(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_title(_data.key ?? '')),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              copyClipboard(context, value: _data.textMessage);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_data.key == null) ...[
              switch (_data.title) {
                'http-request' => _httpRequestBody(),
                'http-response' => _httpResponseBody(),
                'http-error' => _httpResponseBody(),
                _ => const SizedBox(),
              },
            ] else ...[
              switch (_data.key) {
                'http-request' => _httpRequestBody(),
                'http-response' => _httpResponseBody(),
                'http-error' => _httpResponseBody(),
                _ => const SizedBox(),
              },
            ],
          ],
        ),
      ),
    );
  }

  HttpResponseBody _httpResponseBody() {
    final innerData = (_data.data != null) ? _data.data : <String, dynamic>{};
    final method = innerData?['method'] as String?;
    final url = innerData?['url'] as String?;
    final path = innerData?['path'] as String?;
    final statusCode = innerData?['status_code'] as int?;
    final statusMessage = innerData?['status_message'] as String?;
    final requestHeaders = innerData?['request_headers'] as Map<String, dynamic>?;
    final headers = innerData?['headers'] as Map<String, String>?;
    final requestBody = innerData?['request_body'];
    final responseBody = innerData?['response_body'];
    return HttpResponseBody(
      method: method,
      url: url,
      path: path,
      statusCode: statusCode,
      statusMessage: statusMessage,
      requestHeaders: requestHeaders,
      headers: headers,
      requestBody: requestBody,
      responseBody: responseBody,
      jsonController: _jsonController,
    );
  }

  HttpRequestBody _httpRequestBody() {
    final innerData = (_data.data != null) ? _data.data : <String, dynamic>{};
    final method = innerData?['method'] as String?;
    final url = innerData?['url'] as String?;
    final path = innerData?['path'] as String?;
    final headers = innerData?['headers'] as Map<String, dynamic>?;
    final body = innerData?['body'];
    return HttpRequestBody(
      method: method,
      url: url,
      path: path,
      headers: headers,
      body: body,
      jsonController: _jsonController,
    );
  }

  String _title(String key) => switch (key) {
        'http-request' => 'HTTP Request',
        'http-response' => 'HTTP Response',
        'http-error' => 'HTTP Error',
        _ => '',
      };
}
