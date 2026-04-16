// ignore_for_file: inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectFilterSheet extends StatelessWidget {
  const ISpectFilterSheet({
    required this.controller,
    required this.titles,
    required this.uniqTitles,
    required this.titlesController,
    required this.onToggleTitle,
    required this.onClearAllFilters,
    this.scrollController,
    super.key,
  });

  final ISpectViewController controller;
  final List<String?> titles;
  final List<String?> uniqTitles;
  final GroupButtonController titlesController;
  final Function(String title, bool selected) onToggleTitle;
  final VoidCallback onClearAllFilters;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasSelectedChips = titlesController.selectedIndexes.isNotEmpty;

        return ListView(
          controller: scrollController,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            const ISpectDragHandle(),
            ISpectBottomSheetHeader(
              title: context.ispectL10n.filters,
              icon: Icons.tune_rounded,
            ),
            const Gap(12),

            // Search mode toggle
            _SearchModeSection(
              searchMode: controller.searchMode,
              onChanged: (mode) => controller.searchMode = mode,
            ),

            // Log type chips
            if (uniqTitles.isNotEmpty) ...[
              const Gap(4),
              ISpectSectionLabel(
                title: context.ispectL10n.logTypes,
              ),
              _LogTypeChipsWrap(
                titles: titles,
                uniqTitles: uniqTitles,
                titlesController: titlesController,
                onToggle: onToggleTitle,
                theme: iSpect.theme,
              ),
            ],

            // Clear all — only when chips are selected
            if (hasSelectedChips)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      onClearAllFilters();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: Text(context.ispectL10n.clearAllFilters),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appTheme.colorScheme.error,
                      side: BorderSide(
                        color: context.appTheme.colorScheme.error
                            .withValues(alpha: 0.3),
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            const Gap(8),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Search mode segmented control
// ---------------------------------------------------------------------------

class _SearchModeSection extends StatelessWidget {
  const _SearchModeSection({
    required this.searchMode,
    required this.onChanged,
  });

  final SearchMode searchMode;
  final ValueChanged<SearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.appTheme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ISpectSectionLabel(title: context.ispectL10n.searchMode),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<SearchMode>(
              segments: [
                ButtonSegment<SearchMode>(
                  value: SearchMode.highlight,
                  icon: Icon(
                    Icons.manage_search_rounded,
                    size: 18,
                    color: searchMode == SearchMode.highlight
                        ? primaryColor
                        : null,
                  ),
                  label: Text(context.ispectL10n.search),
                ),
                ButtonSegment<SearchMode>(
                  value: SearchMode.filter,
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color:
                        searchMode == SearchMode.filter ? primaryColor : null,
                  ),
                  label: Text(context.ispectL10n.filters),
                ),
              ],
              selected: {searchMode},
              onSelectionChanged: (selected) => onChanged(selected.first),
              style: SegmentedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Log type chips (Wrap layout inside bottom sheet)
// ---------------------------------------------------------------------------

class _LogTypeChipsWrap extends StatelessWidget {
  const _LogTypeChipsWrap({
    required this.titles,
    required this.uniqTitles,
    required this.titlesController,
    required this.onToggle,
    required this.theme,
  });

  final List<String?> titles;
  final List<String?> uniqTitles;
  final GroupButtonController titlesController;
  final Function(String title, bool selected) onToggle;
  final ISpectTheme theme;

  @override
  Widget build(BuildContext context) {
    final countMap = <String?, int>{};
    for (final t in titles) {
      countMap[t] = (countMap[t] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(uniqTitles.length, (index) {
          final title = uniqTitles[index];
          final count = countMap[title] ?? 0;
          final isSelected = titlesController.selectedIndexes.contains(index);
          final typeColor =
              theme.getTypeColor(context, key: title) ?? Colors.grey;
          final typeIcon = theme.getTypeIcon(context, key: title);

          return _LogTypeChip(
            title: title ?? '',
            count: count,
            isSelected: isSelected,
            typeColor: typeColor,
            typeIcon: typeIcon,
            onSelected: (selected) {
              switch (selected) {
                case true:
                  titlesController.selectIndex(index);
                case false:
                  titlesController.unselectIndex(index);
              }
              onToggle(
                title ?? '',
                titlesController.selectedIndexes.contains(index),
              );
            },
          );
        }),
      ),
    );
  }
}

class _LogTypeChip extends StatelessWidget {
  const _LogTypeChip({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.typeColor,
    required this.typeIcon,
    required this.onSelected,
  });

  final String title;
  final int count;
  final bool isSelected;
  final Color typeColor;
  final IconData typeIcon;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? typeColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: isSelected ? typeColor.withValues(alpha: 0.4) : borderColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, size: 14, color: typeColor),
            const Gap(6),
            Text(
              '$count  $title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? typeColor
                    : context.appTheme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
