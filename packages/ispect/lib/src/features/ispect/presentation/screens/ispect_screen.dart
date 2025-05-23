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
      body: GestureDetector(
        onTap: _focusNode.unfocus,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => ISpectifyBuilder(
            iSpectify: ISpect.logger,
            builder: (context, data) {
              final filteredElements =
                  data.where((e) => _controller.filter.apply(e)).toList();
              final titles = data.map((e) => e.title).toList();
              final uniqTitles = titles.toSet().toList();

              return CustomScrollView(
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
                  SliverList.separated(
                    itemCount: filteredElements.length,
                    separatorBuilder: (_, __) => Divider(
                      color: iSpect.theme.dividerColor(context) ??
                          context.ispectTheme.dividerColor,
                      thickness: 1,
                      height: 0,
                    ),
                    itemBuilder: (context, index) {
                      final data = _getListItem(filteredElements, index);
                      if (widget.itemsBuilder != null) {
                        return widget.itemsBuilder!.call(context, data);
                      }

                      return ISpectLogCard(
                        key: ValueKey(data.hashCode),
                        data: data,
                        backgroundColor:
                            iSpect.theme.backgroundColor(context) ??
                                context.ispectTheme.cardColor,
                        onCopyTap: () => _copyISpectifyDataItemText(data),
                        expanded: _controller.expandedLogs,
                        color: iSpect.theme.getTypeColor(
                          context,
                          key: data.key ?? data.title,
                        ),
                      );
                    },
                  ),
                  const SliverGap(8),
                ],
              );
            },
          ),
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
            title: _controller.expandedLogs
                ? context.ispectL10n.collapseLogs
                : context.ispectL10n.expandLogs,
            icon: _controller.expandedLogs
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
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
          ISpectifyActionItem(
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
          ISpectifyActionItem(
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
