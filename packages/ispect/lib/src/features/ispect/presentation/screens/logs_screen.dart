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
import 'package:ispect/src/features/ispect/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/info_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_all_logs_sheet.dart';
import 'package:ispect/src/features/ispect/services/file_processing_service.dart';

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
  final _fileService = FileProcessingService();

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
          onTap: (_) {
            // _logsViewController.shareLogsAsFile(ISpect.logger.history);
            ISpectShareAllLogsBottomSheet(
              controller: _logsViewController,
            ).show(context);
          },
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
        if (ISpect.logger.fileLogHistory != null)
          ISpectActionItem(
            title: 'Daily Sessions',
            icon: Icons.history_rounded,
            onTap: (context) => DailySessionsScreen(
              history: ISpect.logger.fileLogHistory,
            ).push(context),
          ),
        ISpectActionItem(
          title: 'Log Viewer',
          icon: Icons.developer_mode_rounded,
          onTap: (context) {
            _showFileOptionsDialog();
          },
        ),
        ISpectActionItem(
          title: context.ispectL10n.appData,
          icon: Icons.data_usage_rounded,
          onTap: (context) => const AppDataScreen().push(context),
        ),
        ...widget.options.actionItems,
      ];

  Future<void> _showFileOptionsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load File Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how to load your file:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              leading: const Icon(Icons.content_paste),
              title: const Text('Paste Content'),
              subtitle: const Text(
                'Copy .txt or .json file content and paste it here',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showPasteDialog();
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              leading: const Icon(Icons.content_paste),
              title: const Text('Pick Files'),
              subtitle: const Text(
                'Select .txt or .json files from your device',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickFiles();
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '💡 Tip: You can also drag and drop ${_fileService.supportedExtensions.map((e) => '.$e').join(' or ')} files directly to the drop zone above.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Only ${_fileService.supportedExtensions.map((e) => '.$e').join(' and ')} files are supported (max ${_fileService.maxFileSizeFormatted}).',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPasteDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Paste File Content'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paste your file content below:'),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste your .txt or .json file content here...',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _processPastedContent(controller.text);
                }
              },
              child: const Text('Process'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final results = await _fileService.pickAndProcessFiles();

    if (!mounted) return;

    for (final result in results) {
      if (result.success) {
        await ISpectToaster.showInfoToast(
          context,
          title: 'Loaded file: ${result.fileName}',
        );
      } else {
        final color = (result.error?.contains('too large') ?? false) ||
                (result.error?.contains('Unsupported') ?? false)
            ? Colors.orange
            : Colors.red;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.error}: ${result.fileName}'),
            backgroundColor: color,
          ),
        );
      }
    }
  }

  void _processPastedContent(String content) {
    final result = _fileService.processPastedContent(content);

    if (result.success) {
      result.action(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to process content'),
          backgroundColor: Colors.red,
        ),
      );
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
              isExpanded: logsViewController.activeData?.hashCode ==
                      logEntry.hashCode ||
                  logsViewController.expandedLogs,
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
