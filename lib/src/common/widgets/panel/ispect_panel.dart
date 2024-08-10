// ignore_for_file: inference_failure_on_function_return_type, prefer_int_literals, unnecessary_parenthesis, prefer_underscore_for_unused_callback_parameters, unnecessary_lambdas

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/circular_menu/drag_handle_painter.dart';

enum PanelShape {
  rectangle,
  rounded,
}

enum DockType {
  inside,
  outside,
}

enum PanelState {
  open,
  closed,
}

class FloatingMenuPanel extends StatefulWidget {
  const FloatingMenuPanel({
    required this.onPressed,
    this.buttons = const [],
    this.positionTop,
    this.positionLeft,
    this.borderColor,
    this.borderWidth,
    this.iconSize,
    this.panelIcon,
    this.buttonWidth = 35,
    this.buttonHeight = 70.0,
    this.borderRadius,
    this.panelState,
    this.panelOpenOffset,
    this.panelAnimDuration,
    this.panelAnimCurve,
    this.backgroundColor,
    this.contentColor,
    this.panelShape,
    this.dockType,
    this.dockOffset = 10.0,
    this.dockAnimCurve,
    this.dockAnimDuration,
  });

  final double? positionTop;
  final double? positionLeft;
  final Color? borderColor;
  final double? borderWidth;
  final double buttonWidth;
  final double buttonHeight;
  final double? iconSize;
  final IconData? panelIcon;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? contentColor;
  final PanelShape? panelShape;
  final PanelState? panelState;
  final double? panelOpenOffset;
  final int? panelAnimDuration;
  final Curve? panelAnimCurve;
  final DockType? dockType;
  final double dockOffset;
  final int? dockAnimDuration;
  final Curve? dockAnimCurve;
  final List<IconData> buttons;
  final Function(int index) onPressed;

  @override
  _FloatBoxState createState() => _FloatBoxState();
}

class _FloatBoxState extends State<FloatingMenuPanel> {
  // Required to set the default state to closed when the widget gets initialized;
  PanelState _panelState = PanelState.closed;

  // Default positions for the panel;
  double _positionTop = 0.0;
  double _positionLeft = 0.0;

  // ** PanOffset ** is used to calculate the distance from the edge of the panel
  // to the cursor, to calculate the position when being dragged;
  double _panOffsetTop = 0.0;
  double _panOffsetLeft = 0.0;

  // This is the animation duration for the panel movement, it's required to
  // dynamically change the speed depending on what the panel is being used for.
  // e.g: When panel opened or closed, the position should change in a different
  // speed than when the panel is being dragged;
  int _movementSpeed = 0;

  bool _isDragging = false;

  late double _buttonWidth;

  @override
  void initState() {
    super.initState();
    _positionTop = widget.positionTop ?? 0;
    _positionLeft = widget.positionLeft ?? 0;
    _buttonWidth = widget.buttonWidth;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceDock(MediaQuery.sizeOf(context).width);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Width and height of page is required for the dragging the panel;
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageHeight = MediaQuery.sizeOf(context).height;

    // Animated positioned widget can be moved to any part of the screen with
    // animation;
    return AnimatedPositioned(
      duration: Duration(
        milliseconds: _movementSpeed,
      ),
      top: _positionTop,
      left: _positionLeft,
      curve: widget.dockAnimCurve ?? Curves.fastLinearToSlowEaseIn,
      child: TapRegion(
        onTapInside: (event) {
          debugPrint('onTapInside');
        },
        onTapOutside: (event) {
          setState(() {
            _panelState = PanelState.closed;

            _buttonWidth = widget.buttonWidth;

            // Reset panel position, dock it to nearest edge;
            _forceDock(pageWidth);
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: widget.panelAnimDuration ?? 300),
          width: _buttonWidth,
          height: _panelHeight,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? context.ispectTheme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: _borderRadius,
            border: _panelBorder,
          ),
          curve: widget.panelAnimCurve ?? Curves.fastLinearToSlowEaseIn,
          child: Wrap(
            children: [
              // Gesture detector is required to detect the tap and drag on the panel;
              GestureDetector(
                onPanEnd: (event) {
                  setState(
                    () {
                      _isDragging = false;
                      _forceDock(pageWidth);
                    },
                  );
                },
                onPanStart: (event) {
                  // Detect the offset between the top and left side of the panel and
                  // x and y position of the touch(click) event;
                  _panOffsetTop = event.globalPosition.dy - _positionTop;
                  _panOffsetLeft = event.globalPosition.dx - _positionLeft;
                },
                onPanUpdate: (event) {
                  setState(
                    () {
                      // Close Panel if opened;
                      _panelState = PanelState.closed;

                      // Reset Movement Speed;
                      _movementSpeed = 0;
                      _isDragging = true;

                      // Calculate the top position of the panel according to pan;
                      _positionTop = event.globalPosition.dy - _panOffsetTop;

                      // Check if the top position is exceeding the dock boundaries;
                      if (_positionTop < 0 + _dockBoundary) {
                        _positionTop = 0 + _dockBoundary;
                      }
                      if (_positionTop > (pageHeight - _panelHeight) - _dockBoundary) {
                        _positionTop = (pageHeight - _panelHeight) - _dockBoundary;
                      }

                      // Calculate the Left position of the panel according to pan;
                      _positionLeft = event.globalPosition.dx - _panOffsetLeft;

                      // Check if the left position is exceeding the dock boundaries;
                      if (_positionLeft < 0 + _dockBoundary) {
                        _positionLeft = 0 + _dockBoundary;
                      }
                      if (_positionLeft > (pageWidth - _buttonWidth) - _dockBoundary) {
                        _positionLeft = (pageWidth - _buttonWidth) - _dockBoundary;
                      }
                    },
                  );
                },
                onTap: () {
                  setState(
                    () {
                      _toggleButton(pageWidth, pageHeight);
                    },
                  );
                },
                child: _panelState == PanelState.open
                    ? Container(
                        width: _buttonWidth,
                        height: widget.buttonHeight,
                        color: Colors.white.withOpacity(0.0),
                        child: _FloatButton(
                          size: widget.buttonHeight,
                          icon: widget.panelIcon ?? Icons.settings,
                          color: widget.contentColor ?? Colors.white,
                          iconSize: widget.iconSize ?? 36.0,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isDragging
                            ? Center(
                                child: SizedBox(
                                  width: _buttonWidth,
                                  height: widget.buttonHeight,
                                  child: const Icon(
                                    Icons.drag_indicator_rounded,
                                  ),
                                ),
                              )
                            : SizedBox(
                                key: const ValueKey('drag_handle'),
                                width: _buttonWidth,
                                height: widget.buttonHeight,
                                child: Align(
                                  alignment:
                                      _positionLeft > pageWidth / 2 ? Alignment.centerLeft : Alignment.centerRight,
                                  child: CustomPaint(
                                    willChange: true,
                                    size: const Size(20, 65),
                                    painter: LineWithCurvePainter(
                                      isInRightSide: _positionLeft > pageWidth / 2,
                                    ),
                                  ),
                                ),
                              ),
                      ),
              ),

              AnimatedOpacity(
                opacity: _panelState == PanelState.open ? 1.0 : 0.0,
                duration: _panelState == PanelState.open
                    ? const Duration(milliseconds: 250)
                    : const Duration(milliseconds: 10),
                child: Column(
                  children: List.generate(
                    widget.buttons.length,
                    (index) => GestureDetector(
                      onTap: () {
                        widget.onPressed(index);
                        setState(() {
                          _movementSpeed = widget.panelAnimDuration ?? 100;

                          if (_panelState == PanelState.open) {
                            // If panel state is "open", set it to "closed";
                            _panelState = PanelState.closed;

                            // Reset panel position, dock it to nearest edge;
                            _forceDock(pageWidth);
                            //widget.isOpen(false);
                            ////print("Float panel closed.");
                          } else {
                            // If panel state is "closed", set it to "open";
                            _panelState = PanelState.open;

                            // Set the left side position;
                            _positionLeft = _openDockLeft(pageWidth);
                            // widget.isOpen(true);

                            _calcPanelTop(pageHeight);
                          }
                        });
                      },
                      child: _FloatButton(
                        size: widget.buttonHeight,
                        icon: widget.buttons[index],
                        color: widget.contentColor ?? Colors.white,
                        iconSize: widget.iconSize ?? 24.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleButton(double pageWidth, double pageHeight) {
    // Set the animation speed to custom duration;
    _movementSpeed = widget.panelAnimDuration ?? 200;

    if (_panelState == PanelState.open) {
      // If panel state is "open", set it to "closed";
      _panelState = PanelState.closed;

      _buttonWidth = widget.buttonWidth;

      // Reset panel position, dock it to nearest edge;
      _forceDock(pageWidth);
      //widget.isOpen(false);
      //print("Float panel closed.");
    } else {
      // If panel state is "closed", set it to "open";
      _panelState = PanelState.open;

      _buttonWidth = 75;

      // Set the left side position;
      _positionLeft = _openDockLeft(pageWidth);
      //widget.isOpen(true);

      _calcPanelTop(pageHeight);
    }
  }

  double get _dockBoundary {
    if (widget.dockType != null && widget.dockType == DockType.inside) {
      // If it's an 'inside' type dock, dock offset will remain the same;
      return widget.dockOffset;
    } else {
      // If it's an 'outside' type dock, dock offset will be inverted, hence
      // negative value;
      return -widget.dockOffset;
    }
  }

  // If panel shape is set to rectangle, the border radius will be set to custom
  // border radius property of the WIDGET, else it will be set to the size of
  // widget to make all corners rounded.
  BorderRadius get _borderRadius {
    if (widget.panelShape != null && widget.panelShape == PanelShape.rectangle) {
      // If panel shape is 'rectangle', border radius can be set to custom or 0;
      return widget.borderRadius ?? BorderRadius.zero;
    } else {
      // If panel shape is 'rounded', border radius will be the size of widget
      // to make it rounded;
      return BorderRadius.all(Radius.circular(widget.buttonHeight));
    }
  }

  // Height of the panel according to the panel state;
  double get _panelHeight {
    if (_panelState == PanelState.open) {
      // Panel height will be in multiple of total buttons, I have added "1"
      // digit height for each button to fix the overflow issue. Don't know
      // what's causing this, but adding "1" fixed the problem for now.
      return (widget.buttonHeight + (widget.buttonHeight + 1) * widget.buttons.length) + (widget.borderWidth ?? 0);
    } else {
      return widget.buttonHeight + (widget.borderWidth ?? 0) * 2;
    }
  }

  // Panel top needs to be recalculated while opening the panel, to make sure
  // the height doesn't exceed the bottom of the page;
  void _calcPanelTop(double pageHeight) {
    if (_positionTop + _panelHeight > pageHeight + _dockBoundary) {
      _positionTop = pageHeight - _panelHeight + _dockBoundary;
    }
  }

  // Dock Left position when open;
  double _openDockLeft(double pageWidth) {
    if (_positionLeft < (pageWidth / 2)) {
      // If panel is docked to the left;
      return widget.panelOpenOffset ?? 30.0;
    } else {
      // If panel is docked to the right;
      return ((pageWidth - _buttonWidth)) - (widget.panelOpenOffset ?? 30.0);
    }
  }

  // Panel border is only enabled if the border width is greater than 0;
  Border? get _panelBorder {
    if (widget.borderWidth != null && widget.borderWidth! > 0) {
      return Border.fromBorderSide(
        BorderSide(
          color: widget.borderColor ?? const Color(0xFF333333),
          width: widget.borderWidth ?? 0.0,
        ),
      );
    } else {
      return null;
    }
  }

  // Force dock will dock the panel to it's nearest edge of the screen;
  void _forceDock(double pageWidth) {
    // Calculate the center of the panel;
    final center = _positionLeft + (_buttonWidth / 2);

    // Set movement speed to the custom duration property or '300' default;
    _movementSpeed = widget.dockAnimDuration ?? 300;

    // Check if the position of center of the panel is less than half of the
    // page;
    if (center < pageWidth / 2) {
      // Dock to the left edge;
      _positionLeft = 0.0 + _dockBoundary;
    } else {
      // Dock to the right edge;
      _positionLeft = (pageWidth - _buttonWidth) - _dockBoundary;
    }
  }
}

class _FloatButton extends StatelessWidget {
  const _FloatButton({this.size, this.color, this.icon, this.iconSize});
  final double? size;
  final Color? color;
  final IconData? icon;
  final double? iconSize;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white.withOpacity(0.0),
        width: size ?? 70.0,
        height: size ?? 70.0,
        child: Icon(
          icon ?? Icons.settings,
          color: color ?? Colors.white,
          size: iconSize ?? 24.0,
        ),
      );
}
