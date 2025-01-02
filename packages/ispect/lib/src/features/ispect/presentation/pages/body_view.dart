// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/builder/data_builder.dart';
import 'package:ispect/src/common/widgets/builder/widget_builder.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/app_bar.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/info_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_bottom_sheet.dart';

class ISpectPageView extends StatefulWidget {
  const ISpectPageView({
    required this.iSpectify,
    required this.options,
    super.key,
    this.controller,
    this.scrollController,
    this.appBarTitle,
    this.itemsBuilder,
    this.appBarLeading,
  });

  /// ISpectiy implementation
  final ISpectiy iSpectify;

  /// Screen [AppBar] title
  final String? appBarTitle;

  /// Screen [AppBar] leading
  final Widget? appBarLeading;

  /// Optional Builder to customize
  /// log items cards in list
  final ISpectifyDataBuilder? itemsBuilder;

  final ISpectifyViewController? controller;

  final ScrollController? scrollController;

  final ISpectOptions options;

  @override
  State<ISpectPageView> createState() => _ISpectPageViewState();
}

class _ISpectPageViewState extends State<ISpectPageView> {
  final _titlesController = GroupButtonController();
  final _focusNode = FocusNode();
  late final _controller = widget.controller ?? ISpectifyViewController();

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
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => ISpectifyBuilder(
          iSpectify: widget.iSpectify,
          builder: (context, data) {
            final filtredElements = data.where((e) => _controller.filter.filter(e)).toList();
            final titles = data.map((e) => e.title).toList();
            final uniqTitles = titles.toSet().toList();

            return CustomScrollView(
              controller: widget.scrollController,
              slivers: [
                ISpectAppBar(
                  focusNode: _focusNode,
                  title: widget.appBarTitle,
                  leading: widget.appBarLeading,
                  iSpectify: widget.iSpectify,
                  titlesController: _titlesController,
                  titles: titles,
                  uniqTitles: uniqTitles,
                  controller: _controller,
                  onSettingsTap: () {
                    _openISpectifySettings(context);
                  },
                  onInfoTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ISpectLogsInfoBottomSheet(),
                    );
                  },
                  onToggleTitle: _onToggleTitle,
                  isDark: context.isDarkMode,
                  backgroundColor: iSpect.theme.backgroundColor(context),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverList.separated(
                  itemCount: filtredElements.length,
                  separatorBuilder: (_, __) => Divider(
                    color: iSpect.theme.dividerColor(context) ?? context.ispectTheme.dividerColor,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final data = _getListItem(filtredElements, index);
                    if (widget.itemsBuilder != null) {
                      return widget.itemsBuilder!.call(context, data);
                    }

                    return ISpectLogCard(
                      key: ValueKey(data.time.microsecondsSinceEpoch),
                      data: data,
                      backgroundColor: context.ispectTheme.cardColor,
                      onCopyTap: () => _copyISpectifyDataItemText(data),
                      expanded: _controller.expandedLogs,
                      color: iSpect.theme.getTypeColor(
                        context,
                        key: data.key ?? data.title,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            );
          },
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

  ISpectiyData _getListItem(
    List<ISpectiyData> filtredElements,
    int i,
  ) {
    final data = filtredElements[_controller.isLogOrderReversed ? filtredElements.length - 1 - i : i];
    return data;
  }

  void _openISpectifySettings(
    BuildContext context,
  ) {
    final iSpectify = ValueNotifier(widget.iSpectify);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ISpectifySettingsBottomSheets(
        options: widget.options,
        iSpectify: iSpectify,
        actions: [
          ISpectifyActionItem(
            onTap: (_) => _controller.toggleLogOrder(),
            title: context.ispectL10n.reverseLogs,
            icon: Icons.swap_vert,
          ),
          ISpectifyActionItem(
            onTap: _copyAllLogs,
            title: context.ispectL10n.copyAllLogs,
            icon: Icons.copy,
          ),
          ISpectifyActionItem(
            onTap: (_) => _toggleLogsExpanded(),
            title: _controller.expandedLogs ? context.ispectL10n.collapseLogs : context.ispectL10n.expandLogs,
            icon: _controller.expandedLogs ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          ISpectifyActionItem(
            onTap: (_) => _cleanHistory(),
            title: context.ispectL10n.clearHistory,
            icon: Icons.delete_outline,
          ),
          ISpectifyActionItem(
            onTap: (_) => _shareLogsInFile(),
            title: context.ispectL10n.shareLogsFile,
            icon: Icons.ios_share_outlined,
          ),
          ...widget.options.actionItems,
        ],
      ),
    );
  }

  void _copyISpectifyDataItemText(ISpectiyData data) {
    final text = data.textMessage;
    copyClipboard(context, value: text);
  }

  Future<void> _shareLogsInFile() async {
    await _controller.downloadLogsFile(
      widget.iSpectify.history.formattedText,
    );
  }

  void _cleanHistory() {
    widget.iSpectify.clearHistory();
    _controller.update();
  }

  void _toggleLogsExpanded() {
    _controller.toggleExpandedLogs();
  }

  void _copyAllLogs(BuildContext context) {
    copyClipboard(
      context,
      value: widget.iSpectify.history.formattedText,
      title: '✅ ${context.ispectL10n.allLogsCopied}',
      showValue: false,
    );
  }
}
