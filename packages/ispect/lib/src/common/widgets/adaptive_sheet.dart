import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';

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
            context.appTheme.colorScheme.surfaceContainerLowest;
        final borderRadius = topOnlyRadius
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : const BorderRadius.all(Radius.circular(16));

        if (fitContent) {
          return showModalBottomSheet<T>(
            context: context,
            isScrollControlled: true,
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            routeSettings: routeSettings,
            builder: (_) => SafeArea(
              child: builder(context, null),
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
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: borderRadius,
                ),
                child: builder(context, scrollController),
              ),
            ),
          ),
        );
      },
      orElse: () {
        final iSpect = ISpect.read(context);
        final bgColor = iSpect.theme.background?.resolve(context) ??
            context.appTheme.colorScheme.surfaceContainerLowest;

        return showDialog<T>(
          context: context,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          builder: (_) => ScrollConfiguration(
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
        );
      },
    );

class _ClampingScrollBehavior extends ScrollBehavior {
  const _ClampingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
