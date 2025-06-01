// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectAppBar extends StatefulWidget {
  const ISpectAppBar({
    required this.title,
    required this.titlesController,
    required this.controller,
    required this.titles,
    required this.uniqTitles,
    required this.onSettingsTap,
    required this.onInfoTap,
    required this.onToggleTitle,
    required this.focusNode,
    this.backgroundColor,
    super.key,
  });

  final String? title;

  final GroupButtonController titlesController;
  final ISpectifyViewController controller;

  final List<String?> titles;
  final List<String?> uniqTitles;

  final VoidCallback onSettingsTap;
  final VoidCallback onInfoTap;

  final FocusNode focusNode;

  final Function(String title, bool selected) onToggleTitle;

  final Color? backgroundColor;

  @override
  State<ISpectAppBar> createState() => _ISpectAppBarState();
}

class _ISpectAppBarState extends State<ISpectAppBar> {
  final _isFilterEnabled = ValueNotifier(false);

  @override
  void dispose() {
    super.dispose();
    _isFilterEnabled.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: _isFilterEnabled,
        builder: (context, value, _) => SliverAppBar(
          elevation: 0,
          pinned: true,
          floating: true,
          expandedHeight: !value ? 110 : 160,
          collapsedHeight: 60,
          toolbarHeight: 60,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          scrolledUnderElevation: 0,
          backgroundColor: widget.backgroundColor ??
              context.ispectTheme.scaffoldBackgroundColor,
          actions: [
            UnconstrainedBox(
              child: IconButton(
                onPressed: widget.onInfoTap,
                icon: const Icon(
                  Icons.info_outline_rounded,
                ),
              ),
            ),
            UnconstrainedBox(
              child: IconButton(
                onPressed: widget.onSettingsTap,
                icon: const Icon(
                  Icons.settings_rounded,
                ),
              ),
            ),
            const Gap(10),
          ],
          title: Text(
            widget.title ?? '',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchBar(
                        focusNode: widget.focusNode,
                        constraints: const BoxConstraints(
                          minHeight: 45,
                        ),
                        shape: const WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                        ),
                        leading: const Icon(
                          Icons.search_rounded,
                        ),
                        trailing: [
                          Badge(
                            smallSize: 8,
                            alignment: const Alignment(0.8, -0.8),
                            isLabelVisible: widget
                                .titlesController.selectedIndexes.isNotEmpty,
                            child: IconButton(
                              iconSize: 24,
                              onPressed: () {
                                _isFilterEnabled.value =
                                    !_isFilterEnabled.value;
                              },
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ),
                        ],
                        hintText: context.ispectL10n.search,
                        onChanged: widget.controller.updateFilterSearchQuery,
                        elevation: WidgetStateProperty.all(0),
                      ),
                    ),
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: !value
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  key: const ValueKey('filter'),
                                  height: 40,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    separatorBuilder: (_, __) => const Gap(8),
                                    itemCount: widget.uniqTitles.length,
                                    itemBuilder: (context, index) {
                                      final title = widget.uniqTitles[index];
                                      final count = widget.titles
                                          .where((e) => e == title)
                                          .length;
                                      return FilterChip(
                                        selectedColor: context.ispectTheme
                                            .colorScheme.primaryContainer,
                                        label: Text(
                                          '$count  $title',
                                          style: context
                                              .ispectTheme.textTheme.bodyMedium,
                                        ),
                                        selected: widget
                                            .titlesController.selectedIndexes
                                            .contains(index),
                                        onSelected: (selected) {
                                          if (selected) {
                                            widget.titlesController
                                                .selectIndex(index);
                                          } else {
                                            widget.titlesController
                                                .unselectIndex(index);
                                          }
                                          _onToggle(
                                            title,
                                            widget.titlesController
                                                    .selectedIndex ==
                                                index,
                                          );
                                        },
                                        backgroundColor: widget.titlesController
                                                .selectedIndexes
                                                .contains(index)
                                            ? context.isDarkMode
                                                ? context
                                                    .ispectTheme
                                                    .colorScheme
                                                    .primaryContainer
                                                : context.ispectTheme
                                                    .colorScheme.primary
                                            : context.ispectTheme.cardColor,
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  void _onToggle(String? title, bool selected) {
    if (title == null) return;
    widget.onToggleTitle(title, selected);
  }
}
