// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:talker_flutter/src/controller/controller.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TalkerAppBar extends StatelessWidget {
  const TalkerAppBar({
    required this.title,
    required this.leading,
    required this.talker,
    required this.titlesController,
    required this.controller,
    required this.titles,
    required this.uniqTitles,
    required this.onMonitorTap,
    required this.onSettingsTap,
    required this.onActionsTap,
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
  final VoidCallback onActionsTap;
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
      expandedHeight: 174,
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
              Icons.info_rounded,
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
              Icons.settings_rounded,
            ),
          ),
        ),
        UnconstrainedBox(
          child: IconButton(
            onPressed: onActionsTap,
            icon: const Icon(
              Icons.menu_rounded,
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      title: title != null
          ? Text(
              title!,
              style: context.ispectTheme.textTheme.headlineSmall,
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    scrollDirection: Axis.horizontal,
                    children: [
                      GroupButton(
                        controller: titlesController,
                        isRadio: false,
                        buttonBuilder: (selected, value, context) {
                          final count = titles.where((e) => e == value).length;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.fromBorderSide(
                                BorderSide(
                                  color: selected
                                      ? isDark
                                          ? context.ispectTheme.colorScheme
                                              .primaryContainer
                                          : context
                                              .ispectTheme.colorScheme.primary
                                      : iSpect.theme.dividerColor(
                                            isDark: context.isDarkMode,
                                          ) ??
                                          context.ispectTheme.dividerColor,
                                ),
                              ),
                              color: selected
                                  ? isDark
                                      ? context.ispectTheme.colorScheme
                                          .primaryContainer
                                      : context.ispectTheme.colorScheme.primary
                                  : iSpect.theme.cardColor(
                                        isDark: context.isDarkMode,
                                      ) ??
                                      context.ispectTheme.cardColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Align(
                                child: Text(
                                  '$count  $value',
                                  style: context
                                      .ispectTheme.textTheme.bodyMedium!
                                      .copyWith(
                                    color: selected
                                        ? Colors.white
                                        : context.ispectTheme.textColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (_, i, selected) =>
                            _onToggle(uniqTitles[i], selected),
                        buttons: uniqTitles,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
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
              color: iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
                  context.ispectTheme.dividerColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
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
                : iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
                    context.ispectTheme.dividerColor,
            size: 20,
          ),
          hintText: context.ispectL10n.search,
          hintStyle: theme.textTheme.bodyLarge!.copyWith(
            color: context.ispectTheme.textColor,
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
