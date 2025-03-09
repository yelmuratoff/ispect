import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/json_viewer/pretty_json_view.dart';

class DetailedLogScreen extends StatefulWidget {
  const DetailedLogScreen({required this.data, super.key});
  final ISpectifyData data;

  @override
  State<DetailedLogScreen> createState() => _DetailedLogScreenState();
}

class _DetailedLogScreenState extends State<DetailedLogScreen> {
  late final ISpectifyData _data;

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
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                copyClipboard(context, value: prettyJson(_data.toJson()));
              },
            ),
          ),
        ],
      ),
      body: JsonTreeView(
        showControls: true,
        json: _data.toJson(),
        searchHighlightColor: context.ispectTheme.colorScheme.primary,
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
        _ => 'Detailed log: $key',
      };
}
