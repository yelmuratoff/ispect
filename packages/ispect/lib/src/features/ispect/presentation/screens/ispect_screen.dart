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

part '../widgets/not_found_widget.dart';

class ISpectScreen extends StatefulWidget {
  const ISpectScreen({
    required this.options,
    super.key,
    this.appBarTitle,
    this.itemsBuilder,
  });

  /// Screen `AppBar` title
  final String? appBarTitle;

  /// Optional Builder to customize
  /// log items cards in list
  final ISpectifyDataBuilder? itemsBuilder;

  final ISpectOptions options;

  @override
  State<ISpectScreen> createState() => _ISpectScreenState();
}

class _ISpectScreenState extends State<ISpectScreen> {
  final _titlesController = GroupButtonController();
  final _focusNode = FocusNode();
  late final _controller = ISpectifyViewController();

  @override
  void initState() {
    super.initState();
    _controller.toggleExpandedLogs();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _titlesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (_, __) => Row(
          children: [
            Expanded(
              child: ISpectifyBuilder(
                iSpectify: ISpect.logger,
                builder: (context, data) {
                  final filteredElements =
                      data.where((e) => _controller.filter.apply(e)).toList();
                  final titles = data.map((e) => e.title).toList();
                  final uniqTitles = titles.toSet().toList();

                  return CustomScrollView(
                    cacheExtent: 2000,
                    slivers: [
                      ISpectAppBar(
                        focusNode: _focusNode,
                        title: widget.appBarTitle,
                        titlesController: _titlesController,
                        titles: titles,
                        uniqTitles: uniqTitles,
                        controller: _controller,
                        onSettingsTap: () {
                          _openISpectifySettings(context);
                        },
                        onInfoTap: () async {
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
                        },
                        onToggleTitle: _onToggleTitle,
                        backgroundColor: iSpect.theme.backgroundColor(context),
                      ),
                      if (filteredElements.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 24,
                              left: 16,
                            ),
                            child: _NotFoundWidget(),
                          ),
                        ),
                      // Optimized SliverList with better performance characteristics
                      SliverList.builder(
                        itemCount: filteredElements.length,
                        itemBuilder: (context, index) {
                          final data = _getListItem(filteredElements, index);

                          // Custom item builder with divider integrated
                          return _OptimizedLogListItem(
                            key: ValueKey('${data.hashCode}_$index'),
                            data: data,
                            index: index,
                            icon: iSpect.theme.logIcons[data.key] ??
                                Icons.bug_report_outlined,
                            color: iSpect.theme
                                .getTypeColor(context, key: data.key),
                            isExpanded: _controller.activeData?.hashCode ==
                                data.hashCode,
                            isLast: index == filteredElements.length - 1,
                            dividerColor: iSpect.theme.dividerColor(context) ??
                                context.ispectTheme.dividerColor,
                            itemsBuilder: widget.itemsBuilder,
                            onCopyTap: () => _copyISpectifyDataItemText(data),
                            onTap: () {
                              if (_controller.activeData?.hashCode ==
                                  data.hashCode) {
                                _controller.activeData = null;
                              } else {
                                _controller.activeData = data;
                              }
                            },
                          );
                        },
                      ),
                      const SliverGap(8),
                    ],
                  );
                },
              ),
            ),
            if (_controller.activeData != null) ...[
              VerticalDivider(
                color: iSpect.theme.dividerColor(context) ??
                    context.ispectTheme.dividerColor,
                width: 1,
                thickness: 1,
              ),
              context.screenSizeMaybeWhen(
                phone: () => const SizedBox.shrink(),
                orElse: () => _controller.activeData != null
                    ? Flexible(
                        child: LogScreen(
                          key: ValueKey(_controller.activeData!.hashCode),
                          data: _controller.activeData!,
                          onClose: () {
                            _controller.activeData = null;
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

  void _onToggleTitle(String title, bool selected) {
    if (selected) {
      _controller.addFilterTitle(title);
    } else {
      _controller.removeFilterTitle(title);
    }
  }

  ISpectifyData _getListItem(
    List<ISpectifyData> filteredElements,
    int i,
  ) {
    final data = filteredElements[
        _controller.isLogOrderReversed ? filteredElements.length - 1 - i : i];
    return data;
  }

  void _openISpectifySettings(
    BuildContext context,
  ) {
    final iSpectify = ValueNotifier(ISpect.logger);

    context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _settingsBody(iSpectify, context),
      ),
      orElse: () => showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (_) => _settingsBody(iSpectify, context),
      ),
    );
  }

  ISpectifySettingsBottomSheets _settingsBody(
    ValueNotifier<ISpectify> iSpectify,
    BuildContext context,
  ) =>
      ISpectifySettingsBottomSheets(
        options: widget.options,
        iSpectify: iSpectify,
        actions: [
          ISpectActionItem(
            onTap: (_) => _controller.toggleLogOrder(),
            title: context.ispectL10n.reverseLogs,
            icon: Icons.swap_vert,
          ),
          ISpectActionItem(
            onTap: _copyAllLogs,
            title: context.ispectL10n.copyAllLogs,
            icon: Icons.copy,
          ),
          ISpectActionItem(
            onTap: (_) => _toggleLogsExpanded(),
            title: _controller.expandedLogs
                ? context.ispectL10n.collapseLogs
                : context.ispectL10n.expandLogs,
            icon: _controller.expandedLogs
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          ISpectActionItem(
            onTap: (_) => _cleanHistory(),
            title: context.ispectL10n.clearHistory,
            icon: Icons.delete_outline,
          ),
          ISpectActionItem(
            onTap: (_) => _shareLogsInFile(),
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

  void _copyISpectifyDataItemText(ISpectifyData data) {
    final text = data.toJson(truncated: true).toString();
    copyClipboard(context, value: text);
  }

  Future<void> _shareLogsInFile() async {
    await _controller.downloadLogsFile(
      ISpect.logger.history.formattedText,
    );
  }

  void _cleanHistory() {
    ISpect.logger.clearHistory();
    _controller.update();
  }

  void _toggleLogsExpanded() {
    _controller.toggleExpandedLogs();
  }

  void _copyAllLogs(BuildContext context) {
    copyClipboard(
      context,
      value: ISpect.logger.history.formattedText,
      title: '✅ ${context.ispectL10n.allLogsCopied}',
      showValue: false,
    );
  }
}

/// Optimized list item widget with integrated divider for better performance
class _OptimizedLogListItem extends StatelessWidget {
  const _OptimizedLogListItem({
    required this.data,
    required this.index,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.isLast,
    required this.dividerColor,
    required this.onTap,
    required this.onCopyTap,
    this.itemsBuilder,
    super.key,
  });

  final ISpectifyData data;
  final int index;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final bool isLast;
  final Color dividerColor;
  final VoidCallback onTap;
  final VoidCallback onCopyTap;
  final ISpectifyDataBuilder? itemsBuilder;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (itemsBuilder != null) {
      child = itemsBuilder!.call(context, data);
    } else {
      child = LogCard(
        icon: icon,
        color: color,
        data: data,
        index: index,
        isExpanded: isExpanded,
        onCopyTap: onCopyTap,
        onTap: onTap,
      );
    }

    // Only add divider if not the last item
    if (isLast) {
      return child;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Container(
          height: 1,
          color: dividerColor,
        ),
      ],
    );
  }
}
