import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/talker/presentation/pages/http/dio/dio_body.dart';
import 'package:ispect/src/features/talker/presentation/pages/http/http/http_body.dart';
import 'package:talker_dio_logger/dio_logs.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_http_logger/talker_http_logger.dart';

class DetailedHTTPPage extends StatefulWidget {
  const DetailedHTTPPage({required this.data, super.key});
  final TalkerData data;

  @override
  State<DetailedHTTPPage> createState() => _DetailedHTTPPageState();
}

class _DetailedHTTPPageState extends State<DetailedHTTPPage> {
  final _jsonController = JsonController(
    allNodesExpanded: false,
    uncovered: 3,
  );

  late final TalkerData _data;

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
              copyClipboard(context, value: _data.generateTextMessage());
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
                'http-request' => (_data is DioRequestLog)
                    ? DioRequestBody(
                        log: _data,
                        jsonController: _jsonController,
                      )
                    : HttpRequestBody(
                        log: _data as HttpRequestLog,
                        jsonController: _jsonController,
                      ),
                'http-response' => (_data is DioResponseLog)
                    ? DioResponseBody(
                        log: _data,
                        jsonController: _jsonController,
                      )
                    : HttpResponseBody(
                        log: _data as HttpResponseLog,
                        jsonController: _jsonController,
                      ),
                'http-error' => DioErrorBody(
                    log: _data as DioErrorLog,
                    jsonController: _jsonController,
                  ),
                _ => const SizedBox(),
              },
            ] else ...[
              switch (_data.key) {
                'http-request' => (_data is DioRequestLog)
                    ? DioRequestBody(
                        log: _data,
                        jsonController: _jsonController,
                      )
                    : HttpRequestBody(
                        log: _data as HttpRequestLog,
                        jsonController: _jsonController,
                      ),
                'http-response' => (_data is DioResponseLog)
                    ? DioResponseBody(
                        log: _data,
                        jsonController: _jsonController,
                      )
                    : HttpResponseBody(
                        log: _data as HttpResponseLog,
                        jsonController: _jsonController,
                      ),
                'http-error' => DioErrorBody(
                    log: _data as DioErrorLog,
                    jsonController: _jsonController,
                  ),
                _ => const SizedBox(),
              },
            ],
          ],
        ),
      ),
    );
  }

  String _title(String key) => switch (key) {
        'http-request' => 'HTTP Request',
        'http-response' => 'HTTP Response',
        'http-error' => 'HTTP Error',
        _ => '',
      };
}
