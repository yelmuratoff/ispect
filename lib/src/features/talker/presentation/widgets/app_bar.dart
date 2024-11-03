// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:talker_flutter/src/controller/controller.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ISpectAppBar extends StatelessWidget {
  const ISpectAppBar({
    required this.title,
    required this.leading,
    required this.talker,
    required this.titlesController,
    required this.controller,
    required this.titles,
    required this.uniqTitles,
    required this.onMonitorTap,
    required this.onSettingsTap,
    required this.onInfoTap,
    required this.onToggleTitle,
    required this.focusNode,
    required this.isDark,
    this.backgroundColor,
    super.key,
  });

  final String? title;
  final Widget? leading;

  final Talker talker;

  final GroupButtonController titlesController;
  final TalkerViewController controller;

  final List<String?> titles;
  final List<String?> uniqTitles;

  final VoidCallback onMonitorTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onInfoTap;

  final FocusNode focusNode;

  final Function(String title, bool selected) onToggleTitle;
  final bool isDark;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return SliverAppBar(
      elevation: 0,
      pinned: true,
      floating: true,
      expandedHeight: 165,
      collapsedHeight: 60,
      toolbarHeight: 60,
      leading: leading,
      scrolledUnderElevation: 0,
      backgroundColor:
          backgroundColor ?? context.ispectTheme.scaffoldBackgroundColor,
      actions: [
        UnconstrainedBox(
          child: IconButton(
            onPressed: onInfoTap,
            icon: const Icon(
              Icons.info_outline_rounded,
            ),
          ),
        ),
        UnconstrainedBox(
          child: _MonitorButton(
            talker: talker,
            onPressed: onMonitorTap,
          ),
        ),
        UnconstrainedBox(
          child: IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(
              Icons.menu_rounded,
            ),
          ),
        ),
        const Gap(10),
      ],
      title: Text(
        title ?? '',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemCount: uniqTitles.length,
                    itemBuilder: (context, index) {
                      final title = uniqTitles[index];
                      final count = titles.where((e) => e == title).length;
                      return InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        onTap: () {
                          if (titlesController.selectedIndexes
                              .contains(index)) {
                            titlesController.unselectIndex(index);
                          } else {
                            titlesController.selectIndex(index);
                          }
                          _onToggle(
                            title,
                            titlesController.selectedIndex == index,
                          );
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: titlesController.selectedIndexes
                                        .contains(index)
                                    ? isDark
                                        ? context.ispectTheme.colorScheme
                                            .primaryContainer
                                        : context
                                            .ispectTheme.colorScheme.primary
                                    : iSpect.theme.dividerColor(
                                          context,
                                        ) ??
                                        context.ispectTheme.dividerColor,
                              ),
                            ),
                            color: titlesController.selectedIndexes
                                    .contains(index)
                                ? isDark
                                    ? context.ispectTheme.colorScheme
                                        .primaryContainer
                                    : context.ispectTheme.colorScheme.primary
                                : context.ispectTheme.cardColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              child: Text(
                                '$count  $title',
                                style: context.ispectTheme.textTheme.bodyMedium!
                                    .copyWith(
                                  color: titlesController.selectedIndexes
                                          .contains(index)
                                      ? Colors.white
                                      : context.ispectTheme.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(12),
                _SearchTextField(
                  controller: controller,
                  focusNode: focusNode,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onToggle(String? title, bool selected) {
    if (title == null) return;
    onToggleTitle(title, selected);
  }
}

class _SearchTextField extends StatelessWidget {
  const _SearchTextField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
  });

  final TalkerViewController controller;
  final FocusNode focusNode;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iSpect = ISpect.read(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        style: theme.textTheme.bodyLarge!.copyWith(
          color: context.ispectTheme.textColor,
          fontSize: 14,
        ),
        cursorColor: isDark
            ? context.ispectTheme.colorScheme.primaryContainer
            : context.ispectTheme.colorScheme.primary,
        focusNode: focusNode,
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: controller.update,
        onChanged: controller.updateFilterSearchQuery,
        decoration: InputDecoration(
          fillColor: theme.cardColor,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDark
                  ? context.ispectTheme.colorScheme.primaryContainer
                  : context.ispectTheme.colorScheme.primary,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: iSpect.theme.dividerColor(context) ??
                  context.ispectTheme.dividerColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: iSpect.theme.dividerColor(context) ??
                  context.ispectTheme.dividerColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(
            Icons.search,
            color: focusNode == FocusScope.of(context).focusedChild
                ? isDark
                    ? context.ispectTheme.colorScheme.primaryContainer
                    : context.ispectTheme.colorScheme.primary
                : iSpect.theme.dividerColor(context) ??
                    context.ispectTheme.hintColor,
            size: 20,
          ),
          hintText: context.ispectL10n.search,
          hintStyle: theme.textTheme.bodyLarge!.copyWith(
            color: context.ispectTheme.hintColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _MonitorButton extends StatelessWidget {
  const _MonitorButton({
    required this.talker,
    required this.onPressed,
  });

  final Talker talker;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TalkerBuilder(
        talker: talker,
        builder: (_, data) {
          final haveErrors =
              data.any((e) => e is TalkerError || e is TalkerException);
          return Stack(
            children: [
              Center(
                child: IconButton(
                  onPressed: onPressed,
                  icon: const Icon(
                    Icons.monitor_heart_outlined,
                  ),
                ),
              ),
              if (haveErrors)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    height: 7,
                    width: 7,
                  ),
                ),
            ],
          );
        },
      );
}
