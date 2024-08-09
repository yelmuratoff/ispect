// ignore_for_file: avoid_empty_blocks
import 'package:flutter/material.dart';

class CircularMenuItem {
  const CircularMenuItem({
    required this.onTap,
    this.icon,
    this.color,
    this.iconSize = 30,
    this.boxShadow,
    this.iconColor,
    this.animatedIcon,
    this.padding = 10,
    this.margin = 10,
    this.enableBadge = false,
    this.badgeBottomOffset,
    this.badgeLeftOffset,
    this.badgeRightOffset,
    this.badgeTopOffset,
    this.badgeRadius,
    this.badgeTextStyle,
    this.badgeLabel,
    this.badgeTextColor,
    this.badgeColor,
    this.onTapClosesMenu = true,
  });

  final IconData? icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onTap;
  final double iconSize;
  final double padding;
  final double margin;
  final List<BoxShadow>? boxShadow;
  final bool enableBadge;
  final double? badgeRightOffset;
  final double? badgeLeftOffset;
  final double? badgeTopOffset;
  final double? badgeBottomOffset;
  final double? badgeRadius;
  final TextStyle? badgeTextStyle;
  final String? badgeLabel;
  final Color? badgeTextColor;
  final Color? badgeColor;
  final AnimatedIcon? animatedIcon;
  final bool onTapClosesMenu;
}

class CircularMenuItemWidget extends StatelessWidget {
  const CircularMenuItemWidget({
    required this.item,
    super.key,
    this.closeMenu,
  });

  final CircularMenuItem item;
  final VoidCallback? closeMenu;

  Widget _buildCircularMenuItem(BuildContext context) => Container(
        margin: EdgeInsets.all(item.margin),
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: item.boxShadow ??
              [
                BoxShadow(
                  color: item.color ?? Theme.of(context).primaryColor,
                  blurRadius: 10,
                ),
              ],
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Material(
            color: item.color ?? Theme.of(context).primaryColor,
            child: InkWell(
              child: Padding(
                padding: EdgeInsets.all(item.padding),
                child: item.animatedIcon ??
                    Icon(
                      item.icon,
                      size: item.iconSize,
                      color: item.iconColor ?? Colors.white,
                    ),
              ),
              onTap: () {
                item.onTap();
                if (item.onTapClosesMenu) {
                  closeMenu?.call();
                }
              },
            ),
          ),
        ),
      );

  Widget _buildCircularMenuItemWithBadge(BuildContext context) => _Badge(
        color: item.badgeColor,
        bottomOffset: item.badgeBottomOffset,
        rightOffset: item.badgeRightOffset,
        leftOffset: item.badgeLeftOffset,
        topOffset: item.badgeTopOffset,
        radius: item.badgeRadius,
        textStyle: item.badgeTextStyle,
        onTap: item.onTap,
        textColor: item.badgeTextColor,
        label: item.badgeLabel,
        child: _buildCircularMenuItem(context),
      );

  @override
  Widget build(BuildContext context) =>
      item.enableBadge ? _buildCircularMenuItemWithBadge(context) : _buildCircularMenuItem(context);
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.child,
    required this.label,
    this.color,
    this.textColor,
    this.onTap,
    this.radius,
    this.bottomOffset,
    this.leftOffset,
    this.rightOffset,
    this.topOffset,
    this.textStyle,
  });

  final Widget child;
  final String? label;
  final Color? color;
  final Color? textColor;
  final Function? onTap;
  final double? rightOffset;
  final double? leftOffset;
  final double? topOffset;
  final double? bottomOffset;
  final double? radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: (leftOffset == null && rightOffset == null) ? 8 : rightOffset,
            top: (topOffset == null && bottomOffset == null) ? 8 : topOffset,
            left: leftOffset,
            bottom: bottomOffset,
            child: FittedBox(
              child: GestureDetector(
                onTap: onTap as VoidCallback? ?? () {},
                child: CircleAvatar(
                  maxRadius: radius ?? 10,
                  minRadius: radius ?? 10,
                  backgroundColor: color ?? Theme.of(context).primaryColor,
                  child: FittedBox(
                    child: Text(
                      label ?? '',
                      textAlign: TextAlign.center,
                      style: textStyle ??
                          TextStyle(fontSize: 10, color: textColor ?? Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
