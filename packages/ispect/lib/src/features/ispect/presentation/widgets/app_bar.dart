// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/string.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
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

            // Search + filter chips are placed in `bottom`, which always
            // stays visible when pinned — no collapsing.
            final bottomHeight = showFilters ? 90.0 : 50.0;

            return SliverAppBar(
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
                preferredSize: Size.fromHeight(bottomHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      onClearAll: _onClearAllFilters,
                      searchMode: widget.controller.searchMode,
                      focusedMatchPosition:
                          widget.controller.focusedMatchPosition,
                      searchMatchCount:
                          widget.controller.searchMatchCount,
                      onNextMatch: () {
                        widget.controller.focusNextMatch();
                        widget.onScrollToFocusedMatch?.call();
                      },
                      onPreviousMatch: () {
                        widget.controller.focusPreviousMatch();
                        widget.onScrollToFocusedMatch?.call();
                      },
                      onSearchModeToggle:
                          widget.controller.toggleSearchMode,
                    ),
                    if (showFilters)
                      _FilterChipsList(
                        titles: widget.titles,
                        uniqTitles: widget.uniqTitles,
                        titlesController: widget.titlesController,
                        onToggle: _onToggle,
                      ),
                    const Gap(4),
                  ],
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

  void _onClearAllFilters() {
    _searchController.clear();
    _hasSearchText.value = false;
    widget.titlesController.unselectAll();
    widget.controller.clearAllFilters();
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
    required this.onClearAll,
    required this.searchMode,
    required this.focusedMatchPosition,
    required this.searchMatchCount,
    required this.onNextMatch,
    required this.onPreviousMatch,
    required this.onSearchModeToggle,
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
  final VoidCallback onClearAll;
  final SearchMode searchMode;
  final int focusedMatchPosition;
  final int searchMatchCount;
  final VoidCallback onNextMatch;
  final VoidCallback onPreviousMatch;
  final VoidCallback onSearchModeToggle;

  bool get _isHighlightMode => searchMode == SearchMode.highlight;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context);
    final primaryColor = context.appTheme.colorScheme.primary;

    final horizontalPadding = context.screenSizeWhen(
      phone: () => 16.0,
      tablet: () => 16.0,
      desktop: () => 20.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                // Highlight mode: show navigation (← 3/12 →)
                if (_isHighlightMode && hasSearchText) ...[
                  _SearchMatchNavigation(
                    focusedPosition: focusedMatchPosition,
                    totalMatches: searchMatchCount,
                    onNext: onNextMatch,
                    onPrevious: onPreviousMatch,
                  ),
                ] else ...[
                  if (isFiltering && filteredCount != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '$filteredCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  if (isFiltering)
                    Tooltip(
                      message: context.ispectL10n.clearAllFilters,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6)),
                        ),
                        child: IconButton(
                          iconSize: 20,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: onClearAll,
                          icon: Icon(
                            Icons.filter_alt_off_rounded,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
                if (!isFiltering && !(_isHighlightMode && hasSearchText))
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
                    )
                  else if (context.screenSize.isDesktop)
                    const _SearchShortcutBadge(),
              ],
              hintText: _isHighlightMode
                  ? context.ispectL10n.search
                  : '${context.ispectL10n.search} (${context.ispectL10n.filters.toLowerCase()})',
              onChanged: onChanged,
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          const Gap(8),
          // Search mode toggle (highlight / filter)
          _SearchModeToggle(
            searchMode: searchMode,
            onPressed: onSearchModeToggle,
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

/// Navigation widget for search matches: ← 3/12 →
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
    final hasMatches = totalMatches > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 18,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          onPressed: hasMatches ? onPrevious : null,
          icon: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: hasMatches
                ? primaryColor
                : context.appTheme.colorScheme.onSurface
                    .withValues(alpha: 0.25),
          ),
        ),
        Text(
          hasMatches ? '$focusedPosition/$totalMatches' : '0/0',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasMatches
                ? primaryColor
                : context.appTheme.colorScheme.onSurface
                    .withValues(alpha: 0.35),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          iconSize: 18,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          onPressed: hasMatches ? onNext : null,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: hasMatches
                ? primaryColor
                : context.appTheme.colorScheme.onSurface
                    .withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

/// Toggle button to switch between highlight and filter search modes.
class _SearchModeToggle extends StatelessWidget {
  const _SearchModeToggle({
    required this.searchMode,
    required this.onPressed,
  });

  final SearchMode searchMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isFilterMode = searchMode == SearchMode.filter;
    final primaryColor = context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context);

    return Tooltip(
      message: isFilterMode
          ? context.ispectL10n.search.capitalize()
          : context.ispectL10n.filters.capitalize(),
      child: SizedBox(
        width: 45,
        height: 45,
        child: Material(
          color:
              isFilterMode ? primaryColor.withValues(alpha: 0.12) : cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: onPressed,
            child: Icon(
              isFilterMode
                  ? Icons.filter_list_rounded
                  : Icons.manage_search_rounded,
              size: 22,
              color: isFilterMode
                  ? primaryColor
                  : context.appTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
            ),
          ),
        ),
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

    return Tooltip(
      message: context.ispectL10n.filters,
      child: SizedBox(
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
    final chips = List.generate(uniqTitles.length, (index) {
      final title = uniqTitles[index];
      final count = titles.where((e) => e == title).length;
      final isSelected = titlesController.selectedIndexes.contains(index);
      final typeColor = theme.getTypeColor(context, key: title);
      final typeIcon = theme.getTypeIcon(context, key: title);

      final typeDescription = theme.getTypeDescription(context, key: title);

      return _LogFilterChip(
        title: title ?? '',
        count: count,
        isSelected: isSelected,
        typeColor: typeColor,
        typeIcon: typeIcon,
        typeDescription: typeDescription,
        onSelected: (selected) {
          switch (selected) {
            case true:
              titlesController.selectIndex(index);
            case false:
              titlesController.unselectIndex(index);
          }
          onToggle(
            title,
            titlesController.selectedIndexes.contains(index),
          );
        },
      );
    });

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        key: const ValueKey('filter'),
        height: 36,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const Gap(8),
          itemCount: chips.length,
          itemBuilder: (_, index) => chips[index],
        ),
      ),
    );
  }
}

class _LogFilterChip extends StatefulWidget {
  const _LogFilterChip({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.typeColor,
    required this.typeIcon,
    required this.onSelected,
    this.typeDescription,
  });

  final String title;
  final int count;
  final bool isSelected;
  final Color? typeColor;
  final IconData typeIcon;
  final ValueChanged<bool> onSelected;
  final String? typeDescription;

  @override
  State<_LogFilterChip> createState() => _LogFilterChipState();
}

class _LogFilterChipState extends State<_LogFilterChip> {
  OverlayEntry? _tooltipOverlay;
  Timer? _tooltipTimer;
  Offset _mousePosition = Offset.zero;

  static const _tooltipDelay = Duration(milliseconds: 400);

  void _scheduleTooltip() {
    _cancelTooltip();
    final desc = widget.typeDescription;
    if (desc == null || desc.isEmpty) return;

    _tooltipTimer = Timer(_tooltipDelay, () {
      if (!mounted) return;
      _showOverlayTooltip(desc);
    });
  }

  void _showOverlayTooltip(String text) {
    _removeTooltip();

    final position = _mousePosition;
    final overlay = Overlay.of(context);

    // Convert global mouse position to overlay-local coordinates
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final overlayLocal = overlayBox.globalToLocal(position);

    _tooltipOverlay = OverlayEntry(
      builder: (context) {
        final overlaySize = overlayBox.size;
        const tooltipMaxWidth = 300.0;

        var left = overlayLocal.dx + 12;
        var top = overlayLocal.dy - 32;

        // Clamp to stay within overlay bounds
        if (left + tooltipMaxWidth > overlaySize.width - 8) {
          left = overlaySize.width - tooltipMaxWidth - 8;
        }
        if (left < 8) left = 8;
        if (top < 8) {
          top = overlayLocal.dy + 20;
        }

        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Container(
                constraints: const BoxConstraints(maxWidth: tooltipMaxWidth),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_tooltipOverlay!);
  }

  void _cancelTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _removeTooltip();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay?.dispose();
    _tooltipOverlay = null;
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.typeColor ?? Colors.grey;
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.06);

    return MouseRegion(
      onHover: (event) => _mousePosition = event.position,
      onEnter: (_) => _scheduleTooltip(),
      onExit: (_) => _cancelTooltip(),
      child: GestureDetector(
        onTap: () => widget.onSelected(!widget.isSelected),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.isSelected
                ? effectiveColor.withValues(alpha: 0.08)
                : cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.typeIcon,
                  size: 14,
                  color: effectiveColor,
                ),
                const Gap(6),
                Text(
                  '${widget.count}  ${widget.title}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected
                        ? effectiveColor
                        : context.appTheme.textTheme.bodyMedium?.color,
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
