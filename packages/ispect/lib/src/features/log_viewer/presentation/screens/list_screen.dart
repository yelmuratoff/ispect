import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';

/// Browses an independent, immutable set of logs (a file-history session or a
/// caller-supplied list) using the same viewer as the live logs screen.
///
/// Unlike [LogsScreen], this screen does not observe [ISpect.logger]; it
/// renders whatever [logs] / session it resolves once.
class LogsV2Screen extends StatefulWidget {
  const LogsV2Screen({
    this.logs,
    super.key,
    this.appBarTitle,
    this.sessionPath,
    this.sessionDate,
    this.onShare,
    this.metadataProvider,
  });

  final String? appBarTitle;
  final List<ISpectLogData>? logs;
  final String? sessionPath;
  final DateTime? sessionDate;
  final ISpectShareCallback? onShare;
  final ISpectMetadataProvider? metadataProvider;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect V2 Screen'),
      ),
    );
  }

  @override
  State<LogsV2Screen> createState() => _LogsV2ScreenState();
}

class _LogsV2ScreenState extends State<LogsV2Screen> {
  List<ISpectLogData> _logs = const [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ISpect.read(context);
    return LogsScreen(
      options: scope.options.copyWith(
        onShare: widget.onShare,
        metadataProvider: widget.metadataProvider,
      ),
      appBarTitle: widget.appBarTitle ?? scope.theme.pageTitle,
      logs: _logs,
      onClearHistory: _clearLogs,
    );
  }

  void _clearLogs() => setState(() => _logs = const []);

  Future<void> _loadLogs() async {
    List<ISpectLogData>? logs;
    if (widget.logs != null) {
      logs = widget.logs;
    } else if (widget.sessionPath != null) {
      final fileLogHistory = ISpect.logger.fileLogHistory;
      logs = await fileLogHistory?.getLogsBySession(widget.sessionPath!);
    } else if (widget.sessionDate != null) {
      final fileLogHistory = ISpect.logger.fileLogHistory;
      logs = await fileLogHistory?.getLogsByDate(widget.sessionDate!);
    }
    if (!mounted) return;
    setState(
      () => _logs = List<ISpectLogData>.unmodifiable(logs ?? const []),
    );
  }
}
