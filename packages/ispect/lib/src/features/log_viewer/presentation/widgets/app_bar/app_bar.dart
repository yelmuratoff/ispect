// ignore_for_file: implementation_imports, inference_failure_on_function_return_type, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/desktop_metrics.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_app_bar_title.dart';
import 'package:ispect/src/common/widgets/ispect_flat_app_bar.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/filter_button.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/filter_sheet.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/search_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/onboarding_dialog.dart';

class ISpectAppBar extends StatefulWidget {
  const ISpectAppBar({
    required this.title,
    required this.controller,
    required this.counts,
    required this.uniqTitles,
    required this.onToggleTitle,
    required this.focusNode,
    this.onSettingsTap,
    this.backgroundColor,
    this.totalCount,
    this.errorCount,
    this.warningCount,
    this.onScrollToFocusedMatch,
    super.key,
  });

  final String? title;

  final ISpectViewController controller;

  final Map<String, int> counts;
  final List<String?> uniqTitles;

  final VoidCallback? onSettingsTap;

  final FocusNode focusNode;

  final Function(String title, bool selected) onToggleTitle;

  final Color? backgroundColor;

  /// Number of logs that pass the active log type filters; the search query
  /// does not narrow it.
  final int? totalCount;

  /// Number of logs counted in [totalCount] that the severity bar marks as
  /// errors: `error` or `critical` level, an error log key, or a trace with
  /// `success: false`. Pass `0` (not `null`) to indicate "computed, none
  /// found".
  final int? errorCount;

  /// Number of logs counted in [totalCount] with `warning` level or the
  /// warning log key.
  final int? warningCount;

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

  bool get _hasAnyActiveState =>
      widget.controller.activeLogTypeFilterCount > 0 ||
      widget.controller.searchMode == SearchMode.filter;

  @override
  Widget build(BuildContext context) {
    final toolbarHeight = context.ispectAppBarToolbarHeight;
    final horizontalPadding = context.screenSizeWhen(
      phone: () => 16.0,
      tablet: () => 16.0,
      desktop: () => 20.0,
    );

    return ValueListenableBuilder(
      valueListenable: _hasSearchText,
      builder: (context, hasText, _) => SliverAppBar(
        elevation: 0,
        pinned: true,
        toolbarHeight: toolbarHeight ?? kToolbarHeight,
        leadingWidth: (toolbarHeight ?? kToolbarHeight) - 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Center(
            child: ISpectAppBarIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: context.ispectL10n.back,
              onPressed: () => context.iSpect.options.pop(context),
            ),
          ),
        ),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor:
            widget.backgroundColor ??
            context.ispectThemeBackground ??
            context.appTheme.scaffoldBackgroundColor,
        actions: [
          ISpectAppBarIconButton(
            icon: Icons.import_export_rounded,
            tooltip: context.ispectL10n.reverseLogs,
            onPressed: widget.controller.toggleLogOrder,
            color: !widget.controller.isLogOrderReversed
                ? context.ispectPrimaryColor
                : null,
          ),
          ISpectAppBarIconButton(
            icon: Icons.tips_and_updates_outlined,
            tooltip: context.ispectL10n.tips,
            onPressed: () => ISpectOnboardingDialog.show(context),
          ),
          if (widget.onSettingsTap != null)
            ISpectAppBarIconButton(
              icon: Icons.settings_outlined,
              tooltip: context.ispectL10n.settings,
              onPressed: widget.onSettingsTap,
            ),
          const Gap(6),
        ],
        title: ISpectAppBarTitle(
          child: _AppBarTitle(
            title: widget.title,
            totalCount: widget.totalCount,
            errorCount: widget.errorCount,
            warningCount: widget.warningCount,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ISpectSearchBar(
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
                ISpectFilterButton(
                  hasActiveState: _hasAnyActiveState,
                  activeFilterCount: widget.controller.activeLogTypeFilterCount,
                  onPressed: () => _showFilterSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      topOnlyRadius: true,
      routeSettings: const RouteSettings(name: 'ISpect Filter Sheet'),
      builder: (context, scrollController) => ISpectFilterSheet(
        controller: widget.controller,
        counts: widget.counts,
        uniqTitles: widget.uniqTitles,
        onToggleTitle: widget.onToggleTitle,
        scrollController: scrollController,
        onClearAllFilters: widget.controller.clearAllFilters,
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.title,
    this.totalCount,
    this.errorCount,
    this.warningCount,
  });

  final String? title;
  final int? totalCount;
  final int? errorCount;
  final int? warningCount;

  @override
  Widget build(BuildContext context) {
    final hasCounter =
        (totalCount ?? 0) > 0 ||
        (errorCount ?? 0) > 0 ||
        (warningCount ?? 0) > 0;
    return Semantics(
      label: title ?? 'ISpect',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.1,
              ),
            ),
          ),
          if (hasCounter)
            _AppBarCounter(
              total: totalCount,
              errors: errorCount,
              warnings: warningCount,
            ),
        ],
      ),
    );
  }
}

class _AppBarCounter extends StatelessWidget {
  const _AppBarCounter({this.total, this.errors, this.warnings});

  final int? total;
  final int? errors;
  final int? warnings;

  @override
  Widget build(BuildContext context) {
    final neutral = context.appTheme.textColor.withValues(alpha: 0.55);
    final errorColor = context.appTheme.colorScheme.error;
    const warningColor = Color(0xFFFFA000);

    final l10n = context.ispectL10n;

    const accent = TextStyle(fontWeight: FontWeight.w700);
    final spans = <InlineSpan>[];

    final totalValue = total ?? 0;
    if (totalValue > 0) {
      spans.add(TextSpan(text: l10n.logCount(totalValue)));
    }
    final warningValue = warnings ?? 0;
    if (warningValue > 0) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(
        TextSpan(
          text: l10n.warningCount(warningValue),
          style: accent.copyWith(color: warningColor),
        ),
      );
    }
    final errorValue = errors ?? 0;
    if (errorValue > 0) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(
        TextSpan(
          text: l10n.errorCount(errorValue),
          style: accent.copyWith(color: errorColor),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: neutral,
          height: 1.2,
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
