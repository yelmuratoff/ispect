import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/json_tree/json_widget.dart';
import 'package:ispect/src/core/res/json_color.dart';
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
  }

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
      child: _HTTPBody(
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

class _HTTPBody extends StatelessWidget {
  const _HTTPBody({
    required this.dataKey,
    required this.request,
    required this.path,
    required this.fullUrl,
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
  final String? fullUrl;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? _requestHeaders;
  final dynamic data;
  final Headers? headers;
  final String? errorMessage;
  final JsonController jsonController;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final typeColor = iSpect.theme.getTypeColor(
      context,
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
                  TextSpan(
                    text: '${context.ispectL10n.method}: ',
                    style: const TextStyle(
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
                    TextSpan(
                      text: '${context.ispectL10n.path}: ',
                      style: const TextStyle(
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
        if (fullUrl != null) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: GestureDetector(
              onLongPress: () {
                copyClipboard(context, value: fullUrl!);
              },
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${context.ispectL10n.fullURL}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: fullUrl,
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
                  TextSpan(
                    text: '${context.ispectL10n.statusCode}: ',
                    style: const TextStyle(
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
                  TextSpan(
                    text: '${context.ispectL10n.statusMessage}: ',
                    style: const TextStyle(
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
                  TextSpan(
                    text: '${context.ispectL10n.errorMessage}: ',
                    style: const TextStyle(
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
        if (_requestHeaders != null && _requestHeaders!.isNotEmpty) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${context.ispectL10n.requestHeaders}: ',
                        style: const TextStyle(
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
                  indentHeight: 10,
                  indentWidth: 10,
                ),
              ],
            ),
          ),
        ],
        // ignore: avoid_dynamic_calls
        if (data != null && data is Map) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${context.ispectL10n.data}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                if (data is Map) ...[
                  JsonWidget(
                    json: data as Map<String, dynamic>?,
                    jsonController: jsonController,
                    keyColor: context.ispectTheme.textColor,
                    indentLeftEndJsonNode: 0,
                    indentHeight: 10,
                    indentWidth: 10,
                  ),
                ],
                if (data is String?) ...[
                  Text(
                    data.toString(),
                    style: TextStyle(
                      color: iSpect.theme.getTypeColor(
                        context,
                        key: 'error',
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (data is FormData) ...[
          const Gap(8),
          _DetailedItemContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'FormData: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                JsonWidget(
                  json: {
                    'files': (data as FormData)
                        .files
                        .map(
                          (e) =>
                              '${e.value.filename}: Length: ${e.value.length}',
                        )
                        .toList(),
                    'fields': (data as FormData)
                        .fields
                        .map(
                          (e) => '${e.key}: ${e.value}',
                        )
                        .toList(),
                  },
                  jsonController: jsonController,
                  keyColor: context.ispectTheme.textColor,
                  indentLeftEndJsonNode: 0,
                  indentHeight: 10,
                  indentWidth: 10,
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
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${context.ispectL10n.headers}: ',
                        style: const TextStyle(
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
                  indentHeight: 10,
                  indentWidth: 10,
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
