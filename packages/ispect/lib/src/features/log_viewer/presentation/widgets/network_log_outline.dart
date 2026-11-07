import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/json_viewer/models/json_outline.dart';
import 'package:ispectify/ispectify.dart';

abstract final class NetworkLogOutline {
  static JsonOutline forLogKey(Object? logKey) =>
      _httpLogKeys.contains(logKey) ? value : const JsonOutline();

  static final _httpLogKeys = {
    ISpectLogType.httpRequest.key,
    ISpectLogType.httpResponse.key,
    ISpectLogType.httpError.key,
  };

  static JsonOutline get value => JsonOutline(
    landmarks: [
      JsonLandmark(
        id: 'body',
        label: _bodyLabel,
        icon: Icons.data_object_rounded,
        paths: _inPayloads(const [
          [NetworkJsonKeys.data],
          [NetworkJsonKeys.body],
          [NetworkJsonKeys.response, NetworkJsonKeys.data],
          [NetworkJsonKeys.response, NetworkJsonKeys.body],
        ]),
      ),
      JsonLandmark(
        id: 'headers',
        label: _headersLabel,
        icon: Icons.view_list_rounded,
        showsCount: true,
        paths: _inPayloads(const [
          [NetworkJsonKeys.headers],
          [NetworkJsonKeys.response, NetworkJsonKeys.headers],
        ]),
      ),
      JsonLandmark(
        id: 'query',
        label: _queryLabel,
        icon: Icons.manage_search_rounded,
        showsCount: true,
        paths: _inPayloads(const [
          [NetworkJsonKeys.queryParameters],
        ]),
      ),
    ],
    foldedPaths: _inPayloads(const [
      [NetworkJsonKeys.headers],
      [NetworkJsonKeys.extra],
      [NetworkJsonKeys.request],
      [NetworkJsonKeys.request, NetworkJsonKeys.headers],
      [NetworkJsonKeys.response, NetworkJsonKeys.headers],
      [NetworkJsonKeys.response, NetworkJsonKeys.request],
    ]),
  );

  static const _payloadKeys = [
    NetworkJsonKeys.requestData,
    NetworkJsonKeys.responseData,
    NetworkJsonKeys.errorData,
  ];

  static const _additionalDataKey = 'additional-data';

  static List<List<String>> _inPayloads(List<List<String>> relativePaths) => [
    for (final path in relativePaths)
      for (final payloadKey in _payloadKeys)
        [_additionalDataKey, TraceKeys.meta, payloadKey, ...path],
  ];

  static String _bodyLabel(BuildContext context) => context.ispectL10n.data;

  static String _headersLabel(BuildContext context) =>
      context.ispectL10n.headers;

  static String _queryLabel(BuildContext context) =>
      context.ispectL10n.composerQueryParameters;
}
