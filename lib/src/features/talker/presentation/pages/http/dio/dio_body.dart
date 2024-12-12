import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/json_tree/json_widget.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/talker/presentation/pages/http/item_container.dart';
import 'package:talker_dio_logger/dio_logs.dart';

part 'error_body.dart';
part 'request_body.dart';
part 'response_body.dart';

class DioHTTPBody extends StatelessWidget {
  const DioHTTPBody({
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
          DetailedItemContainer(
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
