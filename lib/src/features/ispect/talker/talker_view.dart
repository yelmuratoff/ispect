// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/common/widgets/widget/data_card.dart';
import 'package:ispect/src/common/widgets/widget/info_bottom_sheet.dart';
import 'package:ispect/src/common/widgets/widget/settings/settings_bottom_sheet.dart';
import 'package:ispect/src/common/widgets/widget/view_app_bar.dart';
import 'package:ispect/src/features/app_data/app_data.dart';
import 'package:ispect/src/features/app_info/app.dart';
import 'package:ispect/src/features/ispect/talker/actions/actions_bottom_sheet.dart';
import 'package:ispect/src/features/ispect/talker/monitor/pages/monitor/talker_monitor_page.dart';
import 'package:talker_flutter/src/controller/controller.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TalkerView extends StatefulWidget {
  const TalkerView({
    required this.talker,
    required this.options,
    super.key,
    this.controller,
    this.scrollController,
    this.appBarTitle,
    this.itemsBuilder,
    this.appBarLeading,
  });

  /// Talker implementation
  final Talker talker;

  /// Screen [AppBar] title
  final String? appBarTitle;

  /// Screen [AppBar] leading
  final Widget? appBarLeading;

  /// Optional Builder to customize
  /// log items cards in list
  final TalkerDataBuilder? itemsBuilder;

  final TalkerViewController? controller;

  final ScrollController? scrollController;
  final ISpectOptions options;

  @override
  State<TalkerView> createState() => _TalkerViewState();
}

class _TalkerViewState extends State<TalkerView> {
  final _titlesController = GroupButtonController();
  final _focusNode = FocusNode();
  late final _controller = widget.controller ?? TalkerViewController();

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
        builder: (_, __) => TalkerBuilder(
          talker: widget.talker,
          builder: (context, data) {
            final filtredElements =
                data.where((e) => _controller.filter.filter(e)).toList();
            final titles = data.map((e) => e.title).toList();
            final uniqTitles = titles.toSet().toList();

            return CustomScrollView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                TalkerAppBar(
                  focusNode: _focusNode,
                  title: widget.appBarTitle,
                  leading: widget.appBarLeading,
                  talker: widget.talker,
                  titlesController: _titlesController,
                  titles: titles,
                  uniqTitles: uniqTitles,
                  controller: _controller,
                  onMonitorTap: () => _openTalkerMonitor(context),
                  onActionsTap: () => _showActionsBottomSheet(context),
                  onSettingsTap: () {
                    _openTalkerSettings(context);
                  },
                  onInfoTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ISpectLogsInfoBottomSheet(),
                    );
                  },
                  onToggleTitle: _onToggleTitle,
                  isDark: context.isDarkMode,
                  backgroundColor:
                      iSpect.theme.backgroundColor(isDark: context.isDarkMode),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final data = _getListItem(filtredElements, i);
                      if (widget.itemsBuilder != null) {
                        return widget.itemsBuilder!.call(context, data);
                      }
                      return TalkerDataCards(
                        data: data,
                        backgroundColor: iSpect.theme
                                .cardColor(isDark: context.isDarkMode) ??
                            context.ispectTheme.cardColor,
                        onCopyTap: () => _copyTalkerDataItemText(data),
                        expanded: _controller.expandedLogs,
                        color: getTypeColor(
                          isDark: context.isDarkMode,
                          key: data.title,
                        ),
                      );
                    },
                    childCount: filtredElements.length,
                  ),
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

  TalkerData _getListItem(
    List<TalkerData> filtredElements,
    int i,
  ) {
    final data = filtredElements[
        _controller.isLogOrderReversed ? filtredElements.length - 1 - i : i];
    return data;
  }

  void _openTalkerSettings(
    BuildContext context,
  ) {
    final talker = ValueNotifier(widget.talker);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TalkerSettingsBottomSheets(
        options: widget.options,
        talker: talker,
      ),
    );
  }

  void _openTalkerMonitor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (_) => TalkerMonitorPage(
          options: widget.options,
        ),
      ),
    );
  }

  void _copyTalkerDataItemText(TalkerData data) {
    final text = data.generateTextMessage();
    copyClipboard(context, value: text);
  }

  Future<void> _showActionsBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TalkerActionsBottomSheet(
        actions: [
          TalkerActionItem(
            onTap: (_) => _controller.toggleLogOrder(),
            title: context.ispectL10n.reverseLogs,
            icon: Icons.swap_vert,
          ),
          TalkerActionItem(
            onTap: _copyAllLogs,
            title: context.ispectL10n.copyAllLogs,
            icon: Icons.copy,
          ),
          TalkerActionItem(
            onTap: (_) => _toggleLogsExpanded(),
            title: _controller.expandedLogs
                ? context.ispectL10n.collapseLogs
                : context.ispectL10n.expandLogs,
            icon: _controller.expandedLogs
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          TalkerActionItem(
            onTap: (_) => _cleanHistory(),
            title: context.ispectL10n.cleanHistory,
            icon: Icons.delete_outline,
          ),
          TalkerActionItem(
            onTap: (_) => _shareLogsInFile(),
            title: context.ispectL10n.shareLogsFile,
            icon: Icons.ios_share_outlined,
          ),
          TalkerActionItem(
            onTap: (_) => _manageAppData(),
            title: context.ispectL10n.viewAndManageData,
            icon: Icons.data_usage_sharp,
          ),
          TalkerActionItem(
            onTap: (_) => _checkAppInfo(),
            title: context.ispectL10n.appInfo,
            icon: Icons.info_outline_rounded,
          ),
          ...widget.options.actionItems,
        ],
      ),
    );
  }

  Future<void> _shareLogsInFile() async {
    await _controller.downloadLogsFile(
      widget.talker.history.text(),
    );
  }

  Future<void> _manageAppData() async {
    await Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder: (_) => AppDataPage(
          talker: widget.talker,
        ),
      ),
    );
  }

  Future<void> _checkAppInfo() async {
    await Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder: (_) => AppInfoPage(
          talker: widget.talker,
        ),
      ),
    );
  }

  void _cleanHistory() {
    widget.talker.cleanHistory();
    _controller.update();
  }

  void _toggleLogsExpanded() {
    _controller.toggleExpandedLogs();
  }

  void _copyAllLogs(BuildContext context) {
    copyClipboard(
      context,
      value: widget.talker.history.text(),
      title: '✅ ${context.ispectL10n.allLogsCopied}',
      showValue: false,
    );
  }
}
