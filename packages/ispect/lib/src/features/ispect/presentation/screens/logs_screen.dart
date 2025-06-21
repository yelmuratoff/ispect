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
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/info_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_bottom_sheet.dart';
import 'package:ispect/src/features/json_viewer/json_screen.dart';

/// Screen for browsing, searching, and filtering application logs.
///
/// - Parameters: options, appBarTitle, itemsBuilder, navigatorObserver
/// - Return: StatefulWidget that displays logs in a scrollable list
/// - Usage example: LogsScreen(options: myOptions).push(context)
/// - Edge case notes: Handles empty state when no logs are available
class LogsScreen extends StatefulWidget {
  const LogsScreen({
    required this.options,
    super.key,
    this.appBarTitle,
    this.itemsBuilder,
    this.navigatorObserver,
  });

  final String? appBarTitle;
  final ISpectifyDataBuilder? itemsBuilder;
  final ISpectOptions options;
  final ISpectNavigatorObserver? navigatorObserver;

  /// Pushes this screen onto the navigation stack
  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect Screen'),
      ),
    );
  }

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _titleFiltersController = GroupButtonController();
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();
  late final _logsViewController = ISpectViewController();

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
                builder: (context, data) => _MainLogsView(
                  logsData: data,
                  iSpectTheme: iSpect,
                  titleFiltersController: _titleFiltersController,
                  searchFocusNode: _searchFocusNode,
                  logsScrollController: _logsScrollController,
                  logsViewController: _logsViewController,
                  appBarTitle: widget.appBarTitle,
                  itemsBuilder: widget.itemsBuilder,
                  navigatorObserver: widget.navigatorObserver,
                  onSettingsTap: () => _openLogsSettings(context),
                  onInfoTap: () => _showInfoBottomSheet(context),
                ),
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

  Future<void> _showInfoBottomSheet(BuildContext context) async {
    if (!mounted) return;
    await const ISpectLogsInfoBottomSheet().show(context);
  }

  void _openLogsSettings(BuildContext context) {
    final iSpectify = ValueNotifier(ISpect.logger);
    ISpectSettingsBottomSheet(
      options: widget.options,
      iSpectify: iSpectify,
      controller: _logsViewController,
      actions: _buildSettingsActions(context),
    ).show(context);
  }

  List<ISpectActionItem> _buildSettingsActions(BuildContext context) => [
        ISpectActionItem(
          onTap: (_) => _logsViewController.toggleLogOrder(),
          title: context.ispectL10n.reverseLogs,
          icon: Icons.swap_vert,
        ),
        ISpectActionItem(
          onTap: (_) => _logsViewController.copyAllLogsToClipboard(
            context,
            ISpect.logger.history,
            (context, {required value, showValue, title}) {
              copyClipboard(
                context,
                value: value,
                title: title ?? context.ispectL10n.allLogsCopied,
                showValue: showValue ?? false,
              );
            },
            '✅ ${context.ispectL10n.allLogsCopied}',
          ),
          title: context.ispectL10n.copyAllLogs,
          icon: Icons.copy,
        ),
        ISpectActionItem(
          onTap: (_) => _logsViewController.toggleExpandedLogs(),
          title: _logsViewController.expandedLogs
              ? context.ispectL10n.collapseLogs
              : context.ispectL10n.expandLogs,
          icon: _logsViewController.expandedLogs
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        ISpectActionItem(
          onTap: (_) =>
              _logsViewController.clearLogsHistory(ISpect.logger.clearHistory),
          title: context.ispectL10n.clearHistory,
          icon: Icons.delete_outline,
        ),
        ISpectActionItem(
          onTap: (_) =>
              _logsViewController.shareLogsAsFile(ISpect.logger.history),
          title: context.ispectL10n.shareLogsFile,
          icon: Icons.ios_share_outlined,
        ),
        ISpectActionItem(
          title: context.ispectL10n.appInfo,
          icon: Icons.info_rounded,
          onTap: (context) => const AppInfoScreen().push(context),
        ),
        if (widget.navigatorObserver != null)
          ISpectActionItem(
            title: 'Navigation Flow',
            icon: Icons.route_rounded,
            onTap: (context) => ISpectNavigationFlowScreen(
              observer: widget.navigatorObserver!,
            ).push(context),
          ),
        ISpectActionItem(
          title: context.ispectL10n.appData,
          icon: Icons.data_usage_rounded,
          onTap: (context) => const AppDataScreen().push(context),
        ),
        ...widget.options.actionItems,
      ];
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
    this.observer,
    this.customItemBuilder,
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
  final ISpectifyDataBuilder? customItemBuilder;
  final ISpectNavigatorObserver? observer;

  @override
  Widget build(BuildContext context) {
    final itemContent = customItemBuilder?.call(context, logData) ??
        RepaintBoundary(
          child: LogCard(
            icon: statusIcon,
            color: statusColor,
            data: logData,
            index: itemIndex,
            isExpanded: isExpanded,
            onCopyTap: onCopyPressed,
            onTap: onItemTapped,
            observer: observer,
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
class _EmptyLogsWidget extends StatelessWidget {
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

/// Main logs view widget that displays the scrollable list of logs
class _MainLogsView extends StatelessWidget {
  const _MainLogsView({
    required this.logsData,
    required this.iSpectTheme,
    required this.titleFiltersController,
    required this.searchFocusNode,
    required this.logsScrollController,
    required this.logsViewController,
    required this.onSettingsTap,
    required this.onInfoTap,
    this.appBarTitle,
    this.itemsBuilder,
    this.navigatorObserver,
  });

  final List<ISpectifyData> logsData;
  final ISpectScopeModel iSpectTheme;
  final GroupButtonController titleFiltersController;
  final FocusNode searchFocusNode;
  final ScrollController logsScrollController;
  final ISpectViewController logsViewController;
  final VoidCallback onSettingsTap;
  final VoidCallback onInfoTap;
  final String? appBarTitle;
  final ISpectifyDataBuilder? itemsBuilder;
  final ISpectNavigatorObserver? navigatorObserver;

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
          onSettingsTap: onSettingsTap,
          onInfoTap: onInfoTap,
          onToggleTitle: (title, selected) => logsViewController
              .handleTitleFilterToggle(title, isSelected: selected),
          backgroundColor: iSpectTheme.theme.backgroundColor(context),
        ),
        if (filteredLogEntries.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24, left: 16),
              child: _EmptyLogsWidget(),
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
              isExpanded:
                  logsViewController.activeData?.hashCode == logEntry.hashCode,
              isLastItem: index == filteredLogEntries.length - 1,
              dividerColor: _getDividerColor(iSpectTheme, context),
              customItemBuilder: itemsBuilder,
              onCopyPressed: () => logsViewController.copyLogEntryText(
                context,
                logEntry,
                copyClipboard,
              ),
              onItemTapped: () => logsViewController.handleLogItemTap(logEntry),
              observer: navigatorObserver,
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
