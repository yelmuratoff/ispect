import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/string.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/builder/widget_builder.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/gap/sliver_gap.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';
import 'package:ispect/src/features/ispect/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/desktop_log_row.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
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
    _logsViewController.toggleExpandedLogs();
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

            final detailView = _DetailView(
              activeData: activeForDetail,
              onClose: () {
                if (isDesktop) {
                  _logsViewController.closeDetail();
                } else {
                  _logsViewController.activeData = null;
                }
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
        onTap: (_) => ISpectShareAllLogsBottomSheet(
          controller: _logsViewController,
        ).show(context),
        title: context.ispectL10n.shareLogsFile,
        icon: Icons.ios_share_outlined,
        description: context.ispectL10n.shareLogsFileDesc,
      );

  ISpectActionItem _buildNavigationFlowAction() {
    final observer = widget.options.observer;
    assert(
      observer is ISpectNavigatorObserver,
      'observer must be ISpectNavigatorObserver',
    );
    return ISpectActionItem(
      title: context.ispectL10n.navigationFlow,
      icon: Icons.route_rounded,
      description: context.ispectL10n.navigationFlowDesc,
      onTap: (context) => ISpectNavigationFlowScreen(
        observer: observer! as ISpectNavigatorObserver,
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

    final choice = await showDialog<_LogSourceChoice>(
      context: context,
      builder: (_) => const _LogSourceDialog(),
    );

    if (!mounted || choice == null) return;

    switch (choice) {
      case _LogSourceChoice.external:
        await _loadContentFromCallback();
      case _LogSourceChoice.paste:
        _showPasteDialog();
    }
  }

  void _showPasteDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => _PasteContentDialog(
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

/// A widget that represents a single log entry in the list.
class _LogListItem extends StatelessWidget {
  const _LogListItem({
    required this.logData,
    required this.itemIndex,
    required this.statusIcon,
    required this.statusColor,
    required this.isExpanded,
    required this.onItemTapped,
    required this.onSharePressed,
    this.customItemBuilder,
    this.observer,
    this.onOpenDetail,
    this.onTypeFilterTap,
    this.useRelativeTime = false,
    this.typeColumnWidth = 70,
    this.timeColumnWidth = 140,
    super.key,
  });

  final ISpectLogData logData;
  final int itemIndex;
  final IconData statusIcon;
  final Color statusColor;
  final bool isExpanded;
  final VoidCallback onItemTapped;
  final VoidCallback onSharePressed;
  final ISpectLogDataBuilder? customItemBuilder;
  final ISpectNavigatorObserver? observer;
  final VoidCallback? onOpenDetail;
  final void Function(String type)? onTypeFilterTap;
  final bool useRelativeTime;
  final double typeColumnWidth;
  final double timeColumnWidth;

  @override
  Widget build(BuildContext context) {
    if (customItemBuilder != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: customItemBuilder!(context, logData),
      );
    }

    if (context.screenSize.isDesktop) {
      return DesktopLogRow(
        icon: statusIcon,
        color: statusColor,
        data: logData,
        index: itemIndex,
        isSelected: isExpanded,
        onShareTap: onSharePressed,
        onTap: onItemTapped,
        onOpenDetail: onOpenDetail,
        onTypeFilterTap: onTypeFilterTap,
        observer: observer,
        useRelativeTime: useRelativeTime,
        typeColumnWidth: typeColumnWidth,
        timeColumnWidth: timeColumnWidth,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: LogCard(
        icon: statusIcon,
        color: statusColor,
        data: logData,
        index: itemIndex,
        isExpanded: isExpanded,
        onShareTap: onSharePressed,
        onTap: onItemTapped,
        observer: observer,
      ),
    );
  }
}

/// A widget displayed when there are no logs to show.
class _EmptyLogsWidget extends StatelessWidget {
  const _EmptyLogsWidget();

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.15);
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: muted),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.terminal_rounded,
                      size: 36,
                      color: onSurface.withValues(alpha: 0.18),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 24,
                          color: onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),
            Text(
              context.ispectL10n.notFound.capitalize(),
              style: context.appTheme.textTheme.titleMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(6),
            Text(
              context.ispectL10n.noResultsHint,
              style: context.appTheme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Main logs view widget that displays the scrollable list of logs
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
  /// null = hidden, true = at bottom (show up arrow), false = scrolled down (show down arrow)
  final _scrollDirection = ValueNotifier<bool?>(null);
  final _keyboardFocusNode = FocusNode(debugLabel: 'DesktopLogKeyboard');
  final _listController = ListController();

  // --- Column resizing ---
  double _typeColumnWidth = 70;
  double _timeColumnWidth = 140;

  // --- Live tail / auto-scroll ---
  bool _isLiveTailActive = false;
  int _lastLogCount = 0;
  final _hasNewLogs = ValueNotifier<bool>(false);

  // --- Relative time refresh timer ---
  Timer? _relativeTimeTimer;

  @override
  void initState() {
    super.initState();
    widget.logsScrollController.addListener(_onScroll);
    widget.searchFocusNode.addListener(_onSearchFocusChanged);
    widget.logsViewController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.logsScrollController.removeListener(_onScroll);
    widget.searchFocusNode.removeListener(_onSearchFocusChanged);
    widget.logsViewController.removeListener(_onControllerChanged);
    _scrollDirection.dispose();
    _keyboardFocusNode.dispose();
    _listController.dispose();
    _hasNewLogs.dispose();
    _relativeTimeTimer?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    // Manage relative time refresh timer
    if (widget.logsViewController.useRelativeTime) {
      _relativeTimeTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          if (mounted) setState(() {});
        },
      );
    } else {
      _relativeTimeTimer?.cancel();
      _relativeTimeTimer = null;
    }
  }

  void _onSearchFocusChanged() {
    // When search loses focus, return focus to the keyboard handler
    if (!widget.searchFocusNode.hasFocus &&
        _keyboardFocusNode.canRequestFocus) {
      _keyboardFocusNode.requestFocus();
    }
  }

  /// Whether newest logs appear at scroll offset 0 (top).
  bool get _isNewestAtTop {
    final vc = widget.logsViewController;
    return vc.sortColumn == LogSortColumn.time && vc.isLogOrderReversed;
  }

  void _onScroll() {
    final sc = widget.logsScrollController;
    if (!sc.hasClients) return;
    final offset = sc.offset;
    final maxExtent = sc.position.maxScrollExtent;

    // FAB visibility/direction: same logic regardless of sort order.
    // null = hidden, true = at bottom (show up arrow), false = away from bottom (show down arrow)
    if (offset < 300) {
      _scrollDirection.value = null;
    } else if (offset >= maxExtent - 50) {
      _scrollDirection.value = true;
    } else {
      _scrollDirection.value = false;
    }

    // Live tail: track whether user is at the newest-logs edge.
    if (_isNewestAtTop) {
      if (offset <= 50) {
        _isLiveTailActive = true;
        _hasNewLogs.value = false;
      } else {
        _isLiveTailActive = false;
      }
    } else {
      if (offset >= maxExtent - 50) {
        _isLiveTailActive = true;
        _hasNewLogs.value = false;
      } else {
        _isLiveTailActive = false;
      }
    }
  }

  void _onFabPressed() {
    final sc = widget.logsScrollController;
    final target =
        (_scrollDirection.value ?? false) ? 0.0 : sc.position.maxScrollExtent;
    sc.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToNewest() {
    final sc = widget.logsScrollController;
    if (!sc.hasClients) return;
    final target = _isNewestAtTop ? 0.0 : sc.position.maxScrollExtent;
    sc.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    _hasNewLogs.value = false;
  }

  void _handleColumnResize(int column, double delta) {
    setState(() {
      if (column == 0) {
        _typeColumnWidth = (_typeColumnWidth + delta).clamp(40, 200);
      } else if (column == 1) {
        _timeColumnWidth = (_timeColumnWidth + delta).clamp(80, 250);
      }
    });
  }

  void _handleTypeFilter(String typeAction) {
    final titles = widget.logsViewController.getTitles(widget.logsData);
    final uniq = titles.unique;

    if (typeAction.startsWith('__show_only__')) {
      final type = typeAction.replaceFirst('__show_only__', '');
      widget.logsViewController.setOnlyTitle(type);
      _syncChipsToFilter(type, uniq, showOnly: true);
      return;
    }
    if (typeAction.startsWith('__hide__')) {
      final type = typeAction.replaceFirst('__hide__', '');
      widget.logsViewController.excludeTitle(type, uniq);
      _syncChipsToFilter(type, uniq, showOnly: false);
      return;
    }
    // Simple click on type: toggle — if already filtering by this type, clear
    final currentTitles = widget.logsViewController.filter.titles;
    if (currentTitles.length == 1 && currentTitles.first == typeAction) {
      widget.logsViewController.filter =
          widget.logsViewController.filter.copyWith(titles: <String>[]);
      widget.titleFiltersController.unselectAll();
    } else {
      widget.logsViewController.setOnlyTitle(typeAction);
      _syncChipsToFilter(typeAction, uniq, showOnly: true);
    }
  }

  /// Sync the GroupButtonController chip selection to match the applied filter.
  void _syncChipsToFilter(
    String type,
    List<String> uniqTitles, {
    required bool showOnly,
  }) {
    final controller = widget.titleFiltersController..unselectAll();
    if (showOnly) {
      // Select only the chip matching the type
      final idx = uniqTitles.indexOf(type);
      if (idx != -1) controller.selectIndex(idx);
    } else {
      // Select all chips except the hidden type
      for (var i = 0; i < uniqTitles.length; i++) {
        if (uniqTitles[i] != type) controller.selectIndex(i);
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    // Ctrl/Cmd+K or "/" to focus search (only when search is not focused)
    if ((isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyK) ||
        (!widget.searchFocusNode.hasFocus &&
            event.logicalKey == LogicalKeyboardKey.slash)) {
      widget.searchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl+C: copy selected log message
    if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
      final activeData = widget.logsViewController.activeData;
      if (activeData != null) {
        final text = activeData.isHttpLog
            ? (activeData.httpLogText ?? '')
            : activeData.textMessage;
        if (text.isNotEmpty) {
          copyClipboard(context, value: text);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    // Don't handle arrow/escape when search is focused
    if (widget.searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    final filteredLogEntries =
        widget.logsViewController.applyCurrentFilters(widget.logsData);
    final sortedEntries = _applySortingIfNeeded(filteredLogEntries);
    if (sortedEntries.isEmpty) return KeyEventResult.ignored;

    final activeData = widget.logsViewController.activeData;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.logsViewController.detailData != null) {
        widget.logsViewController.closeDetail();
        return KeyEventResult.handled;
      }
      if (activeData != null) {
        widget.logsViewController.activeData = null;
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Enter: open detail panel for selected log
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (activeData != null) {
        widget.logsViewController.openLogDetail(activeData);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final isDown = event.logicalKey == LogicalKeyboardKey.arrowDown;
      int targetVisualIndex;

      if (activeData == null) {
        targetVisualIndex = isDown ? 0 : sortedEntries.length - 1;
      } else {
        final visualEntries = _getVisualEntries(sortedEntries);
        final currentVisualIndex = visualEntries.indexOf(activeData);
        if (currentVisualIndex == -1) return KeyEventResult.ignored;

        targetVisualIndex =
            isDown ? currentVisualIndex + 1 : currentVisualIndex - 1;
        if (targetVisualIndex < 0 ||
            targetVisualIndex >= visualEntries.length) {
          return KeyEventResult.handled;
        }
      }

      final visualEntries = _getVisualEntries(sortedEntries);
      final nextEntry = visualEntries[targetVisualIndex];

      // Auto-follow: if detail panel is open, update both in one notification
      if (widget.logsViewController.detailData != null) {
        widget.logsViewController.selectAndFollowDetail(nextEntry);
      } else {
        widget.logsViewController.activeData = nextEntry;
      }

      // Scroll to keep the selected row visible
      _listController.animateToItem(
        index: targetVisualIndex,
        scrollController: widget.logsScrollController,
        alignment: 0.5,
        duration: (_) => const Duration(milliseconds: 200),
        curve: (_) => Curves.easeOutCubic,
      );

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Get entries in visual display order (after sorting + reversing).
  List<ISpectLogData> _getVisualEntries(List<ISpectLogData> sortedEntries) {
    if (widget.logsViewController.sortColumn == LogSortColumn.time &&
        widget.logsViewController.isLogOrderReversed) {
      return sortedEntries.reversed.toList();
    }
    return sortedEntries;
  }

  /// Apply column sorting if not sorting by time (time uses existing reverse logic).
  List<ISpectLogData> _applySortingIfNeeded(List<ISpectLogData> entries) {
    if (widget.logsViewController.sortColumn != LogSortColumn.time) {
      return widget.logsViewController.applySorting(entries);
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogEntries =
        widget.logsViewController.applyCurrentFilters(widget.logsData);
    final sortedEntries = _applySortingIfNeeded(filteredLogEntries);
    final titles = widget.logsViewController.getTitles(widget.logsData);

    final options = ISpect.read(context).options;
    final isDesktop = context.screenSize.isDesktop;
    final isFiltered = filteredLogEntries.length != widget.logsData.length;

    // Live tail: auto-scroll when new REAL logs arrive (track raw data, not filtered)
    final rawCount = widget.logsData.length;
    if (isDesktop && rawCount != _lastLogCount) {
      if (rawCount > _lastLogCount && _lastLogCount > 0) {
        if (_isLiveTailActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToNewest();
          });
        } else {
          _hasNewLogs.value = true;
        }
      }
      _lastLogCount = rawCount;
    }

    // Sort column/direction as ints for the header
    final sortColumnIdx = widget.logsViewController.sortColumn.index;
    // For time column, direction is based on isLogOrderReversed
    final sortDirIdx =
        widget.logsViewController.sortColumn == LogSortColumn.time
            ? (widget.logsViewController.isLogOrderReversed
                ? 1
                : 0) // descending when reversed
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
                        // Time column uses existing reverse logic
                        widget.logsViewController.toggleLogOrder();
                        // Ensure sort column is set to time
                        if (widget.logsViewController.sortColumn !=
                            LogSortColumn.time) {
                          widget.logsViewController.toggleSort(col);
                        }
                      } else {
                        widget.logsViewController.toggleSort(col);
                      }
                    },
                    typeColumnWidth: _typeColumnWidth,
                    timeColumnWidth: _timeColumnWidth,
                    onColumnResize: _handleColumnResize,
                  ),
                ),
              ),
            if (sortedEntries.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptyLogsWidget(),
              ),
            SuperSliverList.builder(
              listController: _listController,
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final logEntry = _getEntryAtVisualIndex(sortedEntries, index);
                final isSelected =
                    widget.logsViewController.activeData == logEntry;

                return _LogListItem(
                  key: ObjectKey(logEntry),
                  logData: logEntry,
                  itemIndex: index,
                  statusIcon: widget.iSpectTheme.theme
                      .getTypeIcon(context, key: logEntry.key),
                  statusColor: widget.iSpectTheme.theme
                          .getTypeColor(context, key: logEntry.key) ??
                      Colors.grey,
                  isExpanded:
                      isSelected || widget.logsViewController.expandedLogs,
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
                      : () =>
                          widget.logsViewController.handleLogItemTap(logEntry),
                  onOpenDetail: isDesktop
                      ? () => widget.logsViewController.openLogDetail(logEntry)
                      : null,
                  onTypeFilterTap: isDesktop ? _handleTypeFilter : null,
                  useRelativeTime: widget.logsViewController.useRelativeTime,
                  typeColumnWidth: _typeColumnWidth,
                  timeColumnWidth: _timeColumnWidth,
                );
              },
            ),
            // Extra space for status bar on desktop
            SliverGap(isDesktop ? 36 : 8),
          ],
        ),
        // New logs indicator — near the newest-logs edge
        if (isDesktop)
          ValueListenableBuilder(
            valueListenable: _hasNewLogs,
            builder: (context, hasNew, _) {
              final newestAtTop = _isNewestAtTop;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: newestAtTop ? (hasNew ? 100 : -40) : null,
                bottom: newestAtTop ? null : (hasNew ? 36 : -40),
                child: _NewLogsIndicator(
                  onTap: _scrollToNewest,
                  pointUp: newestAtTop,
                ),
              );
            },
          ),
        ValueListenableBuilder(
          valueListenable: _scrollDirection,
          builder: (context, direction, _) => AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: direction != null ? (isDesktop ? 44 : 16) : -56,
            child: _ScrollToEdgeFab(
              isAtBottom: direction ?? false,
              onPressed: _onFabPressed,
            ),
          ),
        ),
        // Desktop status bar
        if (isDesktop)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _DesktopStatusBar(
              filteredCount: filteredLogEntries.length,
              totalCount: widget.logsData.length,
              isFiltered: isFiltered,
              selectedLog: widget.logsViewController.activeData,
              isLiveTailActive: _isLiveTailActive,
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
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: body,
      );
    }

    return body;
  }

  ISpectLogData _getEntryAtVisualIndex(
    List<ISpectLogData> sortedEntries,
    int index,
  ) {
    if (widget.logsViewController.sortColumn == LogSortColumn.time) {
      // Use existing reverse logic for time column
      final (entry: logEntry, actualIndex: _) =
          widget.logsViewController.getLogEntryAtIndex(sortedEntries, index);
      return logEntry;
    }
    // For other sort columns, entries are already in correct order
    return sortedEntries[index];
  }
}

/// Indicator shown when new logs arrive while user is scrolled away.
class _NewLogsIndicator extends StatelessWidget {
  const _NewLogsIndicator({
    required this.onTap,
    this.pointUp = false,
  });

  final VoidCallback onTap;
  final bool pointUp;

  @override
  Widget build(BuildContext context) {
    final primary = context.appTheme.colorScheme.primary;

    return Center(
      child: Material(
        color: primary,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pointUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: context.appTheme.colorScheme.onPrimary,
                ),
                const Gap(6),
                Text(
                  'New logs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollToEdgeFab extends StatelessWidget {
  const _ScrollToEdgeFab({
    required this.onPressed,
    required this.isAtBottom,
  });

  final VoidCallback onPressed;
  final bool isAtBottom;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.08);

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              isAtBottom
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 22,
              color:
                  context.appTheme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status bar at the bottom of the desktop log view.
class _DesktopStatusBar extends StatelessWidget {
  const _DesktopStatusBar({
    required this.filteredCount,
    required this.totalCount,
    required this.isFiltered,
    required this.useRelativeTime,
    required this.onToggleTimestamp,
    this.selectedLog,
    this.isLiveTailActive = false,
  });

  final int filteredCount;
  final int totalCount;
  final bool isFiltered;
  final ISpectLogData? selectedLog;
  final bool isLiveTailActive;
  final bool useRelativeTime;
  final VoidCallback onToggleTimestamp;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.1);
    final labelColor = onSurface.withValues(alpha: 0.55);

    final countText =
        isFiltered ? '$filteredCount / $totalCount' : '$totalCount';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Live tail indicator
            if (isLiveTailActive) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const Gap(6),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
              const Gap(10),
            ],
            Icon(
              Icons.list_alt_rounded,
              size: 14,
              color: labelColor,
            ),
            const Gap(6),
            Text(
              '$countText logs',
              style: TextStyle(fontSize: 12, color: labelColor),
            ),
            if (selectedLog != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${selectedLog!.key ?? ''} \u2014 '
                  '${selectedLog!.formattedTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ] else
              const Spacer(),
            // Timestamp format toggle
            Tooltip(
              message: useRelativeTime ? 'Absolute time' : 'Relative time',
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                onTap: onToggleTimestamp,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    useRelativeTime
                        ? Icons.access_time_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: useRelativeTime
                        ? context.appTheme.colorScheme.primary
                        : labelColor,
                  ),
                ),
              ),
            ),
            const Gap(10),
            const _KeyBadge(label: '\u2191\u2193'),
            const Gap(4),
            Text(
              'navigate',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            const _KeyBadge(label: '\u23CE'),
            const Gap(4),
            Text(
              'open',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            _KeyBadge(
              label: Theme.of(context).platform == TargetPlatform.macOS
                  ? '\u2318C'
                  : 'Ctrl+C',
            ),
            const Gap(4),
            Text(
              context.ispectL10n.copy.toLowerCase(),
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            const _KeyBadge(label: '/'),
            const Gap(4),
            Text(
              'search',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            const _KeyBadge(label: 'Esc'),
            const Gap(4),
            Text(
              'close',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: onSurface.withValues(alpha: 0.5),
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

/// Detail view widget for displaying selected log data
class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.activeData,
    required this.onClose,
  });

  final ISpectLogData activeData;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final json = activeData.toJson();
    return RepaintBoundary(
      child: JsonScreen(
        key: ValueKey(activeData.hashCode),
        data: json,
        truncatedData: activeData.toJson(truncated: true),
        onClose: onClose,
      ),
    );
  }
}

enum _LogSourceChoice { external, paste }

class _LogSourceDialog extends StatelessWidget {
  const _LogSourceDialog();

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final backgroundColor = iSpect.theme.background?.resolve(context);

    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(context.ispectL10n.loadFileContent),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.file_open),
            title: Text(context.ispectL10n.loadFileContent),
            subtitle: Text(context.ispectL10n.selectTxtOrJsonFromDevice),
            onTap: () => Navigator.of(context).pop(_LogSourceChoice.external),
          ),
          const Gap(16),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: Text(context.ispectL10n.pasteContent),
            subtitle: Text(context.ispectL10n.pasteTxtOrJsonHere),
            onTap: () => Navigator.of(context).pop(_LogSourceChoice.paste),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.ispectL10n.cancel),
        ),
      ],
    );
  }
}

/// Dialog widget for pasting file content
class _PasteContentDialog extends StatefulWidget {
  const _PasteContentDialog({
    required this.onContentProcessed,
  });

  final Future<void> Function(String content) onContentProcessed;

  @override
  State<_PasteContentDialog> createState() => _PasteContentDialogState();
}

class _PasteContentDialogState extends State<_PasteContentDialog> {
  final _controller = TextEditingController();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // ignore: cascade_invocations
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasContent = _controller.text.trim().isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final backgroundColor = iSpect.theme.background?.resolve(context);

    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(context.ispectL10n.pasteContent),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.ispectL10n.pasteYourFileContentBelow),
            const Gap(8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText:
                      context.ispectL10n.pasteYourTxtOrJsonFileContentHere,
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.ispectL10n.cancel),
        ),
        ElevatedButton(
          onPressed: _hasContent
              ? () async {
                  Navigator.of(context).pop();
                  await widget.onContentProcessed(_controller.text);
                }
              : null,
          child: Text(context.ispectL10n.process),
        ),
      ],
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
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => true;
}
