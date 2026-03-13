import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/string.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/builder/widget_builder.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/gap/sliver_gap.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';
import 'package:ispect/src/features/ispect/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
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
    return Scaffold(
      backgroundColor: iSpect.theme.background?.resolve(context),
      body: ISpectLogsBuilder(
        logger: ISpect.logger,
        controller: _logsViewController,
        builder: (context, data) => ListenableBuilder(
          listenable: _logsViewController,
          builder: (_, __) => Row(
            children: [
              Expanded(
                child: _MainLogsView(
                  logsData: data,
                  iSpectTheme: iSpect,
                  titleFiltersController: _titleFiltersController,
                  searchFocusNode: _searchFocusNode,
                  logsScrollController: _logsScrollController,
                  logsViewController: _logsViewController,
                  appBarTitle: widget.appBarTitle,
                  itemsBuilder: widget.itemsBuilder,
                  onSettingsTap: () => _openLogsSettings(context),
                ),
              ),
              if (_logsViewController.activeData != null) ...[
                VerticalDivider(
                  color: context.ispectTheme.divider?.resolve(context),
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

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: customItemBuilder?.call(context, logData) ??
            LogCard(
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

/// A widget displayed when there are no logs to show.
class _EmptyLogsWidget extends StatelessWidget {
  const _EmptyLogsWidget();

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: onSurface.withValues(alpha: 0.2),
            ),
            const Gap(12),
            Text(
              context.ispectL10n.notFound.capitalize(),
              style: context.appTheme.textTheme.titleMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
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
    required this.onSettingsTap,
    this.appBarTitle,
    this.itemsBuilder,
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

  @override
  Widget build(BuildContext context) {
    final filteredLogEntries = logsViewController.applyCurrentFilters(logsData);
    final titles = logsViewController.getTitles(logsData);

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
          onToggleTitle: (title, selected) => logsViewController
              .handleTitleFilterToggle(title, isSelected: selected),
          backgroundColor: iSpectTheme.theme.background?.resolve(context),
          filteredCount: filteredLogEntries.length,
          totalCount: logsData.length,
        ),
        if (filteredLogEntries.isEmpty)
          const SliverToBoxAdapter(
            child: _EmptyLogsWidget(),
          ),
        SuperSliverList.builder(
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
              customItemBuilder: itemsBuilder,
              observer: options.observer is ISpectNavigatorObserver
                  ? options.observer as ISpectNavigatorObserver?
                  : null,
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
    return Flexible(
      child: RepaintBoundary(
        child: JsonScreen(
          key: ValueKey(activeData.hashCode),
          data: json,
          truncatedData: activeData.toJson(truncated: true),
          onClose: onClose,
        ),
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
