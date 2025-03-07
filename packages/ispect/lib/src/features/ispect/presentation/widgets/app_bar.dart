// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/textfields/search_field.dart';

class ISpectAppBar extends StatelessWidget {
  const ISpectAppBar({
    required this.title,
    required this.leading,
    required this.iSpectify,
    required this.titlesController,
    required this.controller,
    required this.titles,
    required this.uniqTitles,
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

  final ISpectify iSpectify;

  final GroupButtonController titlesController;
  final ISpectifyViewController controller;

  final List<String?> titles;
  final List<String?> uniqTitles;

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

  final ISpectifyViewController controller;
  final FocusNode focusNode;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    ISpect.read(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SearchField(
        onChanged: controller.updateFilterSearchQuery,
        controller: null,
      ),
    );
  }
}
