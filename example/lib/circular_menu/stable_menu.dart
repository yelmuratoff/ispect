import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ispect_example/circular_menu/item.dart';

class CircularMenu extends StatefulWidget {
  final List<CircularMenuItem> items;
  final double radius;
  final Widget? backgroundWidget;
  final Duration animationDuration;
  final Curve curve;
  final Curve reverseCurve;
  final VoidCallback? toggleButtonOnPressed;
  final Color? toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow>? toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color? toggleButtonIconColor;
  final AnimatedIconData toggleButtonAnimatedIconData;

  CircularMenu({
    super.key,
    required this.items,
    this.radius = 100,
    this.backgroundWidget,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.bounceOut,
    this.reverseCurve = Curves.fastOutSlowIn,
    this.toggleButtonOnPressed,
    this.toggleButtonColor,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 0,
    this.toggleButtonPadding = 0,
    this.toggleButtonSize = 40,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData = AnimatedIcons.menu_close,
  })  : assert(items.isNotEmpty, 'items can not be empty list'),
        assert(items.length > 1, 'if you have one item no need to use a Menu');

  @override
  CircularMenuState createState() => CircularMenuState();
}

class CircularMenuState extends State<CircularMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _completeAngle = 2 * math.pi;
  double _initialAngle = 0;
  late int _itemsCount;
  late Animation<double> _animation;
  Offset _buttonPosition = const Offset(0, 100);

  void forwardAnimation() {
    _animationController.forward();
  }

  void reverseAnimation() {
    _animationController.reverse();
  }

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
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _snapToEdge(Size screenSize) {
    setState(() {
      if (_buttonPosition.dx > screenSize.width / 2) {
        _buttonPosition = Offset(screenSize.width - widget.toggleButtonSize, _buttonPosition.dy);
      } else {
        _buttonPosition = Offset(0, _buttonPosition.dy);
      }
    });
  }

  List<Widget> _buildMenuItems(Alignment alignment) {
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
                _animation.value * widget.radius),
            child: Transform.scale(
              scale: _animation.value,
              child: Transform.rotate(
                angle: _animation.value * (math.pi * 2),
                child: CircularMenuItemWidget(
                  item: item,
                ),
              ),
            ),
          ),
        ),
      );
    });
    return items;
  }

  Widget _buildMenuButton(BuildContext context) {
    return Positioned(
      left: _buttonPosition.dx,
      top: _buttonPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _buttonPosition += details.delta;
          });
        },
        onPanEnd: (details) {
          _snapToEdge(MediaQuery.of(context).size);
        },
        child: CircularMenuItemWidget(
          item: CircularMenuItem(
            icon: null,
            margin: widget.toggleButtonMargin,
            color: widget.toggleButtonColor ?? Theme.of(context).primaryColor,
            padding: (-_animation.value * widget.toggleButtonPadding * 0.5) + widget.toggleButtonPadding,
            onTap: () {
              _animationController.status == AnimationStatus.dismissed
                  ? (_animationController).forward()
                  : (_animationController).reverse();
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final alignment = _getAlignmentFromOffset(_buttonPosition, screenSize);
    log('alignment: $alignment');
    _configureAlignmentBasedAngles(alignment);

    return Stack(
      children: <Widget>[
        widget.backgroundWidget ?? Container(),
        ..._buildMenuItems(alignment),
        _buildMenuButton(context),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
