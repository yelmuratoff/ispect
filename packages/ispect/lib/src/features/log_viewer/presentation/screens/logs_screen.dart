import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/log_correlation_index.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_processing_result.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_viewer_dialogs.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_builder.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/main_logs_view.dart';
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
  });

  final String? appBarTitle;
  final ISpectOptions options;
  final ISpectViewController? controller;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _titleFiltersController = GroupButtonController();
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();
  late final ISpectViewController _logsViewController;
  static const _fileService = FileProcessingService();

  /// Persisted split ratio so it survives detail panel toggling.
  double _splitRatio = 0.4;

  /// Correlation index for O(1) request↔response/error lookup in the
  /// detail panel. Rebuilt lazily when the input list identity changes.
  final _correlationIndex = LogCorrelationIndex();

  // Bridges controller settings to the global scope so feature-toggle flips
  // reach the inspector panel without waiting for a logs-screen rebuild.
  ISpectScopeModel? _scope;
  bool _scopeBootstrapped = false;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    _ownController = widget.controller == null;
    _logsViewController = widget.controller ??
        ISpectViewController(
          onShare: widget.options.onShare,
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
    final scope = _scope;
    if (scope == null) return;
    final next = _logsViewController.settings;
    if (scope.settings != next) {
      scope.settings = next;
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _titleFiltersController.dispose();
    _logsViewController.removeListener(_mirrorSettingsToScope);
    if (_ownController) {
      _logsViewController.dispose();
    }
    _logsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final isDesktop = context.screenSize.isDesktop;
    return Scaffold(
      backgroundColor: iSpect.theme.background?.resolve(context),
      body: ISpectLogsBuilder(
        logger: ISpect.logger,
        controller: _logsViewController,
        builder: (context, data) => ListenableBuilder(
          listenable: _logsViewController,
          builder: (_, __) {
            // Desktop uses detailData for the panel; mobile/tablet uses activeData.
            final hasDetail = isDesktop
                ? _logsViewController.detailData != null
                : _logsViewController.activeData != null;
            final showDetailPanel = hasDetail && !context.screenSize.isPhone;

            final logsView = MainLogsView(
              logsData: data,
              iSpectTheme: iSpect,
              titleFiltersController: _titleFiltersController,
              searchFocusNode: _searchFocusNode,
              logsScrollController: _logsScrollController,
              logsViewController: _logsViewController,
              appBarTitle: widget.appBarTitle,
              onSettingsTap: () => _openLogsSettings(context),
              hasDetailPanel: showDetailPanel,
            );

            if (!showDetailPanel) {
              return logsView;
            }

            final activeForDetail = isDesktop
                ? _logsViewController.detailData!
                : _logsViewController.activeData!;

            // Find correlated log for cross-navigation.
            final correlation = _findCorrelation(
              activeForDetail,
              data,
            );

            final detailView = LogDetailView(
              activeData: activeForDetail,
              onClose: () {
                if (isDesktop) {
                  _logsViewController.closeDetail();
                } else {
                  _logsViewController.activeData = null;
                }
              },
              correlatedLog: correlation?.log,
              correlationDuration: correlation?.duration,
              onNavigateToCorrelated: correlation?.log != null
                  ? () {
                      if (isDesktop) {
                        _logsViewController
                            .selectAndFollowDetail(correlation!.log!);
                      } else {
                        _logsViewController.activeData = correlation!.log;
                      }
                    }
                  : null,
              onShowRelated: (id) {
                _logsViewController.searchByCorrelationId(id);
              },
            );

            if (isDesktop) {
              return ResizableSplitView(
                initialRatio: _splitRatio,
                minRatio: 0.35,
                maxRatio: 0.65,
                onRatioChanged: (ratio) => _splitRatio = ratio,
                left: logsView,
                right: detailView,
              );
            }

            // Tablet: fixed split, no drag.
            return Row(
              children: [
                Expanded(flex: 5, child: logsView),
                VerticalDivider(
                  color: context.ispectTheme.divider?.resolve(context),
                  width: 1,
                  thickness: 1,
                ),
                Expanded(flex: 5, child: detailView),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Finds a correlated log entry for the given [activeLog].
  ///
  /// Delegates to [LogCorrelationIndex] for an O(1) lookup by requestId,
  /// returning the opposite role (request → response/error, response/error
  /// → request).
  LogCorrelation? _findCorrelation(
    ISpectLogData activeLog,
    List<ISpectLogData> allLogs,
  ) =>
      _correlationIndex.find(
        activeLog,
        allLogs,
        _logsViewController.outputGeneration,
      );

  Future<void> _openLogsSettings(BuildContext context) async {
    final logger = ISpectLoggerNotifier(ISpect.logger);
    try {
      await ISpectSettingsBottomSheet(
        options: widget.options,
        logger: logger,
        controller: _logsViewController,
        actions: _buildSettingsActions(context),
      ).show(context);
    } finally {
      logger.dispose();
    }
  }

  List<ISpectActionItem> _buildSettingsActions(BuildContext context) => [
        _buildReverseLogsAction(context),
        _buildGroupHttpAction(context),
        _buildShareLogsAction(context),
        _buildExpandLogsAction(context),
        _buildClearHistoryAction(context),
        if (widget.options.observer case final ISpectNavigatorObserver observer)
          _buildNavigationFlowAction(observer),
        if (ISpect.logger.fileLogHistory != null) _buildDailySessionsAction(),
        _buildLogViewerAction(),
        ...widget.options.actionItems,
      ];

  ISpectActionItem _buildGroupHttpAction(BuildContext context) {
    final isGrouped = _logsViewController.groupHttpLogs;
    return ISpectActionItem(
      onTap: (_) => _logsViewController.toggleGroupHttpLogs(),
      title: isGrouped
          ? context.ispectL10n.ungroupHttpLogs
          : context.ispectL10n.groupHttpLogs,
      icon:
          isGrouped ? Icons.account_tree_rounded : Icons.account_tree_outlined,
      description: isGrouped
          ? context.ispectL10n.ungroupHttpLogsDesc
          : context.ispectL10n.groupHttpLogsDesc,
    );
  }

  ISpectActionItem _buildReverseLogsAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) => _logsViewController.toggleLogOrder(),
        title: context.ispectL10n.reverseLogs,
        icon: Icons.swap_vert,
        description: context.ispectL10n.reverseLogsDesc,
      );

  ISpectActionItem _buildExpandLogsAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) => _logsViewController.toggleExpandedLogs(),
        title: _logsViewController.expandedLogs
            ? context.ispectL10n.collapseLogs
            : context.ispectL10n.expandLogs,
        icon: _logsViewController.expandedLogs
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        description: _logsViewController.expandedLogs
            ? context.ispectL10n.collapseLogsDesc
            : context.ispectL10n.expandLogsDesc,
      );

  ISpectActionItem _buildClearHistoryAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) =>
            _logsViewController.clearLogsHistory(ISpect.logger.clearHistory),
        title: context.ispectL10n.clearHistory,
        icon: Icons.delete_outline,
        description: context.ispectL10n.clearHistoryDesc,
      );

  ISpectActionItem _buildShareLogsAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) => const ISpectShareAllLogsBottomSheet().show(context),
        title: context.ispectL10n.shareLogsFile,
        icon: Icons.ios_share_outlined,
        description: context.ispectL10n.shareLogsFileDesc,
      );

  ISpectActionItem _buildNavigationFlowAction(
    ISpectNavigatorObserver observer,
  ) =>
      ISpectActionItem(
        title: context.ispectL10n.navigationFlow,
        icon: Icons.route_rounded,
        description: context.ispectL10n.navigationFlowDesc,
        onTap: (context) => ISpectNavigationFlowScreen(
          observer: observer,
        ).push(context),
      );

  ISpectActionItem _buildDailySessionsAction() => ISpectActionItem(
        title: context.ispectL10n.dailySessions,
        icon: Icons.history_rounded,
        description: context.ispectL10n.dailySessionsDesc,
        onTap: (context) => DailySessionsScreen(
          history: ISpect.logger.fileLogHistory,
        ).push(context),
      );

  ISpectActionItem _buildLogViewerAction() => ISpectActionItem(
        title: context.ispectL10n.logViewer,
        icon: Icons.developer_mode_rounded,
        description: context.ispectL10n.logViewerDesc,
        onTap: (_) => _handleLogViewerTap(),
      );

  Future<void> _handleLogViewerTap() async {
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
      builder: (context) => PasteContentDialog(
        onContentProcessed: _processPastedContent,
      ),
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
      _showContentProcessingError('Failed to load log content');
      return;
    }

    if (!mounted || content == null) {
      return;
    }

    await _handleRawContent(content);
  }

  Future<void> _handleRawContent(String content) async {
    final result = _fileService.processPastedContent(content);

    if (!mounted) {
      return;
    }

    switch (result) {
      case final FileProcessingResult r when r.success:
        await r.action(context);
        return;
      case final FileProcessingResult r:
        _showContentProcessingError(r.error);
    }
  }

  void _showContentProcessingError(String? error) {
    if (!mounted) return;
    ISpectToaster.showErrorToast(
      context,
      title: 'Content Processing Error',
      message: error ?? 'Unknown error occurred while processing content',
    );
  }
}
