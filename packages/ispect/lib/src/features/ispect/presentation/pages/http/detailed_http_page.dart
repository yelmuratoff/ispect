import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/json_viewer/pretty_json_view.dart';

class DetailedHTTPPage extends StatefulWidget {
  const DetailedHTTPPage({required this.data, super.key});
  final ISpectiyData data;

  @override
  State<DetailedHTTPPage> createState() => _DetailedHTTPPageState();
}

class _DetailedHTTPPageState extends State<DetailedHTTPPage> {
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
      body: JsonTreeView(
        showControls: true,
        jsonString: json.encode(_data.toJson()),
        keyStyle: TextStyle(
          color: context.ispectTheme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        valueStyle: TextStyle(
          color: context.ispectTheme.colorScheme.secondary,
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
