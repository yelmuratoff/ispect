import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ispect/src/core/res/ispect_callbacks.dart';
import 'package:ispectify/ispectify.dart';

/// Body encoding selected in the composer.
enum ComposerBodyKind { none, json, text, formUrlEncoded, multipart }

/// Why [HttpComposerController.buildReplayRequest] or [send] could not proceed.
///
/// The view maps these to localized messages so the logic layer carries no UI
/// text.
enum ComposerValidation { urlRequired, urlInvalid, jsonInvalid, noClient }

/// A mutable key/value row backing a header, query, or form field editor.
final class ComposerKeyValue {
  ComposerKeyValue({this.key = '', this.value = ''});

  String key;
  String value;
}

/// Holds the editable state of the HTTP composer and assembles it into a
/// [NetworkReplayRequest] for sending.
///
/// All request-building logic lives here rather than in the screen: the view
/// only renders state and forwards edits. Senders and the file picker are
/// injected so the controller stays testable without touching `ISpect`.
final class HttpComposerController extends ChangeNotifier {
  HttpComposerController({
    required List<NetworkRequestSender> senders,
    ISpectComposerFilePicker? filePicker,
    NetworkReplayRequest? seed,
  })  : _senders = senders,
        _filePicker = filePicker {
    if (senders.isNotEmpty) _selectedSenderId = senders.first.id;
    if (seed != null) _applySeed(seed);
  }

  final List<NetworkRequestSender> _senders;
  final ISpectComposerFilePicker? _filePicker;

  String _method = 'GET';
  String _url = '';
  final List<ComposerKeyValue> _headers = [];
  final List<ComposerKeyValue> _queryParams = [];
  ComposerBodyKind _bodyKind = ComposerBodyKind.none;
  String _bodyText = '';
  final List<ComposerKeyValue> _formFields = [];
  final List<ComposerKeyValue> _multipartFields = [];
  final List<MultipartReplayFile> _multipartFiles = [];

  String? _selectedSenderId;
  bool _isSending = false;
  NetworkReplayResult? _result;
  ComposerValidation? _validationError;

  List<NetworkRequestSender> get senders => List.unmodifiable(_senders);
  String? get selectedSenderId => _selectedSenderId;
  String get method => _method;
  String get url => _url;
  List<ComposerKeyValue> get headers => List.unmodifiable(_headers);
  List<ComposerKeyValue> get queryParams => List.unmodifiable(_queryParams);
  ComposerBodyKind get bodyKind => _bodyKind;
  String get bodyText => _bodyText;
  List<ComposerKeyValue> get formFields => List.unmodifiable(_formFields);
  List<ComposerKeyValue> get multipartFields =>
      List.unmodifiable(_multipartFields);
  List<MultipartReplayFile> get multipartFiles =>
      List.unmodifiable(_multipartFiles);
  bool get isSending => _isSending;
  NetworkReplayResult? get result => _result;
  ComposerValidation? get validationError => _validationError;

  /// Whether file attachment is available (a picker was supplied by the host).
  bool get canAttachFiles => _filePicker != null;

  void setMethod(String value) {
    _method = value;
    notifyListeners();
  }

  void setUrl(String value) {
    _url = value;
    notifyListeners();
  }

  void selectSender(String id) {
    _selectedSenderId = id;
    notifyListeners();
  }

  void setBodyKind(ComposerBodyKind kind) {
    _bodyKind = kind;
    notifyListeners();
  }

  void setBodyText(String value) {
    _bodyText = value;
    notifyListeners();
  }

  void addHeader() => _addRow(_headers);
  void removeHeaderAt(int index) => _removeRow(_headers, index);
  void addQueryParam() => _addRow(_queryParams);
  void removeQueryParamAt(int index) => _removeRow(_queryParams, index);
  void addFormField() => _addRow(_formFields);
  void removeFormFieldAt(int index) => _removeRow(_formFields, index);
  void addMultipartField() => _addRow(_multipartFields);
  void removeMultipartFieldAt(int index) => _removeRow(_multipartFields, index);

  void removeFileAt(int index) {
    _multipartFiles.removeAt(index);
    notifyListeners();
  }

  /// Picks a file through the host-supplied picker and attaches it to [field].
  ///
  /// No-op when no picker was injected or the user cancels.
  Future<void> attachFile(String field) async {
    final picker = _filePicker;
    if (picker == null) return;
    final picked = await picker();
    if (picked == null) return;
    _multipartFiles.add(MultipartReplayFile(field: field, file: picked));
    notifyListeners();
  }

  /// Assembles the current state into a [NetworkReplayRequest].
  ///
  /// Returns `null` and sets [validationError] when the URL is missing/invalid
  /// or a JSON body fails to parse.
  NetworkReplayRequest? buildReplayRequest() {
    _validationError = null;

    final trimmedUrl = _url.trim();
    if (trimmedUrl.isEmpty) {
      _validationError = ComposerValidation.urlRequired;
      return null;
    }
    final parsed = Uri.tryParse(trimmedUrl);
    if (parsed == null || !parsed.hasScheme) {
      _validationError = ComposerValidation.urlInvalid;
      return null;
    }

    final NetworkReplayBody? body;
    switch (_bodyKind) {
      case ComposerBodyKind.none:
        body = null;
      case ComposerBodyKind.json:
        if (_bodyText.trim().isEmpty) {
          body = null;
        } else {
          try {
            body = JsonReplayBody(jsonDecode(_bodyText));
          } on FormatException {
            _validationError = ComposerValidation.jsonInvalid;
            return null;
          }
        }
      case ComposerBodyKind.text:
        body = _bodyText.isEmpty ? null : TextReplayBody(_bodyText);
      case ComposerBodyKind.formUrlEncoded:
        body = FormUrlEncodedReplayBody(_toMap(_formFields));
      case ComposerBodyKind.multipart:
        body = MultipartReplayBody(
          fields: _multipartFields
              .where((row) => row.key.isNotEmpty)
              .map((row) => MultipartReplayField(row.key, row.value))
              .toList(),
          files: List.of(_multipartFiles),
        );
    }

    return NetworkReplayRequest(
      method: _method,
      uri: _mergeQuery(parsed),
      headers: _toMap(_headers),
      body: body,
    );
  }

  /// Builds the request and sends it through the selected client.
  ///
  /// Captured silently into [result]; transport failures arrive as a result
  /// with a non-null `error`, so the view renders both the same way.
  Future<void> send() async {
    final sender = _resolveSender();
    if (sender == null) {
      _validationError = ComposerValidation.noClient;
      notifyListeners();
      return;
    }
    final request = buildReplayRequest();
    if (request == null) {
      notifyListeners();
      return;
    }

    _isSending = true;
    _result = null;
    notifyListeners();

    final result = await sender.send(request);

    _isSending = false;
    _result = result;
    notifyListeners();
  }

  NetworkRequestSender? _resolveSender() {
    if (_senders.isEmpty) return null;
    return _senders.firstWhereOrNull((s) => s.id == _selectedSenderId) ??
        _senders.first;
  }

  Uri _mergeQuery(Uri uri) {
    final rows = _queryParams.where((row) => row.key.isNotEmpty);
    if (rows.isEmpty) return uri;
    final merged = <String, String>{...uri.queryParameters};
    for (final row in rows) {
      merged[row.key] = row.value;
    }
    return uri.replace(queryParameters: merged);
  }

  Uri _withoutQuery(Uri uri) => Uri(
        scheme: uri.scheme,
        userInfo: uri.userInfo.isEmpty ? null : uri.userInfo,
        host: uri.host.isEmpty ? null : uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
        fragment: uri.hasFragment ? uri.fragment : null,
      );

  Map<String, String> _toMap(List<ComposerKeyValue> rows) {
    final map = <String, String>{};
    for (final row in rows) {
      if (row.key.isNotEmpty) map[row.key] = row.value;
    }
    return map;
  }

  void _addRow(List<ComposerKeyValue> rows) {
    rows.add(ComposerKeyValue());
    notifyListeners();
  }

  void _removeRow(List<ComposerKeyValue> rows, int index) {
    rows.removeAt(index);
    notifyListeners();
  }

  /// Reconstructs a request to pre-fill the composer from a captured network
  /// [log], or `null` when the log carries no reconstructable request.
  ///
  /// Redacted header/body values are dropped by the parser so they are not
  /// resent; the registered client's interceptors re-add them at send time.
  static NetworkReplayRequest? seedFromLog(ISpectLogData log) {
    final map = _requestMapFromLog(log);
    if (map == null) return null;
    return NetworkReplayRequestParser.fromRequestMap(map)?.request;
  }

  static Map<String, dynamic>? _requestMapFromLog(ISpectLogData log) {
    final meta = log.additionalData?[TraceKeys.meta];
    if (meta is! Map) return null;
    final requestData = meta[NetworkJsonKeys.requestData];
    if (requestData is Map) return Map<String, dynamic>.from(requestData);
    final responseData = meta[NetworkJsonKeys.responseData];
    if (responseData is Map) {
      final nested = responseData[NetworkJsonKeys.request];
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }
    return null;
  }

  void _applySeed(NetworkReplayRequest seed) {
    _method = seed.method;
    final uri = seed.uri;
    if (uri.hasQuery) {
      for (final entry in uri.queryParameters.entries) {
        _queryParams.add(ComposerKeyValue(key: entry.key, value: entry.value));
      }
      _url = _withoutQuery(uri).toString();
    } else {
      _url = uri.toString();
    }
    for (final entry in seed.headers.entries) {
      _headers.add(ComposerKeyValue(key: entry.key, value: entry.value));
    }
    switch (seed.body) {
      case null:
        _bodyKind = ComposerBodyKind.none;
      case JsonReplayBody(:final value):
        _bodyKind = ComposerBodyKind.json;
        _bodyText = const JsonEncoder.withIndent('  ').convert(value);
      case TextReplayBody(:final text):
        _bodyKind = ComposerBodyKind.text;
        _bodyText = text;
      case FormUrlEncodedReplayBody(:final fields):
        _bodyKind = ComposerBodyKind.formUrlEncoded;
        for (final entry in fields.entries) {
          _formFields.add(ComposerKeyValue(key: entry.key, value: entry.value));
        }
      case MultipartReplayBody(:final fields, :final files):
        _bodyKind = ComposerBodyKind.multipart;
        for (final field in fields) {
          _multipartFields
              .add(ComposerKeyValue(key: field.name, value: field.value));
        }
        _multipartFiles.addAll(files);
    }
  }
}
