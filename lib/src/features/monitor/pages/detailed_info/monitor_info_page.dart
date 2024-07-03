import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
import 'package:ispect/src/common/widgets/widget/data_card.dart';
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
  final List<TalkerData> logs = [];
  bool _isLogsExpanded = false;

  @override
  void initState() {
    logs.addAll(widget.data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _MonitorView(
        typeName: widget.typeName,
        logs: logs,
        options: widget.options,
        onCopyTap: (itemContext, data) =>
            _copyTalkerDataItemText(itemContext, data),
        onReverseLogsOrder: _reverseLogsOrder,
        isLogsExpanded: _isLogsExpanded,
        toggleLogsExpansion: _toggleLogsExpansion,
      );

  void _reverseLogsOrder() {
    setState(() {
      logs.setAll(0, logs.reversed.toList());
    });
  }

  void _toggleLogsExpansion() {
    setState(() {
      _isLogsExpanded = !_isLogsExpanded;
    });
  }

  void _copyTalkerDataItemText(BuildContext context, TalkerData data) {
    final text = data.generateTextMessage();
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(context, context.ispectL10n.logItemCopied);
  }

  void _showSnackBar(BuildContext context, String text) {
    ISpectToaster.showInfoToast(
      context,
      title: context.ispectL10n.copiedToClipboard,
    );
  }
}
