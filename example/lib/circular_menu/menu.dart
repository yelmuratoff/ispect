import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ispect_example/circular_menu/item.dart';

class DraggableCircularMenu extends StatefulWidget {
  /// use global key to control animation anywhere in the code
  final GlobalKey<DraggableCircularMenuState>? menuKey;

  /// list of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// menu alignment
  final Alignment alignment;

  /// menu radius
  final double radius;

  /// widget holds actual page content
  final Widget child;

  /// animation duration
  final Duration animationDuration;
  final Duration alignAnimationDuration;

  /// animation curve in forward
  final Curve curve;

  /// animation curve in rverse
  final Curve reverseCurve;

  /// callback
  final VoidCallback? toggleButtonOnPressed;
  final Color? toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow>? toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color? toggleButtonIconColor;
  final AnimatedIconData toggleButtonAnimatedIconData;

  /// staring angle in clockwise radian
  final double? startingAngleInRadian;

  /// ending angle in clockwise radian
  final double? endingAngleInRadian;

  /// should the menu be draggable
  final bool isDraggable;

  /// step size for dragging
  final ({double x, double y}) stepSize;

  /// creates a circular menu with specific [radius] and [alignment] .
  /// [toggleButtonElevation] ,[toggleButtonPadding] and [toggleButtonMargin] must be
  /// equal or greater than zero.
  /// [items] must not be null and it must contains two elements at least.
  DraggableCircularMenu({
    required this.items,
    this.alignment = Alignment.bottomCenter,
    this.radius = 100,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.bounceOut,
    this.reverseCurve = Curves.fastOutSlowIn,
    this.toggleButtonOnPressed,
    this.toggleButtonColor,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 10,
    this.toggleButtonPadding = 10,
    this.toggleButtonSize = 40,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData = AnimatedIcons.menu_close,
    this.menuKey,
    this.startingAngleInRadian,
    this.endingAngleInRadian,
    this.alignAnimationDuration = Duration.zero,
    this.isDraggable = false,
    this.stepSize = (x: 0.1, y: 0.1),
  })  : assert(items.isNotEmpty, 'items can not be empty list'),
        assert(items.length > 1, 'if you have one item no need to use a Menu'),
        assert(stepSize.x > 0 || stepSize.x < 1, 'stepSize.x must be between 0 and 1'),
        assert(stepSize.y > 0 || stepSize.y < 1, 'stepSize.y must be between 0 and 1'),
        super(key: menuKey);

  @override
  DraggableCircularMenuState createState() => DraggableCircularMenuState();
}

class DraggableCircularMenuState extends State<DraggableCircularMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _completeAngle = 2 * math.pi;
  double _initialAngle = 0;
  late int _itemsCount;
  late Animation<double> _animation;
  Offset _buttonPosition = const Offset(0, 100);

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..addListener(() {
        setState(() {});
      });
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: widget.curve, reverseCurve: widget.reverseCurve),
    );
    _itemsCount = widget.items.length;
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final alignment = _getAlignmentFromOffset(_buttonPosition, screenSize);

    _configureAlignmentBasedAngles(alignment);

    return Stack(
      key: widget.menuKey,
      children: <Widget>[
        widget.child,
        ..._buildMenuItems(
          alignment,
          screenSize: screenSize,
        ),
        _buildMenuButton(
          context,
          screenSize: screenSize,
        ),
        Positioned(
          left: screenSize.width / 2 - widget.toggleButtonSize / 2,
          top: screenSize.height / 2,
          child: Container(
            color: Colors.red.withOpacity(0.5),
            height: widget.toggleButtonSize,
            width: widget.toggleButtonSize,
          ),
        )
      ],
    );
  }

  List<Widget> _buildMenuItems(
    Alignment alignment, {
    required Size screenSize,
  }) {
    List<Widget> items = [];
    widget.items.asMap().forEach((index, item) {
      items.add(
        Positioned(
          left: _buttonPosition.dx,
          top: _buttonPosition.dy,
          child: Transform.translate(
            offset: Offset.fromDirection(
              _completeAngle == (2 * math.pi)
                  ? (_initialAngle + (_completeAngle / (_itemsCount)) * index)
                  : (_initialAngle + (_completeAngle / (_itemsCount - 1)) * index),
              _animation.value * widget.radius,
            ),
            child: Transform.scale(
              scale: _animation.value,
              child: Transform.rotate(
                angle: _animation.value * (math.pi * 2),
                child: CircularMenuItemWidget(
                  item: item,
                  closeMenu: _closeMenu,
                ),
              ),
            ),
          ),
        ),
      );
    });
    return items;
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required Size screenSize,
  }) {
    return Positioned(
      left: _buttonPosition.dx,
      top: _buttonPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _buttonPosition += details.delta;
            _buttonPosition = Offset(
              _buttonPosition.dx.clamp(0.0, screenSize.width - widget.toggleButtonSize / 2),
              _buttonPosition.dy.clamp(50, screenSize.height - 100),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            if (_buttonPosition.dx > (screenSize.width / 2 - widget.toggleButtonSize / 2)) {
              _buttonPosition = Offset(screenSize.width - 80, _buttonPosition.dy);
            } else {
              _buttonPosition = Offset(0, _buttonPosition.dy);
            }
          });
        },
        child: CircularMenuItemWidget(
          item: CircularMenuItem(
            margin: widget.toggleButtonMargin,
            onTap: () {
              _closeMenu();
              if (widget.toggleButtonOnPressed != null) {
                widget.toggleButtonOnPressed!();
              }
            },
            boxShadow: widget.toggleButtonBoxShadow,
            animatedIcon: AnimatedIcon(
              icon: widget.toggleButtonAnimatedIconData,
              size: widget.toggleButtonSize,
              color: widget.toggleButtonIconColor ?? Colors.white,
              progress: _animation,
            ),
            onTapClosesMenu: false,
          ),
        ),
      ),
    );
  }

  void _closeMenu() {
    _animationController.status == AnimationStatus.dismissed
        ? (_animationController).forward()
        : (_animationController).reverse();
  }

  Alignment _getAlignmentFromOffset(Offset offset, Size containerSize) {
    double normalizedX = (offset.dx / containerSize.width) * 2 - 1;
    double normalizedY = (offset.dy / containerSize.height) * 2 - 1;

    if (normalizedX < -0.5 && normalizedY < -0.5) {
      return Alignment.topLeft;
    } else if (normalizedX > 0.5 && normalizedY < -0.5) {
      return Alignment.topRight;
    } else if (normalizedX < -0.5 && normalizedY > 0.5) {
      return Alignment.bottomLeft;
    } else if (normalizedX > 0.5 && normalizedY > 0.5) {
      return Alignment.bottomRight;
    } else if (normalizedX < -0.5) {
      return Alignment.centerLeft;
    } else if (normalizedX > 0.5) {
      return Alignment.centerRight;
    } else if (normalizedY < -0.5) {
      return Alignment.topCenter;
    } else if (normalizedY > 0.5) {
      return Alignment.bottomCenter;
    } else {
      return Alignment.center;
    }
  }

  void _configureAlignmentBasedAngles(Alignment alignment) {
    switch (alignment) {
      case Alignment.bottomCenter:
        _completeAngle = 1 * math.pi;
        _initialAngle = 1 * math.pi;
        break;
      case Alignment.topCenter:
        _completeAngle = 1 * math.pi;
        _initialAngle = 0 * math.pi;
        break;
      case Alignment.centerLeft:
        _completeAngle = 1 * math.pi;
        _initialAngle = 1.5 * math.pi;
        break;
      case Alignment.centerRight:
        _completeAngle = 1 * math.pi;
        _initialAngle = 0.5 * math.pi;
        break;
      case Alignment.center:
        _completeAngle = 2 * math.pi;
        _initialAngle = 0 * math.pi;
        break;
      case Alignment.bottomRight:
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 1 * math.pi;
        break;
      case Alignment.bottomLeft:
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 1.5 * math.pi;
        break;
      case Alignment.topLeft:
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 0 * math.pi;
        break;
      case Alignment.topRight:
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 0.5 * math.pi;
        break;
      default:
        throw 'Alignment not supported';
    }
  }
}
