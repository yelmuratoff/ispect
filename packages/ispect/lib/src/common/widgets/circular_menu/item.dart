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
    this.margin = 0,
    this.enableBadge = false,
    this.badgeBottomOffset,
    this.badgeLeftOffset,
    this.badgeRightOffset,
    this.badgeTopOffset,
    this.badgeRadius = 10,
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

  @override
  Widget build(BuildContext context) => Container(
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
        child: Badge(
          backgroundColor: item.badgeColor,
          smallSize: item.badgeRadius,
          isLabelVisible: item.enableBadge,
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
        ),
      );
}
