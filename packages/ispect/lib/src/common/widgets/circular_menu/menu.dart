// ignore_for_file: avoid_empty_blocks, prefer_int_literals
import 'dart:async';
import 'dart:developer' as developer;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ispect/src/common/widgets/circular_menu/drag_handle_painter.dart';
import 'package:ispect/src/common/widgets/circular_menu/item.dart';
import 'package:ispect/src/features/inspector/src/widgets/multi_value_listenable.dart';

enum VisibleState {
  active,
  inactive,
  hidden,
}

class DraggableCircularMenu extends StatefulWidget {
  const DraggableCircularMenu({
    required this.items,
    required this.toggleButtonColor,
    this.alignment = Alignment.bottomCenter,
    this.radius = 100,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.bounceOut,
    this.reverseCurve = Curves.fastOutSlowIn,
    this.toggleButtonOnPressed,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 10,
    this.toggleButtonPadding = 10,
    this.toggleButtonSize = 30,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData = AnimatedIcons.menu_close,
    this.menuKey,
    this.startingAngleInRadian,
    this.endingAngleInRadian,
    this.alignAnimationDuration = Duration.zero,
    this.isDraggable = false,
    this.stepSize = (x: 0.1, y: 0.1),
  }) : super(key: menuKey);

  /// use global key to control animation anywhere in the code
  final GlobalKey<DraggableCircularMenuState>? menuKey;

  /// list of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// menu alignment
  final Alignment alignment;

  /// menu radius
  final double radius;

  /// animation duration
  final Duration animationDuration;
  final Duration alignAnimationDuration;

  /// animation curve in forward
  final Curve curve;

  /// animation curve in reverse
  final Curve reverseCurve;

  /// callback
  final VoidCallback? toggleButtonOnPressed;
  final Color toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow>? toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color? toggleButtonIconColor;
  final AnimatedIconData toggleButtonAnimatedIconData;

  /// starting angle in clockwise radian
  final double? startingAngleInRadian;

  /// ending angle in clockwise radian

  final double? endingAngleInRadian;

  /// should the menu be draggable
  final bool isDraggable;

  /// step size for dragging
  final ({double x, double y}) stepSize;

  @override
  DraggableCircularMenuState createState() => DraggableCircularMenuState();
}

class DraggableCircularMenuState extends State<DraggableCircularMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late int _itemsCount;
  late Animation<double> _animation;

  Timer? _hideTimer;
  Timer? _fullHideTimer;

  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  final ValueNotifier<Offset> _buttonPosition =
      ValueNotifier<Offset>(const Offset(0, 100));
  final ValueNotifier<double> _completeAngle =
      ValueNotifier<double>(2 * math.pi);
  final ValueNotifier<double> _initialAngle = ValueNotifier<double>(0);
  final ValueNotifier<bool> _startDragFromLeft = ValueNotifier<bool>(false);
  final ValueNotifier<VisibleState> _visibleState =
      ValueNotifier<VisibleState>(VisibleState.hidden);

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      ),
    );
    _itemsCount = widget.items.length;
    _startHideTimers(context);
  }

  @override
  void dispose() {
    _isDragging.dispose();
    _buttonPosition.dispose();
    _completeAngle.dispose();
    _initialAngle.dispose();
    _startDragFromLeft.dispose();
    _visibleState.dispose();

    _animationController.dispose();
    _hideTimer?.cancel();
    _fullHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: () {
        if (_animationController.isCompleted) {
          _closeMenu(context);
        }
      },
      child: Stack(
        key: widget.menuKey,
        children: <Widget>[
          MultiValueListenableBuilder(
            valueListenables: [
              _animationController,
              _animation,
              _initialAngle,
              _completeAngle,
              _buttonPosition,
              _visibleState,
              _isDragging,
              _startDragFromLeft,
            ],
            builder: (_) => TapRegion(
              onTapOutside: (_) {
                developer.log('ISpect: onTapOutside');
                if (_animationController.status == AnimationStatus.dismissed) {
                  _visibleState.value = VisibleState.hidden;
                } else if (_animationController.status ==
                    AnimationStatus.completed) {
                  _closeMenu(context);
                }
                _startHideTimers(context);
              },
              child: Stack(
                children: [
                  ..._buildMenuItems(
                    screenSize: screenSize,
                  ),
                  MultiValueListenableBuilder(
                    valueListenables: [
                      _animationController,
                      _animation,
                      _buttonPosition,
                      _visibleState,
                      _isDragging,
                      _startDragFromLeft,
                    ],
                    builder: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final alignment = _getAlignmentFromOffset(
                          _buttonPosition.value,
                          screenSize,
                        );
                        _configureAlignmentBasedAngles(alignment);
                      });
                      return Positioned(
                        left: _isInLeftSide(screenSize)
                            ? _buttonPosition.value.dx
                            : null,
                        right: !_isInLeftSide(screenSize)
                            ? screenSize.width -
                                _buttonPosition.value.dx -
                                widget.toggleButtonSize * 2
                            : null,
                        top: _buttonPosition.value.dy,
                        child: GestureDetector(
                          onPanStart: (details) {
                            if (details.globalPosition.dx < 80) {
                              _startDragFromLeft.value = true;
                            } else if (details.globalPosition.dx >
                                screenSize.width - 80) {
                              _startDragFromLeft.value = false;
                            }
                          },
                          onPanUpdate: (details) {
                            if (_visibleState.value == VisibleState.active ||
                                _visibleState.value == VisibleState.inactive) {
                              _dragButton(details, screenSize);
                              // developer.log(
                              //   'Dragged: ${details.globalPosition.dx}\nIsInLeftSide: ${_isInLeftSide(screenSize)}\nStartDragFromLeft: ${_startDragFromLeft.value}',
                              // );
                            } else {
                              _visibleState.value = VisibleState.active;
                            }
                          },
                          onPanEnd: (_) {
                            if (_visibleState.value == VisibleState.active ||
                                _visibleState.value == VisibleState.inactive) {
                              _snapButton(screenSize);
                              _startHideTimers(context);
                            }
                            setState(() {
                              developer.log('ISpect: button rebuilded');
                            });
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: GestureDetector(
                              onTap: () {
                                _closeMenu(
                                  context,
                                  shouldReset: false,
                                );
                                if (widget.toggleButtonOnPressed != null) {
                                  widget.toggleButtonOnPressed?.call();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.zero,
                                width:
                                    _visibleState.value == VisibleState.hidden
                                        ? 30
                                        : widget.toggleButtonSize * 1.5,
                                height: 70,
                                decoration: BoxDecoration(
                                  color:
                                      _visibleState.value == VisibleState.hidden
                                          ? widget.toggleButtonColor
                                              .withValues(alpha: 0.3)
                                          : widget.toggleButtonColor,
                                  borderRadius: BorderRadius.only(
                                    topRight: _isInLeftSide(screenSize) ||
                                            _isDragging.value
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    bottomRight: _isInLeftSide(screenSize) ||
                                            _isDragging.value
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    topLeft: _isInRightSide(screenSize) ||
                                            _isDragging.value
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    bottomLeft: _isInRightSide(screenSize) ||
                                            _isDragging.value
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                  ),
                                ),
                                child: _visibleState.value ==
                                        VisibleState.hidden
                                    ? _isDragging.value
                                        ? const SizedBox()
                                        : Center(
                                            child: CustomPaint(
                                              willChange: true,
                                              size: const Size(20, 70),
                                              painter: LineWithCurvePainter(
                                                isInRightSide:
                                                    _isInRightSide(screenSize),
                                                color: widget
                                                        .toggleButtonIconColor ??
                                                    Colors.white,
                                              ),
                                            ),
                                          )
                                    : Center(
                                        child: AnimatedIcon(
                                          icon: widget
                                              .toggleButtonAnimatedIconData,
                                          size: widget.toggleButtonSize,
                                          color: widget.toggleButtonIconColor ??
                                              Colors.white,
                                          progress: _animation,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dragButton(DragUpdateDetails details, Size screenSize) {
    _buttonPosition.value += details.delta;
    _isDragging.value = true;
    _buttonPosition.value = Offset(
      _buttonPosition.value.dx
          .clamp(0.0, screenSize.width - widget.toggleButtonSize * 2),
      _buttonPosition.value.dy.clamp(50, screenSize.height - 100),
    );
  }

  List<Widget> _buildMenuItems({
    required Size screenSize,
  }) {
    final items = <Widget>[];

    widget.items.asMap().forEach((index, item) {
      items.add(
        AnimatedBuilder(
          animation: Listenable.merge([
            _animationController,
            _animation,
            _initialAngle,
            _completeAngle,
            _buttonPosition,
            _visibleState,
            _isDragging,
            _startDragFromLeft,
          ]),
          builder: (_, __) => Positioned(
            left: _isInLeftSide(screenSize) ? _buttonPosition.value.dx : null,
            right: !_isInLeftSide(screenSize)
                ? screenSize.width -
                    _buttonPosition.value.dx -
                    widget.toggleButtonSize * 2
                : null,
            top: _buttonPosition.value.dy,
            child: Transform.translate(
              offset: Offset.fromDirection(
                _completeAngle.value == (2 * math.pi)
                    ? (_initialAngle.value +
                        (_completeAngle.value / _itemsCount) * index)
                    : (_initialAngle.value +
                        (_completeAngle.value / (_itemsCount - 1)) * index),
                _animation.value * widget.radius,
              ),
              child: Transform.scale(
                scale: _animation.value,
                child: Transform.rotate(
                  angle: _animation.value * (math.pi * 2),
                  child: CircularMenuItemWidget(
                    item: item,
                    closeMenu: () {
                      _closeMenu(context);
                    },
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

  void _snapButton(Size screenSize) {
    if (_buttonPosition.value.dx > _halfScreenWidth(screenSize)) {
      _buttonPosition.value = Offset(
        screenSize.width - widget.toggleButtonSize * 2,
        _buttonPosition.value.dy,
      );
    } else {
      _buttonPosition.value = Offset(0, _buttonPosition.value.dy);
    }
    _isDragging.value = false;
  }

  double _halfScreenWidth(Size screenSize) =>
      screenSize.width / 2 - widget.toggleButtonSize / 2;

  bool _isInLeftSide(Size screenSize) =>
      _buttonPosition.value.dx < _halfScreenWidth(screenSize);

  bool _isInRightSide(Size screenSize) =>
      _buttonPosition.value.dx > _halfScreenWidth(screenSize);

  void _closeMenu(
    BuildContext context, {
    bool shouldReset = true,
  }) {
    if (_animationController.status == AnimationStatus.dismissed) {
      _animationController.forward();
      _visibleState.value = VisibleState.inactive;
      if (shouldReset) {
        _resetHideTimers(context);
      }
    } else {
      _animationController.reverse();
    }
  }

  void _startHideTimers(BuildContext context) {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (_animationController.status == AnimationStatus.completed &&
          !_isDragging.value) {
        _closeMenu(context);
      }
    });
    _fullHideTimer = Timer(const Duration(seconds: 6), () {
      if (_animationController.status == AnimationStatus.dismissed &&
          !_isDragging.value) {
        _visibleState.value = VisibleState.hidden;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!context.mounted) return;
          _snapButton(MediaQuery.sizeOf(context));
        });
      }
    });
  }

  void _resetHideTimers(BuildContext context) {
    _hideTimer?.cancel();
    _fullHideTimer?.cancel();
    _visibleState.value = VisibleState.inactive;

    _startHideTimers(context);
  }

  Alignment _getAlignmentFromOffset(Offset offset, Size containerSize) {
    final normalizedX = (offset.dx / containerSize.width) * 2 - 1;
    final normalizedY = (offset.dy / containerSize.height) * 2 - 1;

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
        _completeAngle.value = 1 * math.pi;
        _initialAngle.value = 1 * math.pi;
      case Alignment.topCenter:
        _completeAngle.value = 1 * math.pi;
        _initialAngle.value = 0 * math.pi;
      case Alignment.centerLeft:
        _completeAngle.value = 1 * math.pi;
        _initialAngle.value = 1.5 * math.pi;
      case Alignment.centerRight:
        _completeAngle.value = 1 * math.pi;
        _initialAngle.value = 0.5 * math.pi;
      case Alignment.center:
        _completeAngle.value = 2 * math.pi;
        _initialAngle.value = 0 * math.pi;
      case Alignment.bottomRight:
        _completeAngle.value = 0.5 * math.pi;
        _initialAngle.value = 1 * math.pi;
      case Alignment.bottomLeft:
        _completeAngle.value = 0.5 * math.pi;
        _initialAngle.value = 1.5 * math.pi;
      case Alignment.topLeft:
        _completeAngle.value = 0.5 * math.pi;
        _initialAngle.value = 0 * math.pi;
      case Alignment.topRight:
        _completeAngle.value = 0.5 * math.pi;
        _initialAngle.value = 0.5 * math.pi;
    }
  }
}
