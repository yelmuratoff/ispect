import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/desktop_metrics.dart';

/// [AppBar] preset shared by ISpect screens that sit on top of the
/// ISpect-themed scaffold background. Disables M3 surface tint / scroll
/// elevation and resolves the background through [BuildContext.ispectThemeBackground].
///
/// Used by all the secondary screens (sessions, navigation flow, JSON viewer);
/// the main logs screen uses its own [SliverAppBar] preset.
class ISpectFlatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ISpectFlatAppBar({
    required this.title,
    this.leading,
    this.actions,
    this.actionsPadding,
    this.backgroundColor,
    super.key,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;

  /// Optional override; defaults to the ISpect theme background, then to the
  /// host scaffold background.
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final toolbarHeight = context.ispectAppBarToolbarHeight;
    final resolvedBg = backgroundColor ??
        context.ispectThemeBackground ??
        context.appTheme.scaffoldBackgroundColor;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: resolvedBg,
      toolbarHeight: toolbarHeight ?? kToolbarHeight,
      leading: leading,
      title: title,
      actions: actions,
      actionsPadding: actionsPadding,
    );
  }
}

/// Standard back-icon button that respects the ISpect AppBar density / icon
/// size tokens. Defaults to `Navigator.pop`.
class ISpectAppBarBackButton extends StatelessWidget {
  const ISpectAppBarBackButton({
    this.onPressed,
    super.key,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ISpectAppBarIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: context.ispectL10n.back,
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
      );
}

/// [IconButton] preset that picks up ISpect's AppBar density / icon-size
/// tokens automatically. Use anywhere a screen needs an `actions:`/`leading:`
/// button on top of [ISpectFlatAppBar] or the main sliver AppBar.
class ISpectAppBarIconButton extends StatelessWidget {
  const ISpectAppBarIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: context.ispectAppBarButtonDensity,
        iconSize: context.ispectAppBarIconSize,
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: color),
      );
}
