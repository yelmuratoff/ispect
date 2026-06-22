import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';
import 'package:ispect/src/core/res/ispect_theme_data.dart';

/// Wraps modal sheet/dialog content in ISpect's owned theme. Modals push onto
/// the root navigator, above the ISpect scope, so the theme is resolved from
/// [scopeContext] (the caller, under the scope) rather than the modal subtree.
Widget _ispectThemedModal(
  BuildContext scopeContext,
  ISpectScopeModel iSpect,
  Widget child,
) =>
    iSpect.theme.useHostColors
        ? child
        : Theme(
            data: buildISpectThemeData(dark: scopeContext.ispectIsDark),
            child: child,
          );

/// Shows a responsive sheet: bottom sheet on phone, dialog on larger screens.
///
/// By default the sheet sizes itself to fit its content. Set [fitContent] to
/// `false` to use a draggable sheet with explicit size fractions instead.
Future<T?> showISpectSheet<T>(
  BuildContext context, {
  required Widget Function(
    BuildContext context,
    ScrollController? scrollController,
  ) builder,
  bool fitContent = true,
  double initialChildSize = 0.4,
  double minChildSize = 0.2,
  double maxChildSize = 0.5,
  double dialogWidth = 500,
  bool topOnlyRadius = false,
  RouteSettings? routeSettings,
  bool useRootNavigator = true,
}) async =>
    context.screenSizeMaybeWhen(
      phone: () {
        final iSpect = ISpect.read(context);
        final bgColor = iSpect.theme.background?.resolve(context) ??
            (iSpect.theme.useHostColors
                ? context.appTheme.colorScheme.surfaceContainerLowest
                : ISpectDefaultPalette.background
                    .pick(isDark: context.ispectIsDark)!);
        final borderRadius = (topOnlyRadius
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : const BorderRadius.all(Radius.circular(16))) *
            ISpectSquircle.scale;
        final sheetShape =
            ContinuousRectangleBorder(borderRadius: borderRadius);

        if (fitContent) {
          return showModalBottomSheet<T>(
            context: context,
            isScrollControlled: true,
            backgroundColor: bgColor,
            shape: sheetShape,
            routeSettings: routeSettings,
            builder: (_) => _ispectThemedModal(
              context,
              iSpect,
              SafeArea(child: builder(context, null)),
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
            builder: (context, scrollController) => ScrollConfiguration(
              behavior: const _ClampingScrollBehavior(),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: bgColor,
                  shape: sheetShape,
                ),
                child: _ispectThemedModal(
                  context,
                  iSpect,
                  builder(context, scrollController),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () {
        final iSpect = ISpect.read(context);
        final bgColor = iSpect.theme.background?.resolve(context) ??
            (iSpect.theme.useHostColors
                ? context.appTheme.colorScheme.surfaceContainerLowest
                : ISpectDefaultPalette.background
                    .pick(isDark: context.ispectIsDark)!);

        return showDialog<T>(
          context: context,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          builder: (_) => _ispectThemedModal(
            context,
            iSpect,
            ScrollConfiguration(
              behavior: const _ClampingScrollBehavior(),
              child: AlertDialog(
                contentPadding: const EdgeInsets.only(bottom: 16),
                backgroundColor: bgColor,
                clipBehavior: Clip.antiAlias,
                content: SizedBox(
                  width: dialogWidth,
                  child: builder(context, null),
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
