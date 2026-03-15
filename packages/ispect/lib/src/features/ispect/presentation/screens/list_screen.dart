import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/string.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/gap/sliver_gap.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/desktop_log_row.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_log_bottom_sheet.dart';

/// Screen for browsing, searching, and filtering application logs.
///
/// - Parameters: options, appBarTitle, itemsBuilder, navigatorObserver
/// - Return: StatefulWidget that displays logs in a scrollable list
/// - Usage example: LogsScreen(options: myOptions).push(context)
/// - Edge case notes: Handles empty state when no logs are available
class LogsV2Screen extends StatefulWidget {
  const LogsV2Screen({
    this.logs,
    super.key,
    this.appBarTitle,
    this.sessionPath,
    this.sessionDate,
    this.onShare,
  });

  final String? appBarTitle;
  final List<ISpectLogData>? logs;
  final String? sessionPath;
  final DateTime? sessionDate;
  final ISpectShareCallback? onShare;

  /// Pushes this screen onto the navigation stack
  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect V2 Screen'),
      ),
    );
  }

  @override
  State<LogsV2Screen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsV2Screen> {
  final _titleFiltersController = GroupButtonController();
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();
  late final ISpectViewController _logsViewController;
  final List<ISpectLogData> _logs = [];

  @override
  void initState() {
    super.initState();
    _logsViewController = ISpectViewController(
      onShare: widget.onShare,
    );
    _logsViewController.toggleExpandedLogs();
    getLogs();
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
      backgroundColor: iSpect.theme.background?.resolve(context),
      body: ListenableBuilder(
        listenable: _logsViewController,
        builder: (_, __) {
          final hasDetail = _logsViewController.activeData != null;
          final showDetailPanel = hasDetail && !context.screenSize.isPhone;

          final logsView = _MainLogsView(
            logsData: _logs,
            iSpectTheme: iSpect,
            titleFiltersController: _titleFiltersController,
            searchFocusNode: _searchFocusNode,
            logsScrollController: _logsScrollController,
            logsViewController: _logsViewController,
            appBarTitle: widget.appBarTitle,
          );

          if (!showDetailPanel) {
            return logsView;
          }

          final detailView = _DetailView(
            activeData: _logsViewController.activeData!,
            onClose: () => _logsViewController.activeData = null,
          );

          if (context.screenSize.isDesktop) {
            return ResizableSplitView(
              minRatio: 0.25,
              maxRatio: 0.7,
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
    );
  }

  Future<void> getLogs() async {
    List<ISpectLogData>? logs;
    if (widget.logs != null && widget.logs!.isNotEmpty) {
      logs = widget.logs;
    } else if (widget.sessionPath != null) {
      final fileLogHistory = ISpect.logger.fileLogHistory;
      logs = await fileLogHistory?.getLogsBySession(widget.sessionPath!);
    } else if (widget.sessionDate != null) {
      final fileLogHistory = ISpect.logger.fileLogHistory;
      logs = await fileLogHistory?.getLogsByDate(widget.sessionDate!);
    }
    if (!mounted) return;
    if (logs != null && logs.isNotEmpty) {
      _logs
        ..clear()
        ..addAll(logs);
      setState(() {});
    }
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
    super.key,
  });

  final ISpectLogData logData;
  final int itemIndex;
  final IconData statusIcon;
  final Color statusColor;
  final bool isExpanded;
  final VoidCallback onItemTapped;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context) {
    if (context.screenSize.isDesktop) {
      return DesktopLogRow(
        icon: statusIcon,
        color: statusColor,
        data: logData,
        index: itemIndex,
        isSelected: isExpanded,
        onShareTap: onSharePressed,
        onTap: onItemTapped,
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
      ),
    );
  }
}

/// A widget displayed when there are no logs to show.
class EmptyLogsWidget extends StatelessWidget {
  const EmptyLogsWidget();

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
class _MainLogsView extends StatelessWidget {
  const _MainLogsView({
    required this.logsData,
    required this.iSpectTheme,
    required this.titleFiltersController,
    required this.searchFocusNode,
    required this.logsScrollController,
    required this.logsViewController,
    this.appBarTitle,
  });

  final List<ISpectLogData> logsData;
  final ISpectScopeModel iSpectTheme;
  final GroupButtonController titleFiltersController;
  final FocusNode searchFocusNode;
  final ScrollController logsScrollController;
  final ISpectViewController logsViewController;

  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    final filteredLogEntries = logsViewController.applyCurrentFilters(logsData);
    final titles = logsViewController.getTitles(logsData);

    return CustomScrollView(
      controller: logsScrollController,
      cacheExtent: 1000,
      slivers: [
        ISpectAppBar(
          focusNode: searchFocusNode,
          title: appBarTitle,
          titlesController: titleFiltersController,
          titles: titles.all,
          uniqTitles: titles.unique,
          controller: logsViewController,
          onToggleTitle: (title, selected) => logsViewController
              .handleTitleFilterToggle(title, isSelected: selected),
          backgroundColor: iSpectTheme.theme.background?.resolve(context),
          filteredCount: filteredLogEntries.length,
          totalCount: logsData.length,
        ),
        if (context.screenSize.isDesktop)
          const SliverToBoxAdapter(
            child: DesktopLogTableHeader(),
          ),
        if (filteredLogEntries.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyLogsWidget(),
          ),
        SliverList.builder(
          itemCount: filteredLogEntries.length,
          itemBuilder: (context, index) {
            final (entry: logEntry, actualIndex: _) =
                logsViewController.getLogEntryAtIndex(
              filteredLogEntries,
              index,
            );
            return _LogListItem(
              key: ObjectKey(logEntry),
              logData: logEntry,
              itemIndex: index,
              statusIcon:
                  iSpectTheme.theme.getTypeIcon(context, key: logEntry.key),
              statusColor:
                  iSpectTheme.theme.getTypeColor(context, key: logEntry.key) ??
                      Colors.grey,
              isExpanded: logsViewController.activeData == logEntry ||
                  logsViewController.expandedLogs,
              onSharePressed: () => ISpectShareLogBottomSheet(
                data: logEntry.toJson(),
                truncatedData: logEntry.toJson(truncated: true),
              ).show(context),
              onItemTapped: () => logsViewController.handleLogItemTap(logEntry),
            );
          },
        ),
        const SliverGap(8),
      ],
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
