import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/datetime.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_app_bar_title.dart';
import 'package:ispect/src/common/widgets/ispect_flat_app_bar.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/session_logs_screen.dart';
import 'package:material_ui/material_ui.dart';

class DayLaunchesScreen extends StatelessWidget {
  DayLaunchesScreen({
    required this.date,
    required this.dayLogs,
    required this.launches,
    super.key,
  }) : _dayErrorCount = launches.fold(0, (sum, l) => sum + l.errorCount);

  final DateTime date;
  final List<ISpectLogData> dayLogs;
  final List<LaunchLogs> launches;
  final int _dayErrorCount;

  Future<void> push(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => this,
      settings: RouteSettings(
        name: 'ISpect Day Launches Screen',
        arguments: {'date': date.toIso8601String()},
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      ISpectThemeScope(child: Builder(builder: _buildScaffold));

  Widget _buildScaffold(BuildContext context) => Scaffold(
    backgroundColor: context.ispectThemeBackground,
    appBar: ISpectFlatAppBar(
      title: ISpectAppBarTitle(child: Text(sessionDayTitle(context, date))),
      leading: const ISpectAppBarBackButton(),
    ),
    body: ListView(
      children: [
        _LaunchTile(
          key: const ValueKey('ispect-launch-all'),
          title: context.ispectL10n.allLaunches,
          logCount: dayLogs.length,
          errorCount: _dayErrorCount,
          onTap: () => _openLogs(context, logs: dayLogs, title: null),
        ),
        const Divider(height: 1),
        for (final launch in launches)
          _LaunchTile(
            key: ValueKey('ispect-launch-${launch.id ?? 'unknown'}'),
            title: _launchTitle(context, launch),
            logCount: launch.logs.length,
            errorCount: launch.errorCount,
            onTap: () => _openLogs(
              context,
              logs: launch.logs,
              title: _launchLogsTitle(context, launch),
            ),
          ),
      ],
    ),
  );

  String _launchTitle(BuildContext context, LaunchLogs launch) {
    if (launch.id == null) return context.ispectL10n.unknownLaunch;
    final start = launch.startedAt.toTimeString();
    final end = launch.endedAt.toTimeString();
    return start == end ? start : '$start – $end';
  }

  String _launchLogsTitle(BuildContext context, LaunchLogs launch) {
    final label = launch.id == null
        ? context.ispectL10n.unknownLaunch
        : launch.startedAt.toTimeString();
    return '${date.toFormattedString()} · $label';
  }

  Future<void> _openLogs(
    BuildContext context, {
    required List<ISpectLogData> logs,
    required String? title,
  }) => SessionLogsScreen(
    logs: logs,
    sessionDate: date,
    appBarTitle: title,
    onShare: context.iSpect.options.onShare,
    metadataProvider: context.iSpect.options.metadataProvider,
  ).push(context);
}

class _LaunchTile extends StatelessWidget {
  const _LaunchTile({
    required this.title,
    required this.logCount,
    required this.onTap,
    this.errorCount = 0,
    super.key,
  });

  final String title;
  final int logCount;
  final int errorCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: theme.textColor.withValues(alpha: 0.6),
    );
    final errorColor = theme.colorScheme.error;
    return ListTile(
      dense: true,
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(context.ispectL10n.logCount(logCount), style: subtle),
          if (errorCount > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: errorColor),
                const Gap(4),
                Text(
                  context.ispectL10n.errorCount(errorCount),
                  style: subtle?.copyWith(color: errorColor),
                ),
              ],
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
