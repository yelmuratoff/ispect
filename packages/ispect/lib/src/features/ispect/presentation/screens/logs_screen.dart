import 'package:flutter/material.dart';
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
import 'package:ispect/src/features/ispect/presentation/screens/log_screen.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/info_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_bottom_sheet.dart';

/// This screen provides an efficient interface for browsing, searching, and filtering
/// application logs with the following key features:
class LogsScreen extends StatefulWidget {
  /// Creates a high-performance logs viewer screen.
  const LogsScreen({
    required this.options,
    super.key,
    this.appBarTitle,
    this.itemsBuilder,
  });

  /// Custom title for the screen's app bar.
  ///
  /// If not provided, a default title will be used based on the current locale.
  final String? appBarTitle;

  /// Optional builder function to customize the appearance of log items.
  ///
  /// When provided, this builder will be called for each log entry, allowing
  /// complete customization of the log card appearance and behavior.
  ///
  /// Example:
  /// ```dart
  /// itemsBuilder: (context, data) => CustomLogCard(
  ///   data: data,
  ///   onTap: () => handleLogTap(data),
  /// )
  /// ```
  final ISpectifyDataBuilder? itemsBuilder;

  /// Configuration options for the ISpect logging system.
  ///
  /// Contains settings for theming, behavior, and additional action items.
  final ISpectOptions options;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

/// Private state class for the logs screen with performance optimizations.
///
/// Manages the screen's state including:
/// - Controller instances for navigation and filtering
/// - Caching mechanisms for improved performance
/// - Search and filter state management
/// - UI interaction handlers
class _LogsScreenState extends State<LogsScreen> {
  /// Controller for managing title filter buttons group state
  final _titleFiltersController = GroupButtonController();

  /// Focus node for the search input field
  final _searchFocusNode = FocusNode();

  /// Scroll controller for the main logs list
  final _logsScrollController = ScrollController();

  /// Main controller for logs view operations (search, filter, expansion)
  late final _logsViewController = ISpectifyViewController();

  // Performance optimization: Smart caching for filtered data
  /// Cached filtered data to avoid redundant computations
  List<ISpectifyData> _cachedFilteredData = <ISpectifyData>[];

  /// Last processed data length for cache invalidation
  int _lastProcessedDataLength = 0;

  /// Last applied filter for cache invalidation
  ISpectifyFilter? _lastAppliedFilter;

  @override
  void initState() {
    super.initState();
    _logsViewController.toggleExpandedLogs();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _titleFiltersController.dispose();
    _logsViewController.dispose();
    _logsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);

    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      body: ListenableBuilder(
        listenable: _logsViewController,
        builder: (_, __) => Row(
          children: [
            Expanded(
              child: ISpectifyBuilder(
                iSpectify: ISpect.logger,
                builder: (context, data) =>
                    _buildMainLogsList(context, data, iSpect),
              ),
            ),
            if (_logsViewController.activeData != null) ...[
              VerticalDivider(
                color: iSpect.theme.dividerColor(context) ??
                    context.ispectTheme.dividerColor,
                width: 1,
                thickness: 1,
              ),
              context.screenSizeMaybeWhen(
                phone: () => const SizedBox.shrink(),
                orElse: () => _logsViewController.activeData != null
                    ? Flexible(
                        child: LogScreen(
                          key: ValueKey(
                            _logsViewController.activeData!.hashCode,
                          ),
                          data: _logsViewController.activeData!,
                          onClose: () {
                            _logsViewController.activeData = null;
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainLogsList(
    BuildContext context,
    List<ISpectifyData> logsData,
    ISpectScopeModel iSpectTheme,
  ) {
    final filteredLogEntries = _applyCurrentFilters(logsData);
    final allTitles = logsData.map((entry) => entry.title).toList();
    final uniqueTitles = allTitles.toSet().toList();

    return CustomScrollView(
      controller: _logsScrollController,
      cacheExtent: 1000,
      slivers: [
        ISpectAppBar(
          focusNode: _searchFocusNode,
          title: widget.appBarTitle,
          titlesController: _titleFiltersController,
          titles: allTitles,
          uniqTitles: uniqueTitles,
          controller: _logsViewController,
          onSettingsTap: () => _openLogsSettings(context),
          onInfoTap: () => _showInfoBottomSheet(context),
          onToggleTitle: _handleTitleFilterToggle,
          backgroundColor: iSpectTheme.theme.backgroundColor(context),
        ),
        if (filteredLogEntries.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24, left: 16),
              child: _EmptyLogsWidget(),
            ),
          ),
        _buildVirtualizedLogsList(filteredLogEntries, iSpectTheme),
        const SliverGap(8),
      ],
    );
  }

  Widget _buildVirtualizedLogsList(
    List<ISpectifyData> filteredLogEntries,
    ISpectScopeModel iSpectTheme,
  ) =>
      SliverList.builder(
        itemCount: filteredLogEntries.length,
        itemBuilder: (context, index) {
          final logEntry = _getLogEntryAtIndex(filteredLogEntries, index);

          return _LogListItem(
            key: ValueKey('${logEntry.hashCode}_$index'),
            logData: logEntry,
            itemIndex: index,
            statusIcon: iSpectTheme.theme.logIcons[logEntry.key] ??
                Icons.bug_report_outlined,
            statusColor:
                iSpectTheme.theme.getTypeColor(context, key: logEntry.key),
            isExpanded:
                _logsViewController.activeData?.hashCode == logEntry.hashCode,
            isLastItem: index == filteredLogEntries.length - 1,
            dividerColor: iSpectTheme.theme.dividerColor(context) ??
                context.ispectTheme.dividerColor,
            customItemBuilder: widget.itemsBuilder,
            onCopyPressed: () => _copyLogEntryText(logEntry),
            onItemTapped: () {
              if (_logsViewController.activeData?.hashCode ==
                  logEntry.hashCode) {
                _logsViewController.activeData = null;
              } else {
                _logsViewController.activeData = logEntry;
              }
            },
          );
        },
      );

  /// Applies current filters to the logs data with intelligent caching.
  ///
  /// This method implements smart caching to avoid redundant filter computations:
  /// - Checks if data and filter haven't changed
  /// - Returns cached result when possible
  /// - Recomputes only when necessary
  List<ISpectifyData> _applyCurrentFilters(List<ISpectifyData> logsData) {
    // Get current filter from the controller
    final currentFilter = _logsViewController.filter;

    // Check if we can use cached result (optimization for large datasets)
    if (logsData.length == _lastProcessedDataLength &&
        logsData.isNotEmpty &&
        _cachedFilteredData.isNotEmpty &&
        logsData.last.hashCode == _cachedFilteredData.last.hashCode &&
        // Check if filter hasn't changed
        _lastAppliedFilter == currentFilter) {
      // Data and filter haven't changed, return cached result
      return _cachedFilteredData;
    }

    // Apply the filter using the controller's filter
    final filteredData = logsData.where(currentFilter.apply).toList();
    _cachedFilteredData = filteredData;
    _lastProcessedDataLength = logsData.length;
    _lastAppliedFilter = currentFilter;

    return filteredData;
  }

  /// Handles title filter toggle events from the app bar.
  ///
  /// When a title filter is toggled:
  /// - Adds the title to active filters if selected
  /// - Removes the title from active filters if deselected
  void _handleTitleFilterToggle(String title, bool isSelected) {
    if (isSelected) {
      _logsViewController.addFilterTitle(title);
    } else {
      _logsViewController.removeFilterTitle(title);
    }
  }

  /// Gets the log entry at the specified index, considering log order settings.
  ///
  /// Respects the user's preference for log order (normal or reversed).
  ISpectifyData _getLogEntryAtIndex(
    List<ISpectifyData> filteredEntries,
    int index,
  ) {
    final actualIndex = _logsViewController.isLogOrderReversed
        ? filteredEntries.length - 1 - index
        : index;
    return filteredEntries[actualIndex];
  }

  /// Shows the information bottom sheet with logs statistics and help.
  Future<void> _showInfoBottomSheet(BuildContext context) async {
    await context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ISpectLogsInfoBottomSheet(),
      ),
      orElse: () => showDialog<void>(
        context: context,
        builder: (_) => const ISpectLogsInfoBottomSheet(),
      ),
    );
  }

  /// Opens the logs settings and actions bottom sheet.
  void _openLogsSettings(BuildContext context) {
    final iSpectify = ValueNotifier(ISpect.logger);

    context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _buildSettingsSheet(iSpectify, context),
      ),
      orElse: () => showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (_) => _buildSettingsSheet(iSpectify, context),
      ),
    );
  }

  /// Builds the settings bottom sheet with available actions.
  ISpectSettingsBottomSheet _buildSettingsSheet(
    ValueNotifier<ISpectify> iSpectify,
    BuildContext context,
  ) =>
      ISpectSettingsBottomSheet(
        options: widget.options,
        iSpectify: iSpectify,
        actions: [
          ISpectActionItem(
            onTap: (_) => _logsViewController.toggleLogOrder(),
            title: context.ispectL10n.reverseLogs,
            icon: Icons.swap_vert,
          ),
          ISpectActionItem(
            onTap: _copyAllLogsToClipboard,
            title: context.ispectL10n.copyAllLogs,
            icon: Icons.copy,
          ),
          ISpectActionItem(
            onTap: (_) => _toggleLogsExpansion(),
            title: _logsViewController.expandedLogs
                ? context.ispectL10n.collapseLogs
                : context.ispectL10n.expandLogs,
            icon: _logsViewController.expandedLogs
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          ISpectActionItem(
            onTap: (_) => _clearLogsHistory(),
            title: context.ispectL10n.clearHistory,
            icon: Icons.delete_outline,
          ),
          ISpectActionItem(
            onTap: (_) => _shareLogsAsFile(),
            title: context.ispectL10n.shareLogsFile,
            icon: Icons.ios_share_outlined,
          ),
          ISpectActionItem(
            title: context.ispectL10n.appInfo,
            icon: Icons.info_rounded,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AppInfoScreen(),
                ),
              );
            },
          ),
          ISpectActionItem(
            title: context.ispectL10n.appData,
            icon: Icons.data_usage_rounded,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AppDataScreen(),
                ),
              );
            },
          ),
          ...widget.options.actionItems,
        ],
      );

  /// Copies the text content of a log entry to the clipboard.
  void _copyLogEntryText(ISpectifyData logEntry) {
    final text = logEntry.toJson(truncated: true).toString();
    copyClipboard(context, value: text);
  }

  /// Shares all logs as a downloadable file.
  Future<void> _shareLogsAsFile() async {
    await _logsViewController.downloadLogsFile(
      ISpect.logger.history.formattedText,
    );
  }

  /// Clears the entire logs history.
  void _clearLogsHistory() {
    ISpect.logger.clearHistory();
    _logsViewController.update();
  }

  /// Toggles the expanded state of all logs.
  void _toggleLogsExpansion() {
    _logsViewController.toggleExpandedLogs();
  }

  /// Copies all logs to the clipboard.
  void _copyAllLogsToClipboard(BuildContext context) {
    copyClipboard(
      context,
      value: ISpect.logger.history.formattedText,
      title: '✅ ${context.ispectL10n.allLogsCopied}',
      showValue: false,
    );
  }
}

/// High-performance log list item widget with integrated divider.
///
/// This widget optimizes rendering by:
/// - Combining the log card and divider into a single widget
/// - Using RepaintBoundary for paint optimization
/// - Supporting custom item builders for flexibility
class _LogListItem extends StatelessWidget {
  /// Creates a log list item with integrated divider.
  const _LogListItem({
    required this.logData,
    required this.itemIndex,
    required this.statusIcon,
    required this.statusColor,
    required this.isExpanded,
    required this.isLastItem,
    required this.dividerColor,
    required this.onItemTapped,
    required this.onCopyPressed,
    this.customItemBuilder,
    super.key,
  });

  /// The log data to display
  final ISpectifyData logData;

  /// Index of this item in the list
  final int itemIndex;

  /// Icon representing the log status/type
  final IconData statusIcon;

  /// Color representing the log status/type
  final Color statusColor;

  /// Whether this item is currently expanded
  final bool isExpanded;

  /// Whether this is the last item in the list (affects divider rendering)
  final bool isLastItem;

  /// Color for the divider line
  final Color dividerColor;

  /// Callback when the item is tapped
  final VoidCallback onItemTapped;

  /// Callback when the copy button is pressed
  final VoidCallback onCopyPressed;

  /// Optional custom builder for the item content
  final ISpectifyDataBuilder? customItemBuilder;

  @override
  Widget build(BuildContext context) {
    Widget itemContent;

    if (customItemBuilder != null) {
      itemContent = customItemBuilder!.call(context, logData);
    } else {
      itemContent = RepaintBoundary(
        child: LogCard(
          icon: statusIcon,
          color: statusColor,
          data: logData,
          index: itemIndex,
          isExpanded: isExpanded,
          onCopyTap: onCopyPressed,
          onTap: onItemTapped,
        ),
      );
    }

    // Only add divider if not the last item
    if (isLastItem) {
      return itemContent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        itemContent,
        Container(
          height: 1,
          color: dividerColor,
        ),
      ],
    );
  }
}

/// Widget displayed when no logs match the current filters.
///
/// Shows a helpful message with an icon to indicate that no logs
/// were found matching the current search and filter criteria.
class _EmptyLogsWidget extends StatelessWidget {
  /// Creates an empty logs widget.
  const _EmptyLogsWidget();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 40,
            color: Colors.white70,
          ),
          const Gap(8),
          Text(
            context.ispectL10n.notFound.capitalize(),
            style: context.ispectTheme.textTheme.bodyLarge,
          ),
        ],
      );
}
