import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/controllers/logs_screen_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/log_correlation_index.dart';
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

            final logsView = _MainLogsView(
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
  final bool hasDetailPanel;

  @override
  State<_MainLogsView> createState() => _MainLogsViewState();
}

class _MainLogsViewState extends State<_MainLogsView> {
  late final LogsScreenController _controller;
  final _transactionService = NetworkTransactionService();

  Map<int, int> _idToDataIndex = const {};
  List<ISpectLogData>? _lastIdToDataIndexInput;
  int _cachedSortedLength = 0;
  bool _cachedIsReversed = false;

  List<ISpectLogData>? _lastRawMatches;
  List<ISpectLogData> _reversedMatchesCache = const [];

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToFocusedMatch() {
    final focusedId = widget.logsViewController.focusedMatchId;
    if (focusedId < 0) return;

    final dataIndex = _idToDataIndex[focusedId];
    if (dataIndex == null) return;

    final visualIndex =
        _cachedIsReversed ? _cachedSortedLength - 1 - dataIndex : dataIndex;

    try {
      _controller.listController.animateToItem(
        index: visualIndex,
        scrollController: widget.logsScrollController,
        alignment: 0.3,
        duration: (_) => const Duration(milliseconds: 250),
        curve: (_) => Curves.easeOutCubic,
      );
    } on Object catch (error, stackTrace) {
      ISpect.logger.handle(exception: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHighlightMode =
        widget.logsViewController.searchMode == SearchMode.highlight;

    final filteredLogEntries = isHighlightMode
        ? widget.logsViewController.applyFiltersWithoutSearch(widget.logsData)
        : widget.logsViewController.applyCurrentFilters(widget.logsData);

    final sortedEntries = _controller.applySortingIfNeeded(filteredLogEntries);

    _cachedIsReversed =
        widget.logsViewController.sortColumn == LogSortColumn.time &&
            widget.logsViewController.isLogOrderReversed;
    _cachedSortedLength = sortedEntries.length;

    if (isHighlightMode) {
      var matches = widget.logsViewController.findSearchMatches(sortedEntries);
      if (_cachedIsReversed && matches.isNotEmpty) {
        if (!identical(matches, _lastRawMatches)) {
          _reversedMatchesCache = matches.reversed.toList();
          _lastRawMatches = matches;
        }
        matches = _reversedMatchesCache;
      }
      widget.logsViewController.updateSearchMatches(matches);

      if (!identical(sortedEntries, _lastIdToDataIndexInput)) {
        final map = <int, int>{};
        for (var i = 0; i < sortedEntries.length; i++) {
          map[sortedEntries[i].id] = i;
        }
        _idToDataIndex = map;
        _lastIdToDataIndexInput = sortedEntries;
      }
    } else {
      _idToDataIndex = const {};
      _lastIdToDataIndexInput = null;
    }
    final logTypeKeys =
        widget.logsViewController.getLogTypeKeys(widget.logsData);

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
              titles: logTypeKeys.all,
              uniqTitles: logTypeKeys.unique,
              controller: widget.logsViewController,
              onSettingsTap: widget.onSettingsTap,
              onToggleTitle: (key, selected) => widget.logsViewController
                  .handleLogTypeKeyFilterToggle(key, isSelected: selected),
              backgroundColor:
                  widget.iSpectTheme.theme.background?.resolve(context),
              filteredCount: isHighlightMode
                  ? widget.logsViewController.searchMatchCount
                  : filteredLogEntries.length,
              totalCount: isHighlightMode
                  ? filteredLogEntries.length
                  : widget.logsData.length,
              onScrollToFocusedMatch: _scrollToFocusedMatch,
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
            if (widget.logsViewController.groupHttpLogs &&
                widget.logsViewController.filter.logTypeKeys.isEmpty)
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
            key: ValueKey(logEntry.id),
            logData: logEntry,
            itemIndex: index,
            statusIcon: widget.iSpectTheme.theme
                .getTypeIcon(context, key: logEntry.key),
            statusColor: widget.iSpectTheme.theme
                    .getTypeColor(context, key: logEntry.key) ??
                Colors.grey,
            isExpanded: isSelected || widget.logsViewController.expandedLogs,
            searchMatchState: widget.logsViewController.matchStateFor(logEntry),
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
            onShowRelated: isDesktop
                ? null
                : (id) => widget.logsViewController.searchByCorrelationId(id),
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
      widget.logsViewController.outputGeneration,
    );
    final entries = grouped.entries;
    final isReversed =
        widget.logsViewController.sortColumn == LogSortColumn.time &&
            widget.logsViewController.isLogOrderReversed;

    return SuperSliverList.builder(
      listController: _controller.listController,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final visualIndex = isReversed ? entries.length - 1 - index : index;
        final entry = entries[visualIndex];

        if (entry is NetworkTransaction) {
          return NetworkTransactionCard(
            key: ValueKey(entry.requestId),
            transaction: entry,
            searchMatchState:
                widget.logsViewController.matchStateForTransaction(entry),
            typeColumnWidth: _controller.typeColumnWidth,
            timeColumnWidth: _controller.timeColumnWidth,
            onTap: isDesktop
                ? () => widget.logsViewController.selectLog(entry.request)
                : null,
            onOpenRequestDetail: isDesktop
                ? () => widget.logsViewController
                    .selectAndFollowDetail(entry.request)
                : () {
                    final navigator = Navigator.of(context);
                    final responseLog = entry.response ?? entry.error;
                    LogDetailView(
                      activeData: entry.request,
                      onClose: navigator.pop,
                      correlatedLog: responseLog,
                      correlationDuration: entry.duration,
                      onShowRelated: (id) {
                        widget.logsViewController.searchByCorrelationId(id);
                        navigator.pop();
                      },
                    ).push(context);
                  },
            onOpenResponseDetail: (entry.response ?? entry.error) != null
                ? isDesktop
                    ? () => widget.logsViewController.selectAndFollowDetail(
                          entry.response ?? entry.error!,
                        )
                    : () {
                        final navigator = Navigator.of(context);
                        final log = entry.response ?? entry.error!;
                        LogDetailView(
                          activeData: log,
                          onClose: navigator.pop,
                          correlatedLog: entry.request,
                          correlationDuration: entry.duration,
                          onShowRelated: (id) {
                            widget.logsViewController.searchByCorrelationId(id);
                            navigator.pop();
                          },
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
          searchMatchState: widget.logsViewController.matchStateFor(logEntry),
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
          onShowRelated: isDesktop
              ? null
              : (id) => widget.logsViewController.searchByCorrelationId(id),
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
