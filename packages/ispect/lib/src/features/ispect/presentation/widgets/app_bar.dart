// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/daily_sessions.dart';

class ISpectAppBar extends StatefulWidget {
  const ISpectAppBar({
    required this.title,
    required this.titlesController,
    required this.controller,
    required this.titles,
    required this.uniqTitles,
    required this.onToggleTitle,
    required this.focusNode,
    this.onSettingsTap,
    this.backgroundColor,
    this.filteredCount,
    this.totalCount,
    super.key,
  });

  final String? title;

  final GroupButtonController titlesController;
  final ISpectViewController controller;

  final List<String?> titles;
  final List<String?> uniqTitles;

  final VoidCallback? onSettingsTap;

  final FocusNode focusNode;

  final Function(String title, bool selected) onToggleTitle;

  final Color? backgroundColor;

  final int? filteredCount;
  final int? totalCount;

  @override
  State<ISpectAppBar> createState() => _ISpectAppBarState();
}

class _ISpectAppBarState extends State<ISpectAppBar> {
  final _isFilterEnabled = ValueNotifier(false);
  final _searchController = TextEditingController();
  final _hasSearchText = ValueNotifier(false);

  @override
  void dispose() {
    _isFilterEnabled.dispose();
    _searchController.dispose();
    _hasSearchText.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      widget.titlesController.selectedIndexes.isNotEmpty;

  bool get _showFilters => _isFilterEnabled.value || _hasActiveFilters;

  bool get _isFiltering {
    final filtered = widget.filteredCount;
    final total = widget.totalCount;
    if (filtered == null || total == null) return false;
    return filtered != total || _hasSearchText.value || _hasActiveFilters;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: _isFilterEnabled,
        builder: (context, filterExpanded, _) => ValueListenableBuilder(
          valueListenable: _hasSearchText,
          builder: (context, hasText, _) {
            final showFilters = _showFilters;

            return SliverAppBar(
              elevation: 0,
              pinned: true,
              floating: true,
              expandedHeight: showFilters ? 148.0 : 110.0,
              collapsedHeight: 60,
              toolbarHeight: 60,
              leading: IconButton(
                onPressed: () => context.iSpect.options.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              backgroundColor: widget.backgroundColor ??
                  context.ispectTheme.background?.resolve(context) ??
                  context.appTheme.scaffoldBackgroundColor,
              actions: [
                IconButton(
                  onPressed: widget.controller.toggleLogOrder,
                  tooltip: context.ispectL10n.reverseLogs,
                  icon: Icon(
                    Icons.swap_vert_rounded,
                    size: 22,
                    color: widget.controller.isLogOrderReversed
                        ? context.appTheme.colorScheme.primary
                        : null,
                  ),
                ),
                if (widget.onSettingsTap != null)
                  IconButton(
                    onPressed: widget.onSettingsTap,
                    icon: const Icon(Icons.settings_rounded),
                  ),
                const Gap(6),
              ],
              title: _AppBarTitle(title: widget.title),
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        _SearchSection(
                          focusNode: widget.focusNode,
                          searchController: _searchController,
                          hasSearchText: hasText,
                          hasActiveFilters: _hasActiveFilters,
                          isFilterExpanded: filterExpanded,
                          isFiltering: _isFiltering,
                          filteredCount: widget.filteredCount,
                          totalCount: widget.totalCount,
                          onChanged: _onSearchChanged,
                          onClear: _onSearchClear,
                          onFilterToggle: _onFilterToggle,
                        ),
                        if (showFilters)
                          Flexible(
                            child: _FilterChipsList(
                              titles: widget.titles,
                              uniqTitles: widget.uniqTitles,
                              titlesController: widget.titlesController,
                              onToggle: _onToggle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  void _onSearchChanged(String query) {
    _hasSearchText.value = query.isNotEmpty;
    widget.controller.updateFilterSearchQuery(query);
  }

  void _onSearchClear() {
    _searchController.clear();
    _hasSearchText.value = false;
    widget.controller.updateFilterSearchQuery('');
  }

  void _onFilterToggle() {
    _isFilterEnabled.value = !_isFilterEnabled.value;
  }

  void _onToggle(String? title, bool selected) {
    if (title == null) return;
    widget.onToggleTitle(title, selected);
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.title});

  final String? title;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          if (kReleaseMode) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DailySessionsScreen(
                history: ISpect.logger.fileLogHistory,
              ),
              settings: const RouteSettings(name: 'ISpect Info Screen'),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.focusNode,
    required this.searchController,
    required this.hasSearchText,
    required this.hasActiveFilters,
    required this.isFilterExpanded,
    required this.isFiltering,
    required this.filteredCount,
    required this.totalCount,
    required this.onChanged,
    required this.onClear,
    required this.onFilterToggle,
  });

  final FocusNode focusNode;
  final TextEditingController searchController;
  final bool hasSearchText;
  final bool hasActiveFilters;
  final bool isFilterExpanded;
  final bool isFiltering;
  final int? filteredCount;
  final int? totalCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterToggle;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              focusNode: focusNode,
              controller: searchController,
              backgroundColor: WidgetStatePropertyAll(cardColor),
              constraints: const BoxConstraints(minHeight: 45),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: context.appTheme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
              trailing: [
                if (isFiltering && filteredCount != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '$filteredCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                if (hasSearchText)
                  IconButton(
                    iconSize: 20,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onClear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.appTheme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
              ],
              hintText: context.ispectL10n.search,
              onChanged: onChanged,
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          const Gap(8),
          _FilterToggleButton(
            isExpanded: isFilterExpanded,
            hasActiveFilters: hasActiveFilters,
            onPressed: onFilterToggle,
          ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.isExpanded,
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool isExpanded;
  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isActive = isExpanded || hasActiveFilters;
    final primaryColor = context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context);

    return SizedBox(
      width: 45,
      height: 45,
      child: Material(
        color: isActive ? primaryColor.withValues(alpha: 0.12) : cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: isActive
                    ? primaryColor
                    : context.appTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 8, height: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipsList extends StatelessWidget {
  const _FilterChipsList({
    required this.titles,
    required this.uniqTitles,
    required this.titlesController,
    required this.onToggle,
  });

  final List<String?> titles;
  final List<String?> uniqTitles;
  final GroupButtonController titlesController;
  final void Function(String? title, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ISpect.read(context).theme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        key: const ValueKey('filter'),
        height: 32,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const Gap(8),
          itemCount: uniqTitles.length,
          itemBuilder: (context, index) {
            final title = uniqTitles[index];
            final count = titles.where((e) => e == title).length;
            final isSelected = titlesController.selectedIndexes.contains(index);
            final typeColor = theme.getTypeColor(context, key: title);
            final typeIcon = theme.getTypeIcon(context, key: title);

            return _LogFilterChip(
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
                  title,
                  titlesController.selectedIndex == index,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LogFilterChip extends StatelessWidget {
  const _LogFilterChip({
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
  final Color? typeColor;
  final IconData typeIcon;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = typeColor ?? Colors.grey;
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              isSelected ? effectiveColor.withValues(alpha: 0.08) : cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                typeIcon,
                size: 14,
                color: effectiveColor,
              ),
              const Gap(6),
              Text(
                '$count  $title',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? effectiveColor
                      : context.appTheme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
