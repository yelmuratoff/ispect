import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ispect_example/circular_menu/item.dart';

class CircularMenu extends StatefulWidget {
  /// use global key to control animation anywhere in the code
  final GlobalKey<CircularMenuState>? key;

  /// list of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// menu alignment
  final Alignment alignment;

  /// menu radius
  final double radius;

  /// widget holds actual page content
  final Widget? backgroundWidget;

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
  CircularMenu({
    required this.items,
    this.alignment = Alignment.bottomCenter,
    this.radius = 100,
    this.backgroundWidget,
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
    this.key,
    this.startingAngleInRadian,
    this.endingAngleInRadian,
    this.alignAnimationDuration = Duration.zero,
    this.isDraggable = false,
    this.stepSize = (x: 0.1, y: 0.1),
  })  : assert(items.isNotEmpty, 'items can not be empty list'),
        assert(items.length > 1, 'if you have one item no need to use a Menu'),
        assert(stepSize.x > 0 || stepSize.x < 1, 'stepSize.x must be between 0 and 1'),
        assert(stepSize.y > 0 || stepSize.y < 1, 'stepSize.y must be between 0 and 1'),
        super(key: key);

  @override
  CircularMenuState createState() => CircularMenuState();
}

class CircularMenuState extends State<CircularMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double? _completeAngle;
  late double _initialAngle;
  double? _endAngle;
  double? _startAngle;
  late int _itemsCount;
  late Animation<double> _animation;
  Alignment _temporaryAlignment = Alignment.bottomCenter;
  Alignment _finalAlignment = Alignment.bottomCenter;
  List<double> validXValues = [];
  List<double> validYValues = [];

  /// forward animation
  void forwardAnimation() {
    _animationController.forward();
  }

  /// reverse animation
  void reverseAnimation() {
    _animationController.reverse();
  }

  void _configure() {
    if (widget.startingAngleInRadian != null || widget.endingAngleInRadian != null) {
      if (widget.startingAngleInRadian == null) {
        throw ('startingAngleInRadian can not be null');
      }
      if (widget.endingAngleInRadian == null) {
        throw ('endingAngleInRadian can not be null');
      }

      if (widget.startingAngleInRadian! < 0) {
        throw 'startingAngleInRadian has to be in clockwise radian';
      }
      if (widget.endingAngleInRadian! < 0) {
        throw 'endingAngleInRadian has to be in clockwise radian';
      }
      _startAngle = (widget.startingAngleInRadian! / math.pi) % 2;
      _endAngle = (widget.endingAngleInRadian! / math.pi) % 2;
      if (_endAngle! < _startAngle!) {
        throw 'startingAngleInRadian can not be greater than endingAngleInRadian';
      }
      _completeAngle = _startAngle == _endAngle ? 2 * math.pi : (_endAngle! - _startAngle!) * math.pi;
      _initialAngle = _startAngle! * math.pi;
    } else {
      // alignment center left
      if (_finalAlignment.x == -1 && (_finalAlignment.y >= -0.7) && (_finalAlignment.y <= 0.7)) {
        _completeAngle = 1 * math.pi;
        _initialAngle = 1.5 * math.pi;
        return;
      }

      // alignment center right
      if (_finalAlignment.x == 1 && (_finalAlignment.y >= -0.7) && (_finalAlignment.y <= 0.7)) {
        _completeAngle = 1 * math.pi;
        _initialAngle = 0.5 * math.pi;
        return;
      }

      // alignment center top
      if (_finalAlignment.y <= -0.7 && (_finalAlignment.x >= -0.7) && (_finalAlignment.x <= 0.7)) {
        _completeAngle = 1 * math.pi;
        _initialAngle = 0 * math.pi;
        return;
      }

      // alignment center bottom
      if (_finalAlignment.y >= 0.7 && (_finalAlignment.x >= -0.7) && (_finalAlignment.x <= 0.7)) {
        _completeAngle = 1 * math.pi;
        _initialAngle = 1 * math.pi;
        return;
      }

      // alignment top left
      if (_finalAlignment.x == -1 && _finalAlignment.y < -0.7) {
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 0 * math.pi;
        return;
      }

      // alignment top right
      if (_finalAlignment.x == 1 && _finalAlignment.y < -0.7) {
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 0.5 * math.pi;
        return;
      }

      // alignment bottom left
      if (_finalAlignment.x == -1 && _finalAlignment.y > 0.7) {
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 1.5 * math.pi;
        return;
      }

      // alignment bottom right
      if (_finalAlignment.x == 1 && _finalAlignment.y > 0.7) {
        _completeAngle = 0.5 * math.pi;
        _initialAngle = 1 * math.pi;
        return;
      }

      // alignment center
      _completeAngle = 2 * math.pi;
      _initialAngle = 0 * math.pi;
      return;
    }
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];
    widget.items.asMap().forEach((index, item) {
      items.add(
        Positioned.fill(
          child: AnimatedAlign(
            alignment: _finalAlignment,
            duration: widget.alignAnimationDuration,
            curve: Curves.easeOut,
            child: Transform.translate(
              offset: Offset.fromDirection(
                _completeAngle == (2 * math.pi)
                    ? (_initialAngle + (_completeAngle! / (_itemsCount)) * index)
                    : (_initialAngle + (_completeAngle! / (_itemsCount - 1)) * index),
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
        ),
      );
    });
    return items;
  }

  Widget _buildMenuButton(BuildContext context) {
    return Positioned.fill(
      child: AnimatedAlign(
        alignment: _finalAlignment,
        duration: widget.alignAnimationDuration,
        curve: Curves.easeOut,
        child: CircularMenuItemWidget(
          item: CircularMenuItem(
            icon: null,
            margin: widget.toggleButtonMargin,
            color: widget.toggleButtonColor ?? Theme.of(context).primaryColor,
            padding: (-_animation.value * widget.toggleButtonPadding * 0.5) + widget.toggleButtonPadding,
            onTap: () {
              _closeMenu();
              if (widget.toggleButtonOnPressed != null) {
                widget.toggleButtonOnPressed!();
              }
            },
            boxShadow: widget.toggleButtonBoxShadow,
            animatedIcon: AnimatedIcon(
              icon: widget.toggleButtonAnimatedIconData, //AnimatedIcons.menu_close,
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

  Alignment _roundToNearestValidCoordinate(Alignment alignment) {
    double roundedX = validXValues.reduce((a, b) => (alignment.x - a).abs() < (alignment.x - b).abs() ? a : b);
    double roundedY = validYValues.reduce((a, b) => (alignment.y - a).abs() < (alignment.y - b).abs() ? a : b);
    return Alignment(roundedX, roundedY);
  }

  List<double> _generateList(double start, double end, double step) {
    List<double> result = [];
    for (double i = start; i <= end; i += step) {
      result.add(double.parse((i).toStringAsFixed(1)));
    }
    return result;
  }

  @override
  void initState() {
    validXValues = [..._generateList(-1, 0, widget.stepSize.x), ..._generateList(0, 1, widget.stepSize.x)];
    validYValues = [..._generateList(-1, 0, widget.stepSize.y), ..._generateList(0, 1, widget.stepSize.y)];
    _temporaryAlignment = widget.alignment;
    _finalAlignment = widget.alignment;
    _configure();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..addListener(() {
        setState(() {});
      });
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      ),
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
  void didUpdateWidget(oldWidget) {
    _configure();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Stack _stack = Stack(
      children: <Widget>[
        widget.backgroundWidget ?? Container(),
        ..._buildMenuItems(),
        _buildMenuButton(context),
      ],
    );

    return widget.isDraggable
        ? GestureDetector(
            onPanUpdate: (details) {
              _temporaryAlignment += Alignment(
                details.delta.dx / (MediaQuery.of(context).size.width / 2),
                details.delta.dy / (MediaQuery.of(context).size.height / 2),
              );
              setState(() {
                _finalAlignment = _roundToNearestValidCoordinate(_temporaryAlignment);
                _configure();
              });
            },
            child: _stack,
          )
        : _stack;
  }
}
