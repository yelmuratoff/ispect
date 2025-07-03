// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/datetime.dart';
import 'package:ispectify/ispectify.dart';

class DailySessionsScreen extends StatefulWidget {
  const DailySessionsScreen({required this.history, super.key});

  final FileLogHistory? history;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: RouteSettings(
          name: 'ISpect Daily Sessions Screen',
          arguments: history != null
              ? {
                  'directory': history!.sessionDirectory,
                }
              : null,
        ),
      ),
    );
  }

  @override
  State<DailySessionsScreen> createState() => _DailySessionsScreenState();
}

class _DailySessionsScreenState extends State<DailySessionsScreen> {
  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  Future<void> _loadSessions() async {
    print('Loading daily sessions...');
    print('Path: ${widget.history?.sessionDirectory}');
    if (widget.history == null) return;
    _dates
      ..clear()
      ..addAll(await widget.history!.getAvailableLogDates());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Daily Sessions'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actionsPadding: const EdgeInsets.only(right: 12),
        ),
        body: widget.history == null
            ? const Center(
                child: Text('No Daily Sessions'),
              )
            : ListView.builder(
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final session = _dates[index];
                  return ListTile(
                    title: Text(
                      // '${session.day}.${session.month}.${session.year}',
                      session.toFormattedString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: FutureBuilder<int>(
                      future: widget.history!.getDateFileSize(session),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final sizeKB =
                              (snapshot.data! / 1024).toStringAsFixed(1);
                          return Text('File size: $sizeKB KB');
                        }
                        return const Text('Loading...');
                      },
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      try {
                        final logs =
                            await widget.history!.getLogsByDate(session);
                        if (context.mounted) {
                          _showDailyLogsDialog(context, session, logs);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showErrorDialog(context, 'Failed to load logs: $e');
                        }
                      }
                    },
                  );
                },
              ),
      );

  void _showDailyLogsDialog(
    BuildContext context,
    DateTime date,
    List<ISpectifyData> logs,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logs for ${date.day}/${date.month}/${date.year}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: logs.isEmpty
              ? const Center(child: Text('No logs found for this date'))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          log.message ?? 'No message',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${log.time.hour.toString().padLeft(2, '0')}:'
                          '${log.time.minute.toString().padLeft(2, '0')}:'
                          '${log.time.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLogLevelColor(
                              log.logLevel ?? LogLevel.info,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (log.logLevel?.name ?? 'info').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}
