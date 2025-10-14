import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/string.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/gap/sliver_gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';

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
  final List<ISpectifyData>? logs;
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
  final List<ISpectifyData> _logs = [];

  @override
  void initState() {
    super.initState();
    _logsViewController = ISpectViewController(onShare: widget.onShare);
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
      backgroundColor: iSpect.theme.backgroundColor(context),
      body: ListenableBuilder(
        listenable: _logsViewController,
        builder: (_, __) => Row(
          children: [
            Expanded(
              child: _MainLogsView(
                logsData: _logs,
                iSpectTheme: iSpect,
                titleFiltersController: _titleFiltersController,
                searchFocusNode: _searchFocusNode,
                logsScrollController: _logsScrollController,
                logsViewController: _logsViewController,
                appBarTitle: widget.appBarTitle,
              ),
            ),
            if (_logsViewController.activeData != null) ...[
              VerticalDivider(
                color: _getDividerColor(iSpect, context),
                width: 1,
                thickness: 1,
              ),
              context.screenSizeMaybeWhen(
                phone: () => const SizedBox.shrink(),
                orElse: () => _DetailView(
                  activeData: _logsViewController.activeData!,
                  onClose: () => _logsViewController.activeData = null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDividerColor(ISpectScopeModel iSpect, BuildContext context) =>
      iSpect.theme.dividerColor(context) ?? context.ispectTheme.dividerColor;

  Future<void> getLogs() async {
    if (widget.logs != null && widget.logs!.isNotEmpty) {
      _logs.addAll(widget.logs!);
    } else if (widget.sessionPath != null) {
      final fileLogHistory = ISpect.logger.fileLogHistory;
      final logs = await fileLogHistory?.getLogsBySession(widget.sessionPath!);
      _logs.addAll(logs ?? []);
    } else if (widget.sessionDate != null) {
      final fileLogHistory = ISpect.logger.fileLogHistory;
      final logs = await fileLogHistory?.getLogsByDate(widget.sessionDate!);
      _logs.addAll(logs ?? []);
    }
    setState(() {});
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
    required this.isLastItem,
    required this.dividerColor,
    required this.onItemTapped,
    required this.onCopyPressed,
    super.key,
  });

  final ISpectifyData logData;
  final int itemIndex;
  final IconData statusIcon;
  final Color statusColor;
  final bool isExpanded;
  final bool isLastItem;
  final Color dividerColor;
  final VoidCallback onItemTapped;
  final VoidCallback onCopyPressed;

  @override
  Widget build(BuildContext context) {
    final itemContent = RepaintBoundary(
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        itemContent,
        if (!isLastItem)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),
      ],
    );
  }
}

/// A widget displayed when there are no logs to show.
class EmptyLogsWidget extends StatelessWidget {
  const EmptyLogsWidget();

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

  final List<ISpectifyData> logsData;
  final ISpectScopeModel iSpectTheme;
  final GroupButtonController titleFiltersController;
  final FocusNode searchFocusNode;
  final ScrollController logsScrollController;
  final ISpectViewController logsViewController;

  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    final filteredLogEntries = logsViewController.applyCurrentFilters(logsData);
    final (allTitles, uniqueTitles) = logsViewController.getTitles(logsData);

    return CustomScrollView(
      controller: logsScrollController,
      cacheExtent: 1000,
      slivers: [
        ISpectAppBar(
          focusNode: searchFocusNode,
          title: appBarTitle,
          titlesController: titleFiltersController,
          titles: allTitles,
          uniqTitles: uniqueTitles,
          controller: logsViewController,
          onToggleTitle: (title, selected) => logsViewController
              .handleTitleFilterToggle(title, isSelected: selected),
          backgroundColor: iSpectTheme.theme.backgroundColor(context),
        ),
        if (filteredLogEntries.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24, left: 16),
              child: EmptyLogsWidget(),
            ),
          ),
        SliverList.builder(
          itemCount: filteredLogEntries.length,
          itemBuilder: (context, index) {
            final logEntry = logsViewController.getLogEntryAtIndex(
              filteredLogEntries,
              index,
            );
            return _LogListItem(
              key: ValueKey('${logEntry.hashCode}_$index'),
              logData: logEntry,
              itemIndex: index,
              statusIcon:
                  iSpectTheme.theme.getTypeIcon(context, key: logEntry.key),
              statusColor:
                  iSpectTheme.theme.getTypeColor(context, key: logEntry.key),
              isExpanded: logsViewController.activeData?.hashCode ==
                      logEntry.hashCode ||
                  logsViewController.expandedLogs,
              isLastItem: index == filteredLogEntries.length - 1,
              dividerColor: _getDividerColor(iSpectTheme, context),
              onCopyPressed: () => logsViewController.copyLogEntryText(
                context,
                logEntry,
                copyClipboard,
              ),
              onItemTapped: () => logsViewController.handleLogItemTap(logEntry),
            );
          },
        ),
        const SliverGap(8),
      ],
    );
  }

  Color _getDividerColor(ISpectScopeModel iSpect, BuildContext context) =>
      iSpect.theme.dividerColor(context) ?? context.ispectTheme.dividerColor;
}

/// Detail view widget for displaying selected log data
class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.activeData,
    required this.onClose,
  });

  final ISpectifyData activeData;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Flexible(
        child: RepaintBoundary(
          child: JsonScreen(
            key: ValueKey(activeData.hashCode),
            data: activeData.toJson(),
            truncatedData: activeData.toJson(truncated: true),
            onClose: onClose,
          ),
        ),
      );
}
