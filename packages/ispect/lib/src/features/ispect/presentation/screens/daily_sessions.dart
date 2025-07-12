// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/datetime.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/ispect/presentation/screens/list_screen.dart';

class DailySessionsScreen extends StatefulWidget {
  const DailySessionsScreen({required this.history, super.key});

  final FileLogHistory? history;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: RouteSettings(
          name: 'ISpect Daily Sessions Screen',
          arguments:
              history != null ? {'directory': history!.sessionDirectory} : null,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
  }

  Future<void> _copyPathToClipboard() async {
    final history = widget.history;
    if (history == null) {
      return;
    }

    copyClipboard(
      context,
      value: history.sessionDirectory,
      title: '✅ Sessions Path Copied',
    );
  }

  Future<void> _loadSessions({bool isRefreshing = false}) async {
    final history = widget.history;
    if (history == null) {
      return;
    }

    final availableDates = await history.getAvailableLogDates();
    _dates
      ..clear()
      ..addAll(availableDates.reversed);

    if (mounted) {
      setState(() {});

      if (isRefreshing) {
        await ISpectToaster.showInfoToast(
          context,
          title: '✅ Daily sessions refreshed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sessions',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actionsPadding: const EdgeInsets.only(right: 12),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: _copyPathToClipboard,
              tooltip: 'Copy path',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _loadSessions(isRefreshing: true),
              tooltip: 'Refresh',
            ),
            if (widget.history != null)
              IconButton(
                icon: const Icon(Icons.clear_all_rounded),
                onPressed: _showClearAllDialog,
                tooltip: 'Clear All Sessions',
              ),
          ],
        ),
        body: _dates.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 16, left: 16),
                child: EmptyLogsWidget(),
              )
            : ListView.builder(
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final session = _dates[index];
                  return _SessionListTile(
                    key: ValueKey(session.hashCode),
                    session: session,
                    history: widget.history!,
                    onTap: () => _navigateToSession(session),
                  );
                },
              ),
      );

  void _showClearAllDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all Sessions'),
        content: const Text(
          'Are you sure you want to clear all daily sessions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget.history?.clearAllFileStorage();
              if (context.mounted) {
                Navigator.of(context).pop();
                await _loadSessions(isRefreshing: true);
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSession(DateTime session) async {
    try {
      if (!mounted) {
        return;
      }

      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: RouteSettings(
              name: 'ISpect Daily Session Logs',
              arguments: {'date': session.toIso8601String()},
            ),
            builder: (_) => LogsV2Screen(sessionDate: session),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to load logs: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
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
}

class _SessionListTile extends StatefulWidget {
  const _SessionListTile({
    required this.session,
    required this.history,
    required this.onTap,
    super.key,
  });

  final DateTime session;
  final FileLogHistory history;
  final VoidCallback onTap;

  @override
  State<_SessionListTile> createState() => _SessionListTileState();
}

class _SessionListTileState extends State<_SessionListTile> {
  int? _fileSize;

  @override
  void initState() {
    super.initState();
    _fetchFileSize();
  }

  Future<void> _fetchFileSize() async {
    final size = await widget.history.getDateFileSize(widget.session);
    if (mounted) {
      setState(() {
        _fileSize = size;
      });
    }
  }

  String _getSessionTitle(DateTime date) {
    if (date.isToday) {
      return '📅 ${context.ispectL10n.current}: ${date.toFormattedString()}';
    }
    return date.toFormattedString();
  }

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(
          _getSessionTitle(widget.session),
          style: context.ispectTheme.textTheme.titleSmall,
        ),
        subtitle: _fileSize != null
            ? Text(
                'File size: ${(_fileSize! / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              )
            : const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
        ),
        onTap: widget.onTap,
      );
}
