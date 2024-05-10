// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/features/monitor/pages/detailed_info/monitor_info_page.dart';
import 'package:talker_flutter/src/ui/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

part '../../widgets/monitor_card.dart';
part 'view/monitor_view.dart';

class TalkerMonitorPage extends StatelessWidget {
  const TalkerMonitorPage({
    required this.theme,
    required this.options,
    super.key,
  });

  final TalkerScreenTheme theme;
  final ISpectOptions options;

  @override
  Widget build(BuildContext context) => _MonitorView(
        theme: theme,
        options: options,
        openTypedLogsPage: (list, type) {
          _openTypedLogsScreen(context, list, type);
        },
      );

  void _openTypedLogsScreen(
    BuildContext context,
    List<TalkerData> logs,
    String typeName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (context) => MonitorPage(
          exceptions: logs,
          theme: theme,
          typeName: typeName,
          options: options,
        ),
      ),
    );
  }
}
