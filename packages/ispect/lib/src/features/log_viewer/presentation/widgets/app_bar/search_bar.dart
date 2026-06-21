import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/desktop_metrics.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/ispect_input.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// Styled search field shared across log list and JSON viewer screens.
///
/// Callers compose the [trailing] widgets per screen.
class ISpectSearchField extends StatelessWidget {
  const ISpectSearchField({
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hintText,
    this.trailing = const [],
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String? hintText;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;

    return SearchBar(
      focusNode: focusNode,
      controller: controller,
      backgroundColor: WidgetStatePropertyAll(context.ispectCardColor),
      constraints: BoxConstraints(minHeight: context.ispectInputMinHeight),
      shape: WidgetStatePropertyAll(
        ISpectSquircle.border(radius: ISpectInputStyle.radius),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: context.ispectSubtleBorderColor),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: ISpectInputStyle.fontSize, color: onSurface),
      ),
      hintStyle: WidgetStatePropertyAll(ISpectInputStyle.hintStyle(context)),
      leading: Icon(
        Icons.search_rounded,
        size: 18,
        color: onSurface.withValues(alpha: 0.5),
      ),
      trailing: trailing,
      hintText: hintText ?? context.ispectL10n.search,
      onChanged: onChanged,
      elevation: const WidgetStatePropertyAll(0),
    );
  }
}

/// Clear button styled to match [ISpectSearchField].
class ISpectSearchClearButton extends StatelessWidget {
  const ISpectSearchClearButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    return IconButton(
      iconSize: 16,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      tooltip: context.ispectL10n.clearSearch,
      icon: Icon(
        Icons.close_rounded,
        color: onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class ISpectSearchBar extends StatelessWidget {
  const ISpectSearchBar({
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
    super.key,
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
    final isDesktop = context.screenSize.isDesktop;
    return ISpectSearchField(
      focusNode: focusNode,
      controller: searchController,
      onChanged: onChanged,
      trailing: [
        if (isHighlightMode && hasSearchText)
          _SearchMatchNavigation(
            focusedPosition: focusedMatchPosition,
            totalMatches: searchMatchCount,
            onNext: onNextMatch,
            onPrevious: onPreviousMatch,
          )
        else if (hasSearchText)
          ISpectSearchClearButton(onPressed: onClear)
        else if (isDesktop)
          const _SearchShortcutBadge(),
      ],
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
    final primaryColor = context.ispectPrimaryColor;
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
          tooltip: context.ispectL10n.previousMatch,
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
          tooltip: context.ispectL10n.nextMatch,
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
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: color),
      );
}

// ---------------------------------------------------------------------------
// Keyboard shortcut badge (desktop only)
// ---------------------------------------------------------------------------

class _SearchShortcutBadge extends StatelessWidget {
  const _SearchShortcutBadge();

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final isApple = Theme.of(context).platform == TargetPlatform.macOS;
    final label = isApple ? '⌘K' : 'Ctrl+K';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: onSurface.withValues(alpha: 0.05),
          radius: ISpectConstants.mediumBorderRadius,
          side: BorderSide(color: onSurface.withValues(alpha: 0.1)),
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
