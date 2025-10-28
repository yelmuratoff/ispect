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
import 'package:super_sliver_list/super_sliver_list.dart';

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
  });

  final String? appBarTitle;
  final ISpectifyDataBuilder? itemsBuilder;
  final ISpectOptions options;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _titleFiltersController = GroupButtonController();
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();
  late final ISpectViewController _logsViewController;
  static const _fileService = FileProcessingService();

  @override
  void initState() {
    super.initState();
    _logsViewController = ISpectViewController(
      onShare: widget.options.onShare,
    );
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
        _buildReverseLogsAction(context),
        _buildCopyAllLogsAction(context),
        _buildExpandLogsAction(context),
        _buildClearHistoryAction(context),
        if (widget.options.onShare != null) _buildShareLogsAction(context),
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
      );

  ISpectActionItem _buildCopyAllLogsAction(BuildContext context) =>
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
      );

  ISpectActionItem _buildClearHistoryAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) =>
            _logsViewController.clearLogsHistory(ISpect.logger.clearHistory),
        title: context.ispectL10n.clearHistory,
        icon: Icons.delete_outline,
      );

  ISpectActionItem _buildShareLogsAction(BuildContext context) =>
      ISpectActionItem(
        onTap: (_) => ISpectShareAllLogsBottomSheet(
          controller: _logsViewController,
        ).show(context),
        title: context.ispectL10n.shareLogsFile,
        icon: Icons.ios_share_outlined,
      );

  ISpectActionItem _buildNavigationFlowAction() => ISpectActionItem(
        title: context.ispectL10n.navigationFlow,
        icon: Icons.route_rounded,
        onTap: (context) => ISpectNavigationFlowScreen(
          observer: widget.options.observer! as ISpectNavigatorObserver,
        ).push(context),
      );

  ISpectActionItem _buildDailySessionsAction() => ISpectActionItem(
        title: context.ispectL10n.dailySessions,
        icon: Icons.history_rounded,
        onTap: (context) => DailySessionsScreen(
          history: ISpect.logger.fileLogHistory,
        ).push(context),
      );

  ISpectActionItem _buildLogViewerAction() => ISpectActionItem(
        title: context.ispectL10n.logViewer,
        icon: Icons.developer_mode_rounded,
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

    if (!mounted || choice == null) {
      return;
    }

    if (choice == _LogSourceChoice.external) {
      await _loadContentFromCallback();
      return;
    }

    if (choice == _LogSourceChoice.paste) {
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

    if (result.success) {
      await result.action(context);
      return;
    }

    _showContentProcessingError(result.error);
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
    required this.isLastItem,
    required this.dividerColor,
    required this.onItemTapped,
    required this.onCopyPressed,
    this.customItemBuilder,
    this.observer,
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

  @override
  Widget build(BuildContext context) {
    final filteredLogEntries = logsViewController.applyCurrentFilters(logsData);
    final titles = logsViewController.getTitles(logsData);
    final dividerColor = _getDividerColor(iSpectTheme, context);
    final options = ISpect.read(context).options;

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
        SuperSliverList.builder(
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
                  iSpectTheme.theme.getTypeColor(context, key: logEntry.key) ??
                      Colors.grey,
              isExpanded: logsViewController.activeData?.hashCode ==
                      logEntry.hashCode ||
                  logsViewController.expandedLogs,
              isLastItem: index == filteredLogEntries.length - 1,
              dividerColor: dividerColor,
              customItemBuilder: itemsBuilder,
              observer: options.observer is ISpectNavigatorObserver
                  ? options.observer as ISpectNavigatorObserver?
                  : null,
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

enum _LogSourceChoice { external, paste }

class _LogSourceDialog extends StatelessWidget {
  const _LogSourceDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
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
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.ispectL10n.pasteContent),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
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
