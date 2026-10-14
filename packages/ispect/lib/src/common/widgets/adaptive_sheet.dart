import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';
import 'package:ispect/src/core/res/ispect_theme_data.dart';

/// Wraps modal sheet/dialog content in ISpect's owned theme. Modals push onto
/// the root navigator, above the ISpect scope, so [isDark] is resolved from the
/// caller (under the scope) before the modal opens rather than from the modal
/// subtree.
Widget _ispectThemedModal(
  ISpectScopeModel iSpect, {
  required bool isDark,
  required Widget child,
}) => iSpect.theme.useHostColors
    ? child
    : Theme(
        data: buildISpectThemeData(dark: isDark),
        child: child,
      );

/// Shows a responsive sheet: bottom sheet on phone, dialog on larger screens.
///
/// By default the sheet sizes itself to fit its content, growing no taller
/// than [maxHeightFraction] of the screen before its content scrolls. Set
/// [fitContent] to `false` to use a draggable sheet with explicit size
/// fractions instead.
///
/// [builder] receives the sheet's own [BuildContext], inside the modal route
/// and ISpect's modal theme, so `Navigator.of(context).pop()` closes the sheet
/// even when [context] belongs to a nested navigator.
Future<T?> showISpectSheet<T>(
  BuildContext context, {
  required Widget Function(
    BuildContext context,
    ScrollController? scrollController,
  )
  builder,
  bool fitContent = true,
  double maxHeightFraction = 0.85,
  double initialChildSize = 0.4,
  double minChildSize = 0.2,
  double maxChildSize = 0.5,
  double dialogWidth = 500,
  bool topOnlyRadius = false,
  RouteSettings? routeSettings,
  bool useRootNavigator = true,
}) async => context.screenSizeMaybeWhen(
  phone: () {
    final iSpect = ISpect.read(context);
    final isDark = context.ispectIsDark;
    final bgColor =
        iSpect.theme.background?.resolve(context) ??
        (iSpect.theme.useHostColors
            ? context.appTheme.colorScheme.surfaceContainerLowest
            : ISpectDefaultPalette.background.pick(isDark: isDark)!);
    final borderRadius = topOnlyRadius
        ? const BorderRadius.vertical(top: Radius.circular(16))
        : const BorderRadius.all(Radius.circular(16));
    final sheetShape = ISpectSquircle.borderOf(borderRadius);

    if (fitContent) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
        ),
        backgroundColor: bgColor,
        shape: sheetShape,
        routeSettings: routeSettings,
        builder: (_) => _ispectThemedModal(
          iSpect,
          isDark: isDark,
          child: SafeArea(
            child: Builder(
              builder: (sheetContext) => builder(sheetContext, null),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: routeSettings,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (_, scrollController) => ScrollConfiguration(
          behavior: const _ClampingScrollBehavior(),
          child: DecoratedBox(
            decoration: ShapeDecoration(color: bgColor, shape: sheetShape),
            child: _ispectThemedModal(
              iSpect,
              isDark: isDark,
              child: Builder(
                builder: (sheetContext) =>
                    builder(sheetContext, scrollController),
              ),
            ),
          ),
        ),
      ),
    );
  },
  orElse: () {
    final iSpect = ISpect.read(context);
    final isDark = context.ispectIsDark;
    final bgColor =
        iSpect.theme.background?.resolve(context) ??
        (iSpect.theme.useHostColors
            ? context.appTheme.colorScheme.surfaceContainerLowest
            : ISpectDefaultPalette.background.pick(isDark: isDark)!);

    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      builder: (_) => _ispectThemedModal(
        iSpect,
        isDark: isDark,
        child: ScrollConfiguration(
          behavior: const _ClampingScrollBehavior(),
          child: AlertDialog(
            contentPadding: const EdgeInsets.only(bottom: 16),
            backgroundColor: bgColor,
            clipBehavior: Clip.antiAlias,
            content: SizedBox(
              width: dialogWidth,
              child: Builder(
                builder: (sheetContext) => builder(sheetContext, null),
              ),
            ),
          ),
        ),
      ),
    );
  },
);

class _ClampingScrollBehavior extends ScrollBehavior {
  const _ClampingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
