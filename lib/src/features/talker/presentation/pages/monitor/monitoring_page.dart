// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/talker/presentation/pages/detailed_info/monitor_info_page.dart';
import 'package:ispect/src/features/talker/presentation/widgets/monitor_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TalkerMonitorPage extends StatefulWidget {
  const TalkerMonitorPage({
    required this.options,
    super.key,
  });

  final ISpectOptions options;

  @override
  State<TalkerMonitorPage> createState() => _TalkerMonitorPageState();
}

class _TalkerMonitorPageState extends State<TalkerMonitorPage> {
  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: iSpect.theme.backgroundColor(context),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'ISpect monitoring',
            style: context.ispectTheme.textTheme.titleMedium,
          ),
        ),
      ),
      body: TalkerBuilder(
        talker: ISpect.talker,
        builder: (context, data) {
          // TODO(Yelaman): Change to uniqKeys when it will be implemented.
          final titles = data.map((e) => e.title).toList();
          final uniqTitles = titles.toSet().toList()..sort();

          return CustomScrollView(
            slivers: [
              ...uniqTitles.map((title) {
                final logs = data.where((e) => e.title == title).toList();
                return SliverToBoxAdapter(
                  child: TalkerMonitorsCard(
                    logs: logs,
                    title: title ?? '',
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: title,
                    ),
                    icon: iSpect.theme.logIcons[title] ?? Icons.bug_report_rounded,
                    subtitle: 'Logs count: ${logs.length}',
                    onTap: () => _openTypedLogsScreen(
                      context,
                      logs,
                      title ?? '',
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

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
          options: widget.options,
        ),
        settings: RouteSettings(
          name: 'MonitorPage',
          arguments: typeName,
        ),
      ),
    );
  }
}
