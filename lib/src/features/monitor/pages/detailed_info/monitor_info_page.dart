import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
import 'package:ispect/src/common/widgets/widget/data_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'view/monitor_info_view.dart';

class MonitorPage extends StatelessWidget {
  const MonitorPage({
    required this.exceptions,
    required this.theme,
    required this.typeName,
    required this.options,
    super.key,
  });

  final String typeName;
  final TalkerScreenTheme theme;
  final List<TalkerData> exceptions;
  final ISpectOptions options;

  @override
  Widget build(BuildContext context) => _MonitorView(
        typeName: typeName,
        theme: theme,
        exceptions: exceptions,
        options: options,
        onCopyTap: (itemContext, data) =>
            _copyTalkerDataItemText(itemContext, data),
      );

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
