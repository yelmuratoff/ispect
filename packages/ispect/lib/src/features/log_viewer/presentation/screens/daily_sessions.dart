// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/datetime.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/debug_report.dart';
import 'package:ispect/src/common/utils/desktop_metrics.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_alert_dialog.dart';
import 'package:ispect/src/common/widgets/ispect_app_bar_title.dart';
import 'package:ispect/src/common/widgets/ispect_flat_app_bar.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/session_logs_screen.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/empty_logs_widget.dart';

class DailySessionsScreen extends StatefulWidget {
  const DailySessionsScreen({required this.history, super.key});

  final FileLogHistory? history;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: RouteSettings(
          name: 'ISpect Daily Sessions Screen',
          arguments: history != null ? {'file-history-configured': true} : null,
        ),
      ),
    );
  }

  @override
  State<DailySessionsScreen> createState() => _DailySessionsScreenState();
}

class _DailySessionsScreenState extends State<DailySessionsScreen> {
  final List<DateTime> _dates = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
  }

  Future<void> _openPath() async {
    final history = widget.history;
    if (history == null) {
      return;
    }

    final openFile = context.iSpect.options.onOpenFile;
    if (openFile == null) {
      return;
    }

    await openFile(history.sessionDirectory);
  }

  Future<void> _copyPathToClipboard() async {
    final history = widget.history;
    if (history == null) {
      return;
    }

    copyClipboard(
      context,
      value: history.sessionDirectory,
      title: '✅ ${context.ispectL10n.sessionsPathCopied}',
    );
  }

  void _retryLoad() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    unawaited(_loadSessions());
  }

  Future<void> _loadSessions({bool isRefreshing = false}) async {
    final history = widget.history;
    if (history == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final epoch = ++_loadEpoch;
    final List<DateTime> availableDates;
    try {
      availableDates = await history.getAvailableLogDates();
    } on Exception catch (error, stackTrace) {
      if (epoch != _loadEpoch) return;
      ISpect.logger.handle(
        exception: error,
        stackTrace: stackTrace,
        message: 'Failed to list daily sessions',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
      return;
    }
    if (epoch != _loadEpoch) return;
    _dates
      ..clear()
      ..addAll(availableDates.reversed);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadFailed = false;
      });

      if (isRefreshing) {
        await ISpectToaster.showInfoToast(
          context,
          title: '✅ ${context.ispectL10n.dailySessionsRefreshed}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      ISpectThemeScope(child: Builder(builder: _buildScaffold));

  Widget _buildScaffold(BuildContext context) => Scaffold(
    backgroundColor: context.ispectThemeBackground,
    appBar: ISpectFlatAppBar(
      title: ISpectAppBarTitle(child: Text(context.ispectL10n.sessions)),
      leading: const ISpectAppBarBackButton(),
      actionsPadding: const EdgeInsets.only(right: 12),
      actions: [
        ISpectAppBarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: context.ispectL10n.refresh,
          onPressed: () => _loadSessions(isRefreshing: true),
        ),
        if (widget.history != null)
          ISpectAppBarIconButton(
            icon: Icons.clear_all_rounded,
            tooltip: context.ispectL10n.clearAllSessions,
            onPressed: _showClearAllDialog,
          ),
        if (widget.history != null)
          PopupMenuButton<Future<void> Function()>(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: context.ispectAppBarIconSize,
            ),
            tooltip: context.ispectL10n.moreOptions,
            onSelected: (action) => unawaited(
              action().catchError((Object error, StackTrace stackTrace) {
                ISpect.logger.handle(
                  exception: error,
                  stackTrace: stackTrace,
                  message: 'Failed to open the sessions folder',
                );
              }),
            ),
            itemBuilder: (context) => [
              if (context.iSpect.options.onOpenFile != null)
                PopupMenuItem(
                  value: _openPath,
                  child: _MenuRow(
                    icon: Icons.open_in_new_rounded,
                    label: context.ispectL10n.openPath,
                  ),
                ),
              PopupMenuItem(
                value: _copyPathToClipboard,
                child: _MenuRow(
                  icon: Icons.copy_rounded,
                  label: context.ispectL10n.copyPath,
                ),
              ),
            ],
          ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator.adaptive())
        : _loadFailed
        ? _SessionsLoadError(onRetry: _retryLoad)
        : _dates.isEmpty
        ? const EmptyLogsWidget(reason: EmptyLogsReason.noSessions)
        : ListView.builder(
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final session = _dates[index];
              return _SessionListTile(
                key: ObjectKey(session),
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
      builder: (context) => ISpectAlertDialog(
        title: Text(context.ispectL10n.clearAllSessions),
        content: Text(context.ispectL10n.confirmClearAllDailySessions),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.ispectL10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await widget.history?.clearAllFileStorage();
              } on Exception catch (error, stackTrace) {
                ISpect.logger.handle(
                  exception: error,
                  stackTrace: stackTrace,
                  message: 'Failed to clear daily sessions',
                );
                if (context.mounted) Navigator.of(context).pop();
                _showClearErrorToast();
                return;
              }
              if (context.mounted) {
                Navigator.of(context).pop();
                await _loadSessions(isRefreshing: true);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: context.appTheme.colorScheme.error,
            ),
            child: Text(context.ispectL10n.clearAllSessions),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSession(DateTime session) async {
    if (!mounted) return;

    await SessionLogsScreen(
      sessionDate: session,
      onShare: context.iSpect.options.onShare,
      metadataProvider: context.iSpect.options.metadataProvider,
    ).push(context);
  }

  void _showClearErrorToast() {
    if (!mounted) return;
    ISpectToaster.showErrorToast(
      context,
      title: context.ispectL10n.error,
      message: context.ispectL10n.dailySessionsClearFailed,
    );
  }
}

class _SessionsLoadError extends StatelessWidget {
  const _SessionsLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appTheme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: colorScheme.error,
            ),
            const Gap(12),
            Text(
              context.ispectL10n.error,
              style: context.appTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(4),
            Text(
              context.ispectL10n.dailySessionsLoadFailed,
              textAlign: TextAlign.center,
              style: context.appTheme.textTheme.bodyMedium?.copyWith(
                color: context.appTheme.textColor.withValues(alpha: 0.6),
              ),
            ),
            const Gap(12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.ispectL10n.retry),
            ),
          ],
        ),
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
  bool _fileSizeFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchFileSize();
  }

  Future<void> _fetchFileSize() async {
    try {
      final size = await widget.history.getDateFileSize(widget.session);
      if (mounted) {
        setState(() {
          _fileSize = size;
        });
      }
    } on Exception catch (error, stackTrace) {
      ISpect.logger.handle(
        exception: error,
        stackTrace: stackTrace,
        message: 'Failed to read a daily session file size',
      );
      if (mounted) setState(() => _fileSizeFailed = true);
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
      style: context.appTheme.textTheme.titleSmall,
    ),
    subtitle: _fileSize != null
        ? Text(
            '${context.ispectL10n.fileSize}: ${(_fileSize! / 1024).toStringAsFixed(1)} KB',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w300,
            ),
          )
        : _fileSizeFailed
        ? null
        : Text(
            '${context.ispectL10n.loading}...',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w300,
            ),
          ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (context.iSpect.options.onOpenFile != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () {
              _navigateToSession(widget.session);
            },
          ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ],
    ),
    onTap: widget.onTap,
  );

  Future<void> _navigateToSession(DateTime session) async {
    final fileLogHistory = ISpect.logger.fileLogHistory;
    final openFile = context.iSpect.options.onOpenFile;
    final path = await fileLogHistory?.getLogPathByDate(session);
    if (path != null && openFile != null) {
      unawaited(
        openFile(path).catchError(
          (Object error) => debugReportFailure('Failed to open file', error),
        ),
      );
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 18), const Gap(12), Text(label)],
  );
}
