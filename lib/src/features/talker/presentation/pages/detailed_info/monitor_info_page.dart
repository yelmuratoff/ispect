import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/talker/presentation/widgets/log_card/log_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'view/monitor_info_view.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({
    required this.data,
    required this.typeName,
    required this.options,
    super.key,
  });

  final String typeName;
  final List<TalkerData> data;
  final ISpectOptions options;

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final _logs = <TalkerData>[];
  bool _isLogsExpanded = false;

  @override
  void initState() {
    super.initState();
    _logs.addAll(widget.data);
  }

  @override
  Widget build(BuildContext context) => _MonitorView(
        typeName: widget.typeName,
        logs: _logs,
        options: widget.options,
        onCopyTap: _copyTalkerDataItemText,
        onReverseLogsOrder: _reverseLogsOrder,
        isLogsExpanded: _isLogsExpanded,
        toggleLogsExpansion: _toggleLogsExpansion,
      );

  void _reverseLogsOrder() {
    setState(() {
      _logs.setAll(0, _logs.reversed.toList());
    });
  }

  void _toggleLogsExpansion() {
    setState(() {
      _isLogsExpanded = !_isLogsExpanded;
    });
  }

  void _copyTalkerDataItemText(BuildContext context, TalkerData data) {
    final text = data.generateTextMessage();
    copyClipboard(context, value: text);
  }
}
