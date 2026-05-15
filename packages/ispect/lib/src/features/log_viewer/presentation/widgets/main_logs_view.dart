import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/network_transaction_service.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/sliver_gap.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_screen_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/desktop_status_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/empty_logs_widget.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/desktop_log_table_header.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_list_item.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_scroll_indicators.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_log_bottom_sheet.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Main logs view widget that displays the scrollable list of logs.
class MainLogsView extends StatefulWidget {
  const MainLogsView({
    required this.logsData,
    required this.iSpectTheme,
    required this.titleFiltersController,
    required this.searchFocusNode,
    required this.logsScrollController,
    required this.logsViewController,
    required this.onSettingsTap,
    super.key,
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
  State<MainLogsView> createState() => _MainLogsViewState();
}

class _MainLogsViewState extends State<MainLogsView> {
  late final LogsScreenController _controller;
  final _transactionService = NetworkTransactionService();

  Map<String, int> _idToDataIndex = const {};
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
    if (focusedId == null) return;

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
        final map = <String, int>{};
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

  Widget _buildLogListItem({
    required BuildContext context,
    required ISpectLogData logEntry,
    required int index,
    required bool isDesktop,
    required ISpectOptions options,
    required Key key,
  }) {
    final isSelected = widget.logsViewController.activeData == logEntry;
    final observer = options.observer is ISpectNavigatorObserver
        ? options.observer as ISpectNavigatorObserver?
        : null;

    return LogListItem(
      key: key,
      logData: logEntry,
      itemIndex: index,
      statusIcon:
          widget.iSpectTheme.theme.getTypeIcon(context, key: logEntry.key),
      statusColor:
          widget.iSpectTheme.theme.getTypeColor(context, key: logEntry.key) ??
              Colors.grey,
      isExpanded: isSelected || widget.logsViewController.expandedLogs,
      searchMatchState: widget.logsViewController.matchStateFor(logEntry),
      observer: observer,
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
          return _buildLogListItem(
            context: context,
            logEntry: logEntry,
            index: index,
            isDesktop: isDesktop,
            options: options,
            key: ValueKey(logEntry.id),
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
          return _buildTransactionCard(entry, isDesktop: isDesktop);
        }

        final logEntry = entry as ISpectLogData;
        return _buildLogListItem(
          context: context,
          logEntry: logEntry,
          index: index,
          isDesktop: isDesktop,
          options: options,
          key: ObjectKey(logEntry),
        );
      },
    );
  }

  Widget _buildTransactionCard(
    NetworkTransaction entry, {
    required bool isDesktop,
  }) {
    final responseOrError = entry.response ?? entry.error;
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
          ? () => widget.logsViewController.selectAndFollowDetail(entry.request)
          : () => LogDetailView(
                activeData: entry.request,
                correlatedLog: responseOrError,
                correlationDuration: entry.duration,
                onShowRelated: widget.logsViewController.searchByCorrelationId,
              ).push(context),
      onOpenResponseDetail: responseOrError == null
          ? null
          : isDesktop
              ? () => widget.logsViewController
                  .selectAndFollowDetail(responseOrError)
              : () => LogDetailView(
                    activeData: responseOrError,
                    correlatedLog: entry.request,
                    correlationDuration: entry.duration,
                    onShowRelated:
                        widget.logsViewController.searchByCorrelationId,
                  ).push(context),
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
