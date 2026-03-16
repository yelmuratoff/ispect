import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';

/// Shows a responsive sheet: bottom sheet on phone, dialog on larger screens.
///
/// On phone, wraps content in [DraggableScrollableSheet] with a decorated
/// background (rounded corners). On tablet/desktop, wraps content in
/// [AlertDialog].
Future<T?> showISpectSheet<T>(
  BuildContext context, {
  required Widget Function(
    BuildContext context,
    ScrollController? scrollController,
  ) builder,
  double initialChildSize = 0.4,
  double minChildSize = 0.2,
  double maxChildSize = 0.5,
  double dialogHeightFactor = 0.2,
  double dialogWidth = 500,
  bool topOnlyRadius = false,
  RouteSettings? routeSettings,
  bool useRootNavigator = true,
}) async {
  return context.screenSizeMaybeWhen(
    phone: () => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: routeSettings,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          final iSpect = ISpect.read(context);
          final bgColor = iSpect.theme.background?.resolve(context) ??
              context.appTheme.scaffoldBackgroundColor;

          return ScrollConfiguration(
            behavior: const _ClampingScrollBehavior(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: topOnlyRadius
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : const BorderRadius.all(Radius.circular(16)),
              ),
              child: builder(context, scrollController),
            ),
          );
        },
      ),
    ),
    orElse: () {
      final iSpect = ISpect.read(context);
      final bgColor = iSpect.theme.background?.resolve(context);

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
}

class _ClampingScrollBehavior extends ScrollBehavior {
  const _ClampingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
