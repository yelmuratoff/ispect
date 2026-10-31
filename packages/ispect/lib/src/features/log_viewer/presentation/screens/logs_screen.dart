import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/ispect_alert_dialog.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_processing_result.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_viewer_dialogs.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_builder.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_viewer_body.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/onboarding_dialog.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/settings_bottom_sheet.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_all_logs_sheet.dart';
import 'package:ispect/src/features/log_viewer/services/file_processing_service.dart';

/// Screen for browsing, searching, and filtering application logs.
class LogsScreen extends StatefulWidget {
  const LogsScreen({
    required this.options,
    super.key,
    this.appBarTitle,
    this.controller,
    this.logs,
    this.onClearHistory,
  });

  final String? appBarTitle;
  final ISpectOptions options;
  final ISpectViewController? controller;
  final List<ISpectLogData>? logs;
  final VoidCallback? onClearHistory;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();
  late final ISpectViewController _logsViewController;
  static const _fileService = FileProcessingService();

  // Bridges controller settings to the global scope so feature-toggle flips
  // reach the inspector panel without waiting for a logs-screen rebuild.
  ISpectScopeModel? _scope;
  bool _scopeBootstrapped = false;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    _ownController = widget.controller == null;
    _logsViewController =
        widget.controller ??
        ISpectViewController(
          initialSettings: widget.options.initialSettings,
          onSettingsChanged: _handleSettingsChanged,
        );
    _logsViewController.addListener(_mirrorSettingsToScope);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ISpect.read(context);
    if (identical(_scope, scope)) return;
    _scope = scope;
    if (!_scopeBootstrapped && _ownController) {
      _scopeBootstrapped = true;
      _logsViewController.updateSettings(scope.settings);
    }
    _mirrorSettingsToScope();
  }

  void _handleSettingsChanged(ISpectSettingsState settings) {
    _scope?.settings = settings;
    widget.options.onSettingsChanged?.call(settings);
  }

  void _mirrorSettingsToScope() {
    final next = _logsViewController.settings;
    final scope = _scope;
    if (scope == null) return;
    if (scope.settings != next) {
      scope.settings = next;
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _logsViewController.removeListener(_mirrorSettingsToScope);
    if (_ownController) {
      _logsViewController.dispose();
    }
    _logsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ISpectThemeScope(child: Builder(builder: _buildScaffold));

  Widget _buildScaffold(BuildContext context) {
    final iSpect = ISpect.read(context);
    Widget buildViewer(List<ISpectLogData> data) => LogsViewerBody(
      logsData: data,
      controller: _logsViewController,
      iSpectTheme: iSpect,
      searchFocusNode: _searchFocusNode,
      logsScrollController: _logsScrollController,
      appBarTitle: widget.appBarTitle,
      onShareTap: () => _shareAllLogs(context),
      shareTooltip: _canShare(context)
          ? context.ispectL10n.shareLogsFile
          : context.ispectL10n.exportLogs,
      onMoreTap: () => _openLogsSettings(context),
    );

    return Scaffold(
      backgroundColor: context.ispectThemeBackground,
      body: switch (widget.logs) {
        final logs? => buildViewer(logs),
        null => ISpectLogsBuilder(
          logger: ISpect.logger,
          controller: _logsViewController,
          builder: (_, data) => buildViewer(data),
        ),
      },
    );
  }

  Future<void> _openLogsSettings(BuildContext context) async {
    final logger = ISpectLoggerNotifier(ISpect.logger);
    try {
      await ISpectSettingsBottomSheet(
        logger: logger,
        controller: _logsViewController,
        actions: _buildSettingsActions(context),
      ).show(context);
    } finally {
      logger.dispose();
    }
  }

  List<ISpectActionItem> _buildSettingsActions(BuildContext context) => [
    _buildShareLogsAction(context),
    if (widget.options.observer case final ISpectNavigatorObserver observer)
      _buildNavigationFlowAction(observer),
    if (ISpect.logger.fileLogHistory != null) _buildDailySessionsAction(),
    _buildImportLogsAction(),
    _buildClearHistoryAction(context),
    ...widget.options.actionItems,
    _buildTipsAction(context),
  ];

  Future<void> _confirmClearHistory(BuildContext context) async {
    final l10n = context.ispectL10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ISpectAlertDialog(
        title: Text(l10n.clearHistoryConfirmTitle),
        content: Text(l10n.clearHistoryConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.appTheme.colorScheme.error,
            ),
            child: Text(l10n.clearHistory),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _logsViewController.clearLogsHistory(
      widget.onClearHistory ?? ISpect.logger.clearHistory,
    );
  }

  Future<void> _shareAllLogs(BuildContext context) =>
      ISpectShareAllLogsBottomSheet(
        logs: widget.logs,
        onShare: widget.options.onShare,
        metadataProvider: widget.options.metadataProvider,
      ).show(context);

  ISpectActionItem _buildClearHistoryAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) => _confirmClearHistory(context),
        title: context.ispectL10n.clearHistory,
        icon: Icons.delete_outline,
        description: context.ispectL10n.clearHistoryDesc,
      );

  bool _canShare(BuildContext context) =>
      (widget.options.onShare ?? ISpect.read(context).options.onShare) != null;

  ISpectActionItem _buildShareLogsAction(BuildContext context) {
    final l10n = context.ispectL10n;
    final canShare = _canShare(context);
    return ISpectActionItem(
      onTap: (_) => _shareAllLogs(context),
      title: canShare ? l10n.shareLogsFile : l10n.exportLogs,
      icon: Icons.share_rounded,
      description: canShare ? l10n.shareLogsFileDesc : l10n.exportLogsDesc,
    );
  }

  ISpectActionItem _buildNavigationFlowAction(
    ISpectNavigatorObserver observer,
  ) => ISpectActionItem(
    title: context.ispectL10n.navigationFlow,
    icon: Icons.route_rounded,
    description: context.ispectL10n.navigationFlowDesc,
    onTap: (context) =>
        ISpectNavigationFlowScreen(observer: observer).push(context),
  );

  ISpectActionItem _buildDailySessionsAction() => ISpectActionItem(
    title: context.ispectL10n.dailySessions,
    icon: Icons.history_rounded,
    description: context.ispectL10n.dailySessionsDesc,
    onTap: (context) => DailySessionsScreen(
      history: ISpect.logger.fileLogHistory,
    ).push(context),
  );

  ISpectActionItem _buildImportLogsAction() => ISpectActionItem(
    title: context.ispectL10n.importLogs,
    icon: Icons.file_open_outlined,
    description: context.ispectL10n.importLogsDesc,
    onTap: (_) => _handleImportLogsTap(),
  );

  ISpectActionItem _buildTipsAction(BuildContext context) => ISpectActionItem(
    title: context.ispectL10n.tips,
    icon: Icons.tips_and_updates_outlined,
    onTap: (_) => ISpectOnboardingDialog.show(context),
  );

  Future<void> _handleImportLogsTap() async {
    if (!mounted) return;
    final loader = widget.options.onLoadLogContent;
    if (loader == null) {
      _showPasteDialog();
      return;
    }

    final choice = await showDialog<LogSourceChoice>(
      context: context,
      builder: (_) => const LogSourceDialog(),
    );

    if (!mounted || choice == null) return;

    switch (choice) {
      case LogSourceChoice.external:
        await _loadContentFromCallback();
      case LogSourceChoice.paste:
        _showPasteDialog();
    }
  }

  void _showPasteDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) =>
          PasteContentDialog(onContentProcessed: _processPastedContent),
    );
  }

  Future<void> _processPastedContent(String content) async {
    await _handleRawContent(content);
  }

  Future<void> _loadContentFromCallback() async {
    final loader = widget.options.onLoadLogContent;
    if (loader == null) {
      return;
    }

    String? content;
    try {
      content = await loader(context);
    } catch (error, stackTrace) {
      ISpect.logger.handle(exception: error, stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      _showContentProcessingError(context.ispectL10n.failedToLoadLogContent);
      return;
    }

    if (!mounted || content == null) {
      return;
    }

    await _handleRawContent(content);
  }

  Future<void> _handleRawContent(String content) async {
    final result = await _fileService.processPastedContentAsync(content);

    if (!mounted) {
      return;
    }

    switch (result) {
      case final FileProcessingSuccess success:
        JsonScreen(
          data: success.viewerData,
          resourceLimits: success.resourceLimits,
          processingPolicy: success.processingPolicy,
        ).push(context);
      case FileProcessingFailure(:final error):
        _showContentProcessingError(_localizedProcessingError(error));
    }
  }

  String _localizedProcessingError(FileProcessingError error) =>
      switch (error) {
        FileProcessingError.emptyContent =>
          context.ispectL10n.contentEmptyError,
        FileProcessingError.exceedsSafeLimits =>
          context.ispectL10n.contentExceedsSafeLimitsError,
      };

  void _showContentProcessingError(String? error) {
    if (!mounted) return;
    ISpectToaster.showErrorToast(
      context,
      title: context.ispectL10n.contentProcessingError,
      message: error ?? context.ispectL10n.unknownContentProcessingError,
    );
  }
}
