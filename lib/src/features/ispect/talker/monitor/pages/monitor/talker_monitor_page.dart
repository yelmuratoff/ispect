// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/features/ispect/talker/monitor/pages/detailed_info/monitor_info_page.dart';
import 'package:talker_flutter/src/ui/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

part '../../widgets/monitor_card.dart';
part 'view/monitor_view.dart';

class TalkerMonitorPage extends StatelessWidget {
  const TalkerMonitorPage({
    required this.options,
    super.key,
  });

  final ISpectOptions options;

  @override
  Widget build(BuildContext context) => _MonitorView(
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
        builder: (_) => MonitorPage(
          data: logs,
          typeName: typeName,
          options: options,
        ),
      ),
    );
  }
}
