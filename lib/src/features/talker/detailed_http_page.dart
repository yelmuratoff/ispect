import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/res/json_color.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/common/widgets/json_tree/json_widget.dart';
import 'package:talker_dio_logger/dio_logs.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_title(_data.key ?? '')),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              switch (_data.key) {
                'http-request' => _RequestBody(
                    log: _data as DioRequestLog,
                    jsonController: _jsonController,
                  ),
                'http-response' => _ResponseBody(
                    log: _data as DioResponseLog,
                    jsonController: _jsonController,
                  ),
                'http-error' => _ErrorBody(
                    log: _data as DioErrorLog,
                    jsonController: _jsonController,
                  ),
                _ => const SizedBox(),
              },
            ],
          ),
        ),
      );

  String _title(String key) => switch (key) {
        'http-request' => 'HTTP Request',
        'http-response' => 'HTTP Response',
        'http-error' => 'HTTP Error',
        _ => '',
      };
}

class _ResponseBody extends StatefulWidget {
  const _ResponseBody({
    required this.log,
    required this.jsonController,
  });
  final DioResponseLog log;
  final JsonController jsonController;

  @override
  State<_ResponseBody> createState() => _ResponseBodyState();
}

class _ResponseBodyState extends State<_ResponseBody> {
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
      child: _HTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: response.requestOptions.path,
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

class _RequestBody extends StatefulWidget {
  const _RequestBody({required this.log, required this.jsonController});
  final DioRequestLog log;
  final JsonController jsonController;

  @override
  State<_RequestBody> createState() => _RequestBodyState();
}

class _RequestBodyState extends State<_RequestBody> {
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
      child: _HTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: request.path,
        statusCode: null,
        statusMessage: null,
        requestHeaders: _requestHeaders,
        data: data as Map<String, dynamic>?,
        headers: null,
        jsonController: widget.jsonController,
      ),
    );
  }
}

class _ErrorBody extends StatefulWidget {
  const _ErrorBody({
    required this.log,
    required this.jsonController,
  });
  final DioErrorLog log;
  final JsonController jsonController;

  @override
  State<_ErrorBody> createState() => _ErrorBodyState();
}

class _ErrorBodyState extends State<_ErrorBody> {
  Map<String, dynamic>? _requestHeaders;
  @override
  void initState() {
    super.initState();
    _requestHeaders = widget.log.dioException.response?.requestOptions.headers;
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.log.dioException.response;
    final data = response?.data;
    final headers = response?.headers;
    final statusCode = response?.statusCode;
    final statusMessage = response?.statusMessage;
    final request = response?.requestOptions;
    final errorMessage = widget.log.dioException.message;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _HTTPBody(
        dataKey: widget.log.key,
        request: request,
        path: response?.requestOptions.path,
        statusCode: statusCode,
        statusMessage: statusMessage,
        requestHeaders: _requestHeaders,
        data: data as Map<String, dynamic>?,
        headers: headers,
        errorMessage: errorMessage,
        jsonController: widget.jsonController,
      ),
    );
  }
}

class _HTTPBody extends StatelessWidget {
  const _HTTPBody({
    required this.dataKey,
    required this.request,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required Map<String, dynamic>? requestHeaders,
    required this.data,
    required this.headers,
    required this.jsonController,
    this.errorMessage,
  }) : _requestHeaders = requestHeaders;

  final String dataKey;
  final RequestOptions? request;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? _requestHeaders;
  final Map<String, dynamic>? data;
  final Headers? headers;
  final String? errorMessage;
  final JsonController jsonController;

  @override
  Widget build(BuildContext context) {
    final typeColor = getTypeColor(
      isDark: context.isDarkMode,
      key: dataKey,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request != null) ...[
          _DetailedItemContainer(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Method: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: request!.method,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (path != null) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: GestureDetector(
              onLongPress: () {
                copyClipboard(context, value: path!);
              },
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Path: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: path,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: JsonColors.stringColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (statusCode != null) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Status code: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '$statusCode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (statusMessage != null) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Status message: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '$statusMessage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Error message: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: errorMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const Gap(8),
        _DetailedItemContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Request headers: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              JsonWidget(
                json: _requestHeaders,
                jsonController: jsonController,
                keyColor: context.ispectTheme.textColor,
                indentLeftEndJsonNode: 0,
              ),
            ],
          ),
        ),
        if (data != null && data!.isNotEmpty) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Data: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                JsonWidget(
                  json: data,
                  jsonController: jsonController,
                  keyColor: context.ispectTheme.textColor,
                  indentLeftEndJsonNode: 0,
                ),
              ],
            ),
          ),
        ],
        if (headers != null) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Headers: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                JsonWidget(
                  json: headers?.map as Map<String, dynamic>?,
                  jsonController: jsonController,
                  keyColor: context.ispectTheme.textColor,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailedItemContainer extends StatelessWidget {
  const _DetailedItemContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              context.adjustColor(context.ispectTheme.scaffoldBackgroundColor),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      );
}

// Map<String, dynamic> _getUpdatedMap(Map<String, dynamic> map) {
//   final updatedMap = <String, dynamic>{};
//   // Must change Authorization header value to 'Hidden'
//   map.forEach((key, value) {
//     if (key == 'Authorization') {
//       updatedMap[key] = 'Hidden';
//     } else {
//       updatedMap[key] = value;
//     }
//   });
//   return updatedMap;
// }
