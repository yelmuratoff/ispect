// ignore_for_file: avoid_empty_blocks, prefer_int_literals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/circular_menu/drag_handle_painter.dart';
import 'package:ispect/src/common/widgets/circular_menu/item.dart';
import 'package:ispect/src/features/inspector/src/widgets/multi_value_listenable.dart';

enum VisibleState {
  active,
  inactive,
  hidden;

  T mapOrNull<T>(T Function(VisibleState state) f) {
    switch (this) {
      case VisibleState.active:
        return f(VisibleState.active);
      case VisibleState.inactive:
        return f(VisibleState.inactive);
      case VisibleState.hidden:
        return f(VisibleState.hidden);
    }
  }

  void when({
    required VoidCallback onActive,
    required VoidCallback onInactive,
    required VoidCallback onHidden,
  }) {
    switch (this) {
      case VisibleState.active:
        onActive();
      case VisibleState.inactive:
        onInactive();
      case VisibleState.hidden:
        onHidden();
    }
  }

  T map<T>({
    required T Function() onActive,
    required T Function() onInactive,
    required T Function() onHidden,
  }) {
    switch (this) {
      case VisibleState.active:
        return onActive();
      case VisibleState.inactive:
        return onInactive();
      case VisibleState.hidden:
        return onHidden();
    }
  }
}

class DraggableMenuPanel extends StatefulWidget {
  const DraggableMenuPanel({
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
  final GlobalKey<DraggableMenuPanelState>? menuKey;

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
  DraggableMenuPanelState createState() => DraggableMenuPanelState();
}

class DraggableMenuPanelState extends State<DraggableMenuPanel> with SingleTickerProviderStateMixin {
  Timer? _hideTimer;
  Timer? _fullHideTimer;

  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  final ValueNotifier<Offset> _buttonPosition = ValueNotifier<Offset>(const Offset(0, 100));

  final ValueNotifier<bool> _startDragFromLeft = ValueNotifier<bool>(false);
  final ValueNotifier<VisibleState> _visibleState = ValueNotifier<VisibleState>(VisibleState.hidden);

  @override
  void initState() {
    super.initState();

    _startHideTimers();
  }

  @override
  void dispose() {
    _isDragging.dispose();
    _buttonPosition.dispose();

    _startDragFromLeft.dispose();
    _visibleState.dispose();

    _hideTimer?.cancel();
    _fullHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: () {
        if (_visibleState.value == VisibleState.active) {
          _toggleMenu();
        }
      },
      child: Stack(
        key: widget.menuKey,
        children: <Widget>[
          MultiValueListenableBuilder(
            valueListenables: [
              _buttonPosition,
              _visibleState,
              _isDragging,
              _startDragFromLeft,
            ],
            builder: (_) => TapRegion(
              onTapOutside: (_) {
                if (_visibleState.value == VisibleState.inactive) {
                  _visibleState.value = VisibleState.hidden;
                } else if (_visibleState.value == VisibleState.active) {
                  _toggleMenu();
                }
                _resetHideTimers();
              },
              child: Stack(
                children: [
                  MultiValueListenableBuilder(
                    valueListenables: [
                      _buttonPosition,
                      _visibleState,
                      _isDragging,
                      _startDragFromLeft,
                    ],
                    builder: (_) => AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      // left: _buttonPosition.value.dx,
                      left: _isInLeftSide(screenSize) ? _buttonPosition.value.dx : null,
                      right: !_isInLeftSide(screenSize)
                          ? screenSize.width - _buttonPosition.value.dx - widget.toggleButtonSize * 2
                          : null,
                      top: _buttonPosition.value.dy,
                      child: GestureDetector(
                        onPanStart: (details) {
                          if (details.globalPosition.dx < 80) {
                            _startDragFromLeft.value = true;
                          } else if (details.globalPosition.dx > screenSize.width - 80) {
                            _startDragFromLeft.value = false;
                          }
                        },
                        onPanUpdate: (details) {
                          if (_visibleState.value == VisibleState.active ||
                              _visibleState.value == VisibleState.inactive) {
                            _dragButton(details, screenSize);
                          } else {
                            _visibleState.value = VisibleState.inactive;
                          }
                        },
                        onPanEnd: (_) {
                          if (_visibleState.value == VisibleState.active ||
                              _visibleState.value == VisibleState.inactive) {
                            _snapButton(screenSize);
                            _resetHideTimers();
                          }
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onTap: () {
                              _toggleMenu(
                                shouldReset: false,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.zero,
                              width: _visibleState.value.map(
                                onActive: () => widget.toggleButtonSize * 8,
                                onInactive: () => widget.toggleButtonSize * 2,
                                onHidden: () => widget.toggleButtonSize,
                              ),
                              height: _visibleState.value.map(
                                onActive: () => _calculateRowCount(widget.items.length) * 60 + 80,
                                onInactive: () => 70,
                                onHidden: () => 70,
                              ),
                              decoration: BoxDecoration(
                                color: _visibleState.value == VisibleState.hidden
                                    ? widget.toggleButtonColor.withOpacity(0.3)
                                    : widget.toggleButtonColor,
                                borderRadius: BorderRadius.only(
                                  topRight: _isInLeftSide(screenSize) || _isDragging.value
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomRight: _isInLeftSide(screenSize) || _isDragging.value
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  topLeft: _isInRightSide(screenSize) || _isDragging.value
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomLeft: _isInRightSide(screenSize) || _isDragging.value
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                ),
                              ),
                              child: _visibleState.value.map(
                                onActive: () => Center(
                                  child: SingleChildScrollView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          runAlignment: WrapAlignment.center,
                                          spacing: 4,
                                          runSpacing: 8,
                                          children: widget.items
                                              .map(
                                                (item) => CircularMenuItemWidget(
                                                  item: item,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        const Gap(12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: MaterialButton(
                                              onPressed: _toggleMenu,
                                              color: widget.items.first.color,
                                              highlightElevation: 0,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                              ),
                                              elevation: 0,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Text(
                                                  context.ispectL10n.hidePanel,
                                                  style: TextStyle(
                                                    color: widget.toggleButtonIconColor ?? Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                onInactive: () => Center(
                                  child: Icon(
                                    Icons.menu,
                                    color: widget.toggleButtonIconColor ?? Colors.white,
                                  ),
                                ),
                                onHidden: () => Center(
                                  child: CustomPaint(
                                    willChange: true,
                                    size: const Size(20, 70),
                                    painter: LineWithCurvePainter(
                                      isInRightSide: _isInRightSide(screenSize),
                                      color: widget.toggleButtonIconColor ?? Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
      _buttonPosition.value.dx.clamp(0.0, screenSize.width - widget.toggleButtonSize * 2),
      _buttonPosition.value.dy.clamp(50, screenSize.height - 100),
    );
  }

  void _snapButton(Size screenSize) {
    if (_buttonPosition.value.dx > _halfScreenWidth(screenSize)) {
      _buttonPosition.value = Offset(screenSize.width - widget.toggleButtonSize * 2, _buttonPosition.value.dy);
    } else {
      _buttonPosition.value = Offset(0, _buttonPosition.value.dy);
    }
    _isDragging.value = false;
  }

  double _halfScreenWidth(Size screenSize) => screenSize.width / 2 - widget.toggleButtonSize / 2;

  bool _isInLeftSide(Size screenSize) => _buttonPosition.value.dx < _halfScreenWidth(screenSize);

  bool _isInRightSide(Size screenSize) => _buttonPosition.value.dx > _halfScreenWidth(screenSize);

  void _toggleMenu({
    bool shouldReset = true,
  }) {
    _visibleState.value.when(
      onActive: () {
        _visibleState.value = VisibleState.inactive;
      },
      onInactive: () {
        _visibleState.value = VisibleState.active;
      },
      onHidden: () {
        _visibleState.value = VisibleState.active;
        if (shouldReset) {
          _resetHideTimers();
        }
      },
    );
  }

  void _startHideTimers() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (_visibleState.value == VisibleState.active && !_isDragging.value) {
        _toggleMenu();
      }
    });
    _fullHideTimer = Timer(const Duration(seconds: 6), () {
      if (_visibleState.value == VisibleState.inactive && !_isDragging.value) {
        _visibleState.value = VisibleState.hidden;

        Future.delayed(const Duration(milliseconds: 200), () {
          _snapButton(MediaQuery.sizeOf(context));
        });
      }
    });
  }

  void _resetHideTimers() {
    _hideTimer?.cancel();
    _fullHideTimer?.cancel();

    _startHideTimers();
  }

  int _calculateRowCount(int itemCount) {
    final result = (itemCount / 4).ceil();
    return result;
  }
}
