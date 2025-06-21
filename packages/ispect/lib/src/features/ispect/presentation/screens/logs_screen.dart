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
class LogsScreen extends StatefulWidget {
  const LogsScreen({
    required this.options,
    super.key,
    this.appBarTitle,
    this.itemsBuilder,
    this.navigatorObserver,
  });

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect Screen'),
      ),
    );
  }

  final String? appBarTitle;
  final ISpectifyDataBuilder? itemsBuilder;
  final ISpectOptions options;
  final ISpectNavigatorObserver? navigatorObserver;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  static const double _cacheExtent = 1000;
  static const double _dividerHeight = 1;
  static const double _emptyStatePaddingTop = 24;
  static const double _emptyStatePaddingLeft = 16;
  static const double _sliverGapHeight = 8;

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
                builder: (context, data) =>
                    _buildMainLogsList(context, data, iSpect),
              ),
            ),
            if (_logsViewController.activeData != null) ...[
              VerticalDivider(
                color: _getDividerColor(iSpect, context),
                width: _dividerHeight,
                thickness: _dividerHeight,
              ),
              context.screenSizeMaybeWhen(
                phone: () => const SizedBox.shrink(),
                orElse: _buildDetailView,
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
    final filteredLogEntries =
        _logsViewController.applyCurrentFilters(logsData);
    final (allTitles, uniqueTitles) = _logsViewController.getTitles(logsData);
    return CustomScrollView(
      controller: _logsScrollController,
      cacheExtent: _cacheExtent,
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
          onToggleTitle: (title, selected) => _logsViewController
              .handleTitleFilterToggle(title, isSelected: selected),
          backgroundColor: iSpectTheme.theme.backgroundColor(context),
        ),
        if (filteredLogEntries.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: _emptyStatePaddingTop,
                left: _emptyStatePaddingLeft,
              ),
              child: _EmptyLogsWidget(),
            ),
          ),
        _buildVirtualizedLogsList(filteredLogEntries, iSpectTheme),
        const SliverGap(_sliverGapHeight),
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
          final logEntry =
              _logsViewController.getLogEntryAtIndex(filteredLogEntries, index);
          return _LogListItem(
            key: ValueKey('${logEntry.hashCode}_$index'),
            logData: logEntry,
            itemIndex: index,
            statusIcon:
                iSpectTheme.theme.getTypeIcon(context, key: logEntry.key),
            statusColor:
                iSpectTheme.theme.getTypeColor(context, key: logEntry.key),
            isExpanded:
                _logsViewController.activeData?.hashCode == logEntry.hashCode,
            isLastItem: index == filteredLogEntries.length - 1,
            dividerColor: _getDividerColor(iSpectTheme, context),
            customItemBuilder: widget.itemsBuilder,
            onCopyPressed: () => _logsViewController.copyLogEntryText(
              context,
              logEntry,
              copyClipboard,
            ),
            onItemTapped: () => _logsViewController.handleLogItemTap(logEntry),
            observer: widget.navigatorObserver,
          );
        },
      );

  Future<void> _showInfoBottomSheet(BuildContext context) async {
    if (!mounted) return;
    await context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ISpectLogsInfoBottomSheet(),
      ),
      orElse: () => showDialog<void>(
        context: context,
        routeSettings: const RouteSettings(name: 'ISpect Logs Info Dialog'),
        builder: (_) => const ISpectLogsInfoBottomSheet(),
      ),
    );
  }

  Color _getDividerColor(ISpectScopeModel iSpect, BuildContext context) =>
      iSpect.theme.dividerColor(context) ?? context.ispectTheme.dividerColor;

  Widget _buildDetailView() => Flexible(
        child: RepaintBoundary(
          child: JsonScreen(
            key: ValueKey(_logsViewController.activeData!.hashCode),
            data: _logsViewController.activeData!.toJson(),
            truncatedData:
                _logsViewController.activeData!.toJson(truncated: true),
            onClose: () {
              _logsViewController.activeData = null;
            },
          ),
        ),
      );

  void _openLogsSettings(BuildContext context) {
    context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        routeSettings: const RouteSettings(name: 'ISpect Logs Settings Sheet'),
        builder: (_) => _buildSettingsSheet(context),
      ),
      orElse: () => showDialog<void>(
        context: context,
        useRootNavigator: false,
        routeSettings: const RouteSettings(name: 'ISpect Logs Settings Dialog'),
        builder: (_) => _buildSettingsSheet(context),
      ),
    );
  }

  ISpectSettingsBottomSheet _buildSettingsSheet(BuildContext context) {
    final iSpectify = ValueNotifier(ISpect.logger);
    return ISpectSettingsBottomSheet(
      options: widget.options,
      iSpectify: iSpectify,
      controller: _logsViewController,
      actions: _buildSettingsActions(context),
    );
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
          onTap: (context) {
            const AppInfoScreen().push(context);
          },
        ),
        if (widget.navigatorObserver != null)
          ISpectActionItem(
            title: 'Navigation Flow',
            icon: Icons.route_rounded,
            onTap: (context) {
              ISpectNavigationFlowScreen(
                observer: widget.navigatorObserver!,
              ).push(context);
            },
          ),
        ISpectActionItem(
          title: context.ispectL10n.appData,
          icon: Icons.data_usage_rounded,
          onTap: (context) {
            const AppDataScreen().push(context);
          },
        ),
        ...widget.options.actionItems,
      ];
}

/// Log list item widget with integrated divider.
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
    final itemContent = customItemBuilder != null
        ? customItemBuilder!(context, logData)
        : RepaintBoundary(
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
    if (isLastItem) return itemContent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        itemContent,
        Divider(
          height: _LogsScreenState._dividerHeight,
          thickness: _LogsScreenState._dividerHeight,
          color: dividerColor,
        ),
      ],
    );
  }
}

/// Widget displayed when no logs match the current filters.
class _EmptyLogsWidget extends StatelessWidget {
  const _EmptyLogsWidget();
  static const double _iconSize = 40;
  static const Color _iconColor = Colors.white70;
  static const double _gapSize = 8;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: _iconSize,
            color: _iconColor,
          ),
          const Gap(_gapSize),
          Text(
            context.ispectL10n.notFound.capitalize(),
            style: context.ispectTheme.textTheme.bodyLarge,
          ),
        ],
      );
}
