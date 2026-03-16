import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/controllers/logs_screen_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/network_transaction_service.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/builder/widget_builder.dart';
import 'package:ispect/src/common/widgets/gap/sliver_gap.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';
import 'package:ispect/src/features/ispect/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/desktop_status_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/empty_logs_widget.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/desktop_log_row.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_list_item.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/network_transaction_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_detail_view.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_scroll_indicators.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_viewer_dialogs.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/onboarding_dialog.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_all_logs_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_log_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/services/file_processing_service.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Screen for browsing, searching, and filtering application logs.
class LogsScreen extends StatefulWidget {
  const LogsScreen({
    required this.options,
    super.key,
    this.appBarTitle,
    this.itemsBuilder,
    this.controller,
  });

  final String? appBarTitle;
  final ISpectLogDataBuilder? itemsBuilder;
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

  @override
  void initState() {
    super.initState();
    _logsViewController = widget.controller ??
        ISpectViewController(
          onShare: widget.options.onShare,
          initialSettings: widget.options.initialSettings,
        );
    _logsViewController.expandedLogs = false;
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _titleFiltersController.dispose();
    // Dispose only if we own the controller instance.
    if (widget.controller == null) {
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

            final logsView = _MainLogsView(
              logsData: data,
              iSpectTheme: iSpect,
              titleFiltersController: _titleFiltersController,
              searchFocusNode: _searchFocusNode,
              logsScrollController: _logsScrollController,
              logsViewController: _logsViewController,
              appBarTitle: widget.appBarTitle,
              itemsBuilder: widget.itemsBuilder,
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
  /// For a response/error, returns the matching request (and vice versa)
  /// using the requestId stored in additionalData.
  ({ISpectLogData? log, Duration? duration})? _findCorrelation(
    ISpectLogData activeLog,
    List<ISpectLogData> allLogs,
  ) {
    if (!activeLog.isHttpLog) return null;

    final requestId = activeLog.additionalData?[kRequestIdKey] as String?;
    if (requestId == null) return null;

    final isRequest = activeLog.key == ISpectLogType.httpRequest.key;

    for (final log in allLogs) {
      if (identical(log, activeLog)) continue;
      final logRid = log.additionalData?[kRequestIdKey] as String?;
      if (logRid != requestId) continue;

      // If viewing request, find its response/error.
      // If viewing response/error, find the request.
      if (isRequest && log.key != ISpectLogType.httpRequest.key) {
        return (
          log: log,
          duration: log.time.difference(activeLog.time),
        );
      }
      if (!isRequest && log.key == ISpectLogType.httpRequest.key) {
        return (
          log: log,
          duration: activeLog.time.difference(log.time),
        );
      }
    }
    return null;
  }

  Future<void> _openLogsSettings(BuildContext context) async {
    final logger = ValueNotifier(ISpect.logger);
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
        if (widget.options.observer != null &&
            widget.options.observer is ISpectNavigatorObserver)
          _buildNavigationFlowAction(),
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
      icon: isGrouped
          ? Icons.account_tree_rounded
          : Icons.account_tree_outlined,
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

  ISpectActionItem _buildShareLogsAction(BuildContext context) {
    final allLogs = ISpect.logger.history;
    final filteredLogs = _logsViewController.applyCurrentFilters(allLogs);
    final isFiltered = filteredLogs.length != allLogs.length;

    return ISpectActionItem(
      onTap: (_) => ISpectShareAllLogsBottomSheet(
        controller: _logsViewController,
        filteredCount: filteredLogs.length,
        isFiltered: isFiltered,
      ).show(context),
      title: context.ispectL10n.shareLogsFile,
      icon: Icons.ios_share_outlined,
      description: context.ispectL10n.shareLogsFileDesc,
    );
  }

  ISpectActionItem _buildNavigationFlowAction() {
    final observer = widget.options.observer;
    assert(
      observer is ISpectNavigatorObserver,
      'observer must be ISpectNavigatorObserver',
    );
    final navObserver = observer! as ISpectNavigatorObserver;
    return ISpectActionItem(
      title: context.ispectL10n.navigationFlow,
      icon: Icons.route_rounded,
      description: context.ispectL10n.navigationFlowDesc,
      onTap: (context) => ISpectNavigationFlowScreen(
        observer: navObserver,
      ).push(context),
    );
  }

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

/// Main logs view widget that displays the scrollable list of logs.
class _MainLogsView extends StatefulWidget {
  const _MainLogsView({
    required this.logsData,
    required this.iSpectTheme,
    required this.titleFiltersController,
    required this.searchFocusNode,
    required this.logsScrollController,
    required this.logsViewController,
    required this.onSettingsTap,
    this.appBarTitle,
    this.itemsBuilder,
    this.hasDetailPanel = false,
  });

  final List<ISpectLogData> logsData;
  final ISpectScopeModel iSpectTheme;
  final GroupButtonController titleFiltersController;
  final FocusNode searchFocusNode;
  final ScrollController logsScrollController;
  final ISpectViewController logsViewController;
  final VoidCallback onSettingsTap;
  final String? appBarTitle;
  final ISpectLogDataBuilder? itemsBuilder;
  final bool hasDetailPanel;

  @override
  State<_MainLogsView> createState() => _MainLogsViewState();
}

class _MainLogsViewState extends State<_MainLogsView> {
  late final LogsScreenController _controller;
  final _transactionService = NetworkTransactionService();

  @override
  void initState() {
    super.initState();
    _controller = LogsScreenController(
      logsViewController: widget.logsViewController,
      logsScrollController: widget.logsScrollController,
      searchFocusNode: widget.searchFocusNode,
      titleFiltersController: widget.titleFiltersController,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    ISpectOnboardingDialog.showIfNeeded(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogEntries =
        widget.logsViewController.applyCurrentFilters(widget.logsData);
    final sortedEntries = _controller.applySortingIfNeeded(filteredLogEntries);
    final titles = widget.logsViewController.getTitles(widget.logsData);

    final options = ISpect.read(context).options;
    final isDesktop = context.screenSize.isDesktop;
    final isFiltered = filteredLogEntries.length != widget.logsData.length;

    // Live tail: auto-scroll when new REAL logs arrive
    _controller.checkForNewLogs(
      widget.logsData.length,
      isDesktop: isDesktop,
      onMount: () {
        if (mounted) _controller.scrollToNewest();
      },
    );

    // Sort column/direction as ints for the header
    final sortColumnIdx = widget.logsViewController.sortColumn.index;
    final sortDirIdx =
        widget.logsViewController.sortColumn == LogSortColumn.time
            ? (widget.logsViewController.isLogOrderReversed ? 1 : 0)
            : widget.logsViewController.sortDirection.index;

    Widget body = Stack(
      children: [
        CustomScrollView(
          controller: widget.logsScrollController,
          cacheExtent: 1000,
          slivers: [
            ISpectAppBar(
              focusNode: widget.searchFocusNode,
              title: widget.appBarTitle,
              titlesController: widget.titleFiltersController,
              titles: titles.all,
              uniqTitles: titles.unique,
              controller: widget.logsViewController,
              onSettingsTap: widget.onSettingsTap,
              onToggleTitle: (title, selected) => widget.logsViewController
                  .handleTitleFilterToggle(title, isSelected: selected),
              backgroundColor:
                  widget.iSpectTheme.theme.background?.resolve(context),
              filteredCount: filteredLogEntries.length,
              totalCount: widget.logsData.length,
            ),
            if (isDesktop)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: DesktopLogTableHeader(
                    backgroundColor:
                        widget.iSpectTheme.theme.background?.resolve(context) ??
                            context.appTheme.scaffoldBackgroundColor,
                    sortColumn: sortColumnIdx,
                    sortDirection: sortDirIdx,
                    onSortTap: (colIdx) {
                      final col = LogSortColumn.values[colIdx];
                      if (col == LogSortColumn.time) {
                        widget.logsViewController.toggleLogOrder();
                        if (widget.logsViewController.sortColumn !=
                            LogSortColumn.time) {
                          widget.logsViewController.toggleSort(col);
                        }
                      } else {
                        widget.logsViewController.toggleSort(col);
                      }
                    },
                    typeColumnWidth: _controller.typeColumnWidth,
                    timeColumnWidth: _controller.timeColumnWidth,
                    onColumnResize: _controller.handleColumnResize,
                  ),
                ),
              ),
            const SliverGap(4),
            if (sortedEntries.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyLogsWidget(),
              ),
            if (widget.logsViewController.groupHttpLogs)
              _buildGroupedList(sortedEntries, isDesktop, options)
            else
              _buildFlatList(sortedEntries, isDesktop, options),
            // Extra space for status bar on desktop
            SliverGap(isDesktop ? 36 : 8),
          ],
        ),
        // New logs indicator — near the newest-logs edge
        if (isDesktop)
          ValueListenableBuilder(
            valueListenable: _controller.hasNewLogs,
            builder: (context, hasNew, _) {
              final newestAtTop = _controller.isNewestAtTop;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: newestAtTop ? (hasNew ? 100 : -40) : null,
                bottom: newestAtTop ? null : (hasNew ? 36 : -40),
                child: NewLogsIndicator(
                  onTap: _controller.scrollToNewest,
                  pointUp: newestAtTop,
                ),
              );
            },
          ),
        ValueListenableBuilder(
          valueListenable: _controller.scrollDirection,
          builder: (context, direction, _) => AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: direction != null ? (isDesktop ? 44 : 16) : -56,
            child: ScrollToEdgeFab(
              isAtBottom: direction ?? false,
              onPressed: _controller.onFabPressed,
            ),
          ),
        ),
        // Desktop status bar
        if (isDesktop)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DesktopStatusBar(
              filteredCount: filteredLogEntries.length,
              totalCount: widget.logsData.length,
              isFiltered: isFiltered,
              selectedLog: widget.logsViewController.activeData,
              isLiveTailActive: _controller.isLiveTailActive,
              isLiveTailPaused: _controller.isLiveTailPaused,
              onToggleLiveTail: _controller.toggleLiveTailPause,
              useRelativeTime: widget.logsViewController.useRelativeTime,
              onToggleTimestamp:
                  widget.logsViewController.toggleTimestampFormat,
            ),
          ),
      ],
    );

    // Keyboard navigation on desktop
    if (isDesktop) {
      body = Focus(
        focusNode: _controller.keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) => _controller.handleKeyEvent(
          node,
          event,
          widget.logsData,
          context,
        ),
        child: body,
      );
    }

    return body;
  }

  Widget _buildFlatList(
    List<ISpectLogData> sortedEntries,
    bool isDesktop,
    ISpectOptions options,
  ) =>
      SuperSliverList.builder(
        listController: _controller.listController,
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final logEntry =
              _controller.getEntryAtVisualIndex(sortedEntries, index);
          final isSelected = widget.logsViewController.activeData == logEntry;

          return LogListItem(
            key: ObjectKey(logEntry),
            logData: logEntry,
            itemIndex: index,
            statusIcon: widget.iSpectTheme.theme
                .getTypeIcon(context, key: logEntry.key),
            statusColor: widget.iSpectTheme.theme
                    .getTypeColor(context, key: logEntry.key) ??
                Colors.grey,
            isExpanded: isSelected || widget.logsViewController.expandedLogs,
            customItemBuilder: widget.itemsBuilder,
            observer: options.observer is ISpectNavigatorObserver
                ? options.observer as ISpectNavigatorObserver?
                : null,
            onSharePressed: () => ISpectShareLogBottomSheet(
              data: logEntry.toJson(),
              truncatedData: logEntry.toJson(truncated: true),
            ).show(context),
            onItemTapped: isDesktop
                ? () => widget.logsViewController.selectLog(logEntry)
                : () => widget.logsViewController.handleLogItemTap(logEntry),
            onOpenDetail: isDesktop
                ? () => widget.logsViewController.openLogDetail(logEntry)
                : null,
            onTypeFilterTap: isDesktop
                ? (type) => _controller.handleTypeFilter(type, widget.logsData)
                : null,
            useRelativeTime: widget.logsViewController.useRelativeTime,
            typeColumnWidth: _controller.typeColumnWidth,
            timeColumnWidth: _controller.timeColumnWidth,
          );
        },
      );

  Widget _buildGroupedList(
    List<ISpectLogData> sortedEntries,
    bool isDesktop,
    ISpectOptions options,
  ) {
    // Group from chronological order, then apply visual reversal.
    // This prevents time ordering bugs where a transaction positioned
    // at the response's slot shows the request's (older) time.
    final grouped = _transactionService.getGroupedEntries(
      sortedEntries,
      sortedEntries.length,
    );
    final entries = grouped.entries;
    final isReversed =
        widget.logsViewController.sortColumn == LogSortColumn.time &&
            widget.logsViewController.isLogOrderReversed;

    return SuperSliverList.builder(
      listController: _controller.listController,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final visualIndex =
            isReversed ? entries.length - 1 - index : index;
        final entry = entries[visualIndex];

        if (entry is NetworkTransaction) {
          return NetworkTransactionCard(
            key: ValueKey(entry.requestId),
            transaction: entry,
            typeColumnWidth: _controller.typeColumnWidth,
            timeColumnWidth: _controller.timeColumnWidth,
            onTap: () {
              if (isDesktop) {
                widget.logsViewController.selectLog(entry.request);
              } else {
                widget.logsViewController.handleLogItemTap(entry.request);
              }
            },
            onOpenRequestDetail: isDesktop
                ? () => widget.logsViewController
                    .selectAndFollowDetail(entry.request)
                : () {
                    final responseLog = entry.response ?? entry.error;
                    final l10n = ISpectLocalization.of(context);
                    JsonScreen(
                      data: entry.request.toJson(),
                      truncatedData: entry.request.toJson(truncated: true),
                      correlatedLogData: responseLog?.toJson(),
                      correlatedLogLabel:
                          responseLog != null ? l10n.httpResponse : null,
                      correlationDuration: entry.duration,
                    ).push(context);
                  },
            onOpenResponseDetail: (entry.response ?? entry.error) != null
                ? isDesktop
                    ? () => widget.logsViewController.selectAndFollowDetail(
                          entry.response ?? entry.error!,
                        )
                    : () {
                        final log = entry.response ?? entry.error!;
                        final l10n = ISpectLocalization.of(context);
                        JsonScreen(
                          data: log.toJson(),
                          truncatedData: log.toJson(truncated: true),
                          correlatedLogData: entry.request.toJson(),
                          correlatedLogLabel: l10n.httpRequest,
                          correlationDuration: entry.duration,
                        ).push(context);
                      }
                : null,
          );
        }

        final logEntry = entry as ISpectLogData;
        final isSelected = widget.logsViewController.activeData == logEntry;

        return LogListItem(
          key: ObjectKey(logEntry),
          logData: logEntry,
          itemIndex: index,
          statusIcon:
              widget.iSpectTheme.theme.getTypeIcon(context, key: logEntry.key),
          statusColor: widget.iSpectTheme.theme
                  .getTypeColor(context, key: logEntry.key) ??
              Colors.grey,
          isExpanded: isSelected || widget.logsViewController.expandedLogs,
          customItemBuilder: widget.itemsBuilder,
          observer: options.observer is ISpectNavigatorObserver
              ? options.observer as ISpectNavigatorObserver?
              : null,
          onSharePressed: () => ISpectShareLogBottomSheet(
            data: logEntry.toJson(),
            truncatedData: logEntry.toJson(truncated: true),
          ).show(context),
          onItemTapped: isDesktop
              ? () => widget.logsViewController.selectLog(logEntry)
              : () => widget.logsViewController.handleLogItemTap(logEntry),
          onOpenDetail: isDesktop
              ? () => widget.logsViewController.openLogDetail(logEntry)
              : null,
          onTypeFilterTap: isDesktop
              ? (type) => _controller.handleTypeFilter(type, widget.logsData)
              : null,
          useRelativeTime: widget.logsViewController.useRelativeTime,
          typeColumnWidth: _controller.typeColumnWidth,
          timeColumnWidth: _controller.timeColumnWidth,
        );
      },
    );
  }
}

/// Delegate that pins the [DesktopLogTableHeader] below the [SliverAppBar].
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.child});

  final Widget child;

  static const _height = 36.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      SizedBox(height: _height, child: child);

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      child != oldDelegate.child;
}
