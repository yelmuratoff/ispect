// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/onboarding_dialog.dart';

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
    this.onScrollToFocusedMatch,
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

  /// Called when the user taps ↑/↓ arrows to navigate search matches.
  final VoidCallback? onScrollToFocusedMatch;

  @override
  State<ISpectAppBar> createState() => _ISpectAppBarState();
}

class _ISpectAppBarState extends State<ISpectAppBar> {
  TextEditingController get _searchController =>
      widget.controller.searchController;
  final _hasSearchText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _hasSearchText.value = _searchController.text.isNotEmpty;
    _searchController.addListener(_syncSearchText);
  }

  @override
  void dispose() {
    _searchController.removeListener(_syncSearchText);
    _hasSearchText.dispose();
    super.dispose();
  }

  void _syncSearchText() {
    final hasText = _searchController.text.isNotEmpty;
    if (_hasSearchText.value != hasText) {
      _hasSearchText.value = hasText;
    }
  }

  bool get _hasActiveFilters =>
      widget.titlesController.selectedIndexes.isNotEmpty;

  bool get _hasAnyActiveState =>
      _hasActiveFilters || widget.controller.searchMode == SearchMode.filter;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: _hasSearchText,
        builder: (context, hasText, _) => SliverAppBar(
          elevation: 0,
          pinned: true,
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
                color: !widget.controller.isLogOrderReversed
                    ? context.appTheme.colorScheme.primary
                    : null,
              ),
            ),
            IconButton(
              onPressed: () => ISpectOnboardingDialog.show(context),
              tooltip: context.ispectL10n.tips,
              icon: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 22,
              ),
            ),
            if (widget.onSettingsTap != null)
              IconButton(
                onPressed: widget.onSettingsTap,
                tooltip: context.ispectL10n.settings,
                icon: const Icon(Icons.settings_rounded),
              ),
            const Gap(6),
          ],
          title: _AppBarTitle(title: widget.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: EdgeInsets.only(
                left: context.screenSizeWhen(
                  phone: () => 16.0,
                  tablet: () => 16.0,
                  desktop: () => 20.0,
                ),
                right: context.screenSizeWhen(
                  phone: () => 16.0,
                  tablet: () => 16.0,
                  desktop: () => 20.0,
                ),
                bottom: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      focusNode: widget.focusNode,
                      searchController: _searchController,
                      hasSearchText: hasText,
                      isHighlightMode:
                          widget.controller.searchMode == SearchMode.highlight,
                      focusedMatchPosition:
                          widget.controller.focusedMatchPosition,
                      searchMatchCount: widget.controller.searchMatchCount,
                      onChanged: _onSearchChanged,
                      onClear: _onSearchClear,
                      onNextMatch: () {
                        widget.controller.focusNextMatch();
                        widget.onScrollToFocusedMatch?.call();
                      },
                      onPreviousMatch: () {
                        widget.controller.focusPreviousMatch();
                        widget.onScrollToFocusedMatch?.call();
                      },
                    ),
                  ),
                  const Gap(8),
                  _FilterButton(
                    hasActiveState: _hasAnyActiveState,
                    onPressed: () => _showFilterSheet(context),
                  ),
                ],
              ),
            ),
          ),
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

  void _showFilterSheet(BuildContext context) {
    showISpectSheet<void>(
      context,
      fitContent: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      topOnlyRadius: true,
      routeSettings: const RouteSettings(name: 'ISpect Filter Sheet'),
      builder: (context, scrollController) => _FilterSheetContent(
        controller: widget.controller,
        titles: widget.titles,
        uniqTitles: widget.uniqTitles,
        titlesController: widget.titlesController,
        onToggleTitle: widget.onToggleTitle,
        scrollController: scrollController,
        onClearAllFilters: () {
          widget.titlesController.unselectAll();
          widget.controller.clearAllFilters();
        },
      ),
    );
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
            Flexible(
              child: Text(
                title ?? '',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Search bar with inline match navigation
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.focusNode,
    required this.searchController,
    required this.hasSearchText,
    required this.isHighlightMode,
    required this.focusedMatchPosition,
    required this.searchMatchCount,
    required this.onChanged,
    required this.onClear,
    required this.onNextMatch,
    required this.onPreviousMatch,
  });

  final FocusNode focusNode;
  final TextEditingController searchController;
  final bool hasSearchText;
  final bool isHighlightMode;
  final int focusedMatchPosition;
  final int searchMatchCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onNextMatch;
  final VoidCallback onPreviousMatch;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context);

    return SearchBar(
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
          color: context.appTheme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: [
        if (isHighlightMode && hasSearchText)
          _SearchMatchNavigation(
            focusedPosition: focusedMatchPosition,
            totalMatches: searchMatchCount,
            onNext: onNextMatch,
            onPrevious: onPreviousMatch,
          )
        else if (hasSearchText)
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
              color:
                  context.appTheme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          )
        else if (context.screenSize.isDesktop)
          const _SearchShortcutBadge(),
      ],
      hintText: context.ispectL10n.search,
      onChanged: onChanged,
      elevation: const WidgetStatePropertyAll(0),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline search match navigation: [▲] 1/5 [▼]
// ---------------------------------------------------------------------------

class _SearchMatchNavigation extends StatelessWidget {
  const _SearchMatchNavigation({
    required this.focusedPosition,
    required this.totalMatches,
    required this.onNext,
    required this.onPrevious,
  });

  final int focusedPosition;
  final int totalMatches;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.appTheme.colorScheme.primary;
    final mutedColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.3);
    final hasMatches = totalMatches > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: hasMatches ? onPrevious : null,
          color: hasMatches ? primaryColor : mutedColor,
        ),
        Text(
          hasMatches ? '$focusedPosition/$totalMatches' : '0/0',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasMatches ? primaryColor : mutedColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        _NavButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: hasMatches ? onNext : null,
          color: hasMatches ? primaryColor : mutedColor,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: onPressed,
          icon: Icon(icon, color: color),
        ),
      );
}

// ---------------------------------------------------------------------------
// Single filter button (replaces two old buttons)
// ---------------------------------------------------------------------------

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.hasActiveState,
    required this.onPressed,
  });

  final bool hasActiveState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context);

    return Tooltip(
      message: context.ispectL10n.filters,
      child: SizedBox(
        width: 45,
        height: 45,
        child: Material(
          color:
              hasActiveState ? primaryColor.withValues(alpha: 0.12) : cardColor,
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
                  color: hasActiveState
                      ? primaryColor
                      : context.appTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                ),
                if (hasActiveState)
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

class _FilterSheetContent extends StatelessWidget {
  const _FilterSheetContent({
    required this.controller,
    required this.titles,
    required this.uniqTitles,
    required this.titlesController,
    required this.onToggleTitle,
    required this.onClearAllFilters,
    this.scrollController,
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

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------

class _SearchShortcutBadge extends StatelessWidget {
  const _SearchShortcutBadge();

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final isApple = Theme.of(context).platform == TargetPlatform.macOS;
    final label = isApple ? '\u2318K' : 'Ctrl+K';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(
            color: onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: onSurface.withValues(alpha: 0.35),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
