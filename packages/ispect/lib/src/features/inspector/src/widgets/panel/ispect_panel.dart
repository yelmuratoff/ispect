// ignore_for_file: inference_failure_on_function_return_type, prefer_int_literals, unnecessary_parenthesis, prefer_underscore_for_unused_callback_parameters, unnecessary_lambdas

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/widgets/circular_menu/drag_handle_painter.dart';
import 'package:ispect/src/features/inspector/src/widgets/multi_value_listenable.dart';
import 'package:ispect/src/features/inspector/src/widgets/panel/panel_item.dart';

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

class ISpectMenuPanel extends StatefulWidget {
  const ISpectMenuPanel({
    required this.backgroundColor,
    this.items = const [],
    this.buttons = const [],
    this.borderColor,
    this.borderWidth,
    this.iconSize,
    this.panelIcon,
    this.buttonWidth = 35,
    this.buttonHeight = 70.0,
    this.borderRadius,
    this.panelState,
    this.panelOpenOffset,
    this.panelAnimDuration = 200,
    this.panelAnimCurve,
    this.contentColor,
    this.panelShape,
    this.dockType,
    this.dockOffset = 10.0,
    this.dockAnimCurve,
    this.dockAnimDuration,
    this.initialPosition,
    this.observer,
    this.onPositionChanged,
  });

  final Color? borderColor;
  final double? borderWidth;
  final double buttonWidth;
  final double buttonHeight;
  final double? iconSize;
  final IconData? panelIcon;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color? contentColor;
  final PanelShape? panelShape;
  final PanelState? panelState;
  final double? panelOpenOffset;
  final int panelAnimDuration;
  final Curve? panelAnimCurve;
  final DockType? dockType;
  final double dockOffset;
  final int? dockAnimDuration;
  final Curve? dockAnimCurve;
  final List<ISpectPanelItem> items;
  final List<ISpectPanelButton> buttons;
  final ({double x, double y})? initialPosition;
  final void Function(double x, double y)? onPositionChanged;
  final NavigatorObserver? observer;

  @override
  _FloatBoxState createState() => _FloatBoxState();
}

class _FloatBoxState extends State<ISpectMenuPanel> {
  // <-- Notifiers -->

// Required to set the default state to closed when the widget gets initialized;
  final ValueNotifier<PanelState> _panelState =
      ValueNotifier(PanelState.closed);

// Default positions for the panel;
  final ValueNotifier<double> _draggablePositionTop = ValueNotifier(0.0);
  final ValueNotifier<double> _draggablePositionLeft = ValueNotifier(0.0);
  final ValueNotifier<double> _panelPositionLeft = ValueNotifier(0.0);

  // ** PanOffset ** is used to calculate the distance from the edge of the panel
  // to the cursor, to calculate the position when being dragged;

  final ValueNotifier<double> _panOffsetTop = ValueNotifier(0.0);
  final ValueNotifier<double> _panOffsetLeft = ValueNotifier(0.0);

  // This is the animation duration for the panel movement, it's required to
  // dynamically change the speed depending on what the panel is being used for.
  // e.g: When panel opened or closed, the position should change in a different
  // speed than when the panel is being dragged;

  final ValueNotifier<int> _movementSpeed = ValueNotifier(0);

  final ValueNotifier<bool> _isDragging = ValueNotifier(false);

  final ValueNotifier<double> _buttonWidth = ValueNotifier(0.0);

  static const double _panelWidth = 200;

  @override
  void initState() {
    super.initState();
    _draggablePositionTop.value = widget.initialPosition?.y ?? 200;
    _draggablePositionLeft.value = widget.initialPosition?.x ?? 0;
    _buttonWidth.value = widget.buttonWidth;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceDock(MediaQuery.sizeOf(context).width);
      _hidePanel(MediaQuery.sizeOf(context).width);
    });
  }

  @override
  void dispose() {
    _panelState.dispose();
    _draggablePositionTop.dispose();
    _draggablePositionLeft.dispose();
    _panOffsetTop.dispose();
    _panOffsetLeft.dispose();
    _movementSpeed.dispose();
    _isDragging.dispose();
    _buttonWidth.dispose();
    _panelPositionLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Width and height of page is required for the dragging the panel;
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageHeight = MediaQuery.sizeOf(context).height;

    return MultiValueListenableBuilder(
      key: const ValueKey('ispect_panel_builder'),
      valueListenables: [
        _panelState,
        _draggablePositionTop,
        _draggablePositionLeft,
        _panelPositionLeft,
        _movementSpeed,
        _isDragging,
        _buttonWidth,
        _panOffsetTop,
        _panOffsetLeft,
      ],
      builder: (context) {
        // Animated positioned widget can be moved to any part of the screen with
        // animation;
        final isInRightSide = _draggablePositionLeft.value > pageWidth / 2;
        return Stack(
          children: [
            AnimatedPositioned(
              key: const ValueKey('ispect_draggable_button'),
              duration: Duration(
                milliseconds: _movementSpeed.value,
              ),
              top: _draggablePositionTop.value,
              left: _draggablePositionLeft.value,
              curve: widget.dockAnimCurve ?? Curves.fastLinearToSlowEaseIn,
              child: AnimatedContainer(
                duration: Duration(milliseconds: widget.panelAnimDuration),
                width: widget.buttonWidth,
                height: widget.buttonHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: _borderRadius,
                  border: _panelBorder,
                ),
                curve: widget.panelAnimCurve ?? Curves.fastLinearToSlowEaseIn,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gesture detector is required to detect the tap and drag on the panel;
                      Flexible(
                        child: GestureDetector(
                          onPanEnd: (event) {
                            _isDragging.value = false;
                            _forceDock(pageWidth);
                            _hidePanel(pageWidth);
                            widget.onPositionChanged?.call(
                              _draggablePositionLeft.value,
                              _draggablePositionTop.value,
                            );
                          },
                          onPanStart: (event) {
                            // Detect the offset between the top and left side of the panel and
                            // x and y position of the touch(click) event;
                            _panOffsetTop.value = event.globalPosition.dy -
                                _draggablePositionTop.value;
                            _panOffsetLeft.value = event.globalPosition.dx -
                                _draggablePositionLeft.value;
                          },
                          onPanUpdate: (event) {
                            // Close Panel if opened;
                            _panelState.value = PanelState.closed;

                            _buttonWidth.value = widget.buttonWidth;

                            // Reset Movement Speed;
                            _movementSpeed.value = 0;
                            _isDragging.value = true;

                            // Calculate the top position of the panel according to pan;
                            final statusBarHeight =
                                MediaQuery.paddingOf(context).top;
                            _draggablePositionTop.value =
                                event.globalPosition.dy - _panOffsetTop.value;

                            // Check if the top position is exceeding the status bar or dock boundaries;
                            if (_draggablePositionTop.value <
                                statusBarHeight + _dockBoundary) {
                              _draggablePositionTop.value =
                                  statusBarHeight + _dockBoundary;
                            }
                            if (_draggablePositionTop.value >
                                (pageHeight - widget.buttonHeight - 10) -
                                    _dockBoundary) {
                              _draggablePositionTop.value =
                                  (pageHeight - widget.buttonHeight - 10) -
                                      _dockBoundary;
                            }

                            // Calculate the Left position of the panel according to pan;
                            _draggablePositionLeft.value =
                                event.globalPosition.dx - _panOffsetLeft.value;

                            // Check if the left position is exceeding the dock boundaries;
                            if (_draggablePositionLeft.value <
                                0 + _dockBoundary) {
                              _draggablePositionLeft.value = 0 + _dockBoundary;
                            }
                            if (_draggablePositionLeft.value >
                                (pageWidth - _buttonWidth.value) -
                                    _dockBoundary) {
                              _draggablePositionLeft.value =
                                  (pageWidth - _buttonWidth.value) -
                                      _dockBoundary;
                            }
                          },
                          onTap: () async {
                            await _toggleMainButton(pageWidth);
                            _togglePanel(pageWidth);
                          },
                          child: _panelState.value == PanelState.open
                              ? const SizedBox()
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                  child: _isDragging.value
                                      ? Center(
                                          child: SizedBox(
                                            width: _buttonWidth.value,
                                            height: widget.buttonHeight,
                                            child: Icon(
                                              Icons.drag_indicator_rounded,
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          key: const ValueKey('drag_handle'),
                                          width: _buttonWidth.value,
                                          height: widget.buttonHeight,
                                          child: Align(
                                            alignment: isInRightSide
                                                ? Alignment.centerLeft
                                                : Alignment.centerRight,
                                            child: CustomPaint(
                                              willChange: true,
                                              size: const Size(20, 65),
                                              painter: LineWithCurvePainter(
                                                isInRightSide: isInRightSide,
                                                color: Colors.white
                                                    .withValues(alpha: 0.5),
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
            ),
            AnimatedPositioned(
              key: const ValueKey('ispect_panel'),
              duration: const Duration(
                milliseconds: 600,
              ),
              top: _panelTopPosition(pageHeight),
              left: _panelPositionLeft.value,
              curve: Curves.linearToEaseOut,
              child: TapRegion(
                onTapOutside: (event) {
                  if (_panelState.value == PanelState.open) {
                    _panelState.value = PanelState.closed;

                    // Reset panel position, dock it to nearest edge;
                    _forceDock(pageWidth);
                    _togglePanel(pageWidth);
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) => Transform.translate(
                    offset: Offset.zero,
                    child: child,
                  ),
                  child: _panelState.value == PanelState.open
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: _panelWidth,
                          height: _panelHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius: _borderRadius,
                            border: _panelBorder,
                          ),
                          curve: Curves.linearToEaseOut,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (true) ...[
                                  Wrap(
                                    runAlignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: List.generate(
                                      widget.items.length,
                                      (index) => Badge(
                                        isLabelVisible:
                                            widget.items[index].enableBadge,
                                        smallSize: 12,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: IconButton.filled(
                                            icon: Icon(
                                              widget.items[index].icon,
                                              color: Colors.white,
                                            ),
                                            padding: EdgeInsets.zero,
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all<
                                                      Color>(
                                                _itemColor,
                                              ),
                                              shape: WidgetStateProperty.all<
                                                  RoundedRectangleBorder>(
                                                const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(16),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onPressed: () {
                                              widget.items[index].onTap
                                                  .call(context);

                                              _panelState.value =
                                                  PanelState.closed;
                                              _forceDock(pageWidth);
                                              _hidePanel(pageWidth);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ColoredBox(
                                    color: Colors.transparent,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ...widget.buttons.map(
                                          (button) => _PanelButton(
                                            itemColor: _itemColor,
                                            icon: button.icon,
                                            label: button.label,
                                            pageWidth: pageWidth,
                                            onTap: () {
                                              button.onTap.call(context);
                                            },
                                          ),
                                        ),
                                        _HidePanel(
                                          itemColor: _itemColor,
                                          positionLeft: _draggablePositionLeft,
                                          panOffsetLeft: _panOffsetLeft,
                                          pageWidth: pageWidth,
                                          onTap: () {
                                            _panelState.value =
                                                PanelState.closed;

                                            // Reset panel position, dock it to nearest edge;
                                            _forceDock(pageWidth);
                                            _togglePanel(pageWidth);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // <-- Functions -->

  double _panelTopPosition(double pageHeight) {
    if (_draggablePositionTop.value < 0) {
      return 0;
    } else if (_draggablePositionTop.value > pageHeight - _panelHeight) {
      return _draggablePositionTop.value - _panelHeight;
    } else {
      return _draggablePositionTop.value + widget.buttonHeight;
    }
  }

  void _hidePanel(double pageWidth) {
    if (_draggablePositionLeft.value > pageWidth / 2) {
      _panelPositionLeft.value = pageWidth + _panelWidth;
    } else {
      _panelPositionLeft.value = -_panelWidth;
    }
  }

  void _togglePanel(double pageWidth) {
    if (_panelState.value == PanelState.open) {
      if (_draggablePositionLeft.value > pageWidth / 2) {
        _panelPositionLeft.value = pageWidth - _panelWidth - widget.buttonWidth;
      } else {
        _panelPositionLeft.value = widget.buttonWidth;
      }
    } else {
      if (_draggablePositionLeft.value > pageWidth / 2) {
        _panelPositionLeft.value = pageWidth;
      } else {
        _panelPositionLeft.value = -_panelWidth;
      }
    }
  }

  Future<void> _toggleMainButton(double pageWidth) async {
    if (_panelState.value == PanelState.open) {
      // If panel state is "open", set it to "closed";
      _panelState.value = PanelState.closed;

      // Reset panel position, dock it to nearest edge;
      _forceDock(pageWidth);
    } else {
      // If panel state is "closed", set it to "open";
      _panelState.value = PanelState.open;

      if (_draggablePositionLeft.value > pageWidth / 2) {
        _draggablePositionLeft.value = pageWidth + _buttonWidth.value;
      } else {
        _draggablePositionLeft.value = -_buttonWidth.value;
      }
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
    if (widget.panelShape != null &&
        widget.panelShape == PanelShape.rectangle) {
      // If panel shape is 'rectangle', border radius can be set to custom or 0;
      return widget.borderRadius ?? BorderRadius.zero;
    } else {
      // If panel shape is 'rounded', border radius will be the size of widget
      // to make it rounded;
      return BorderRadius.all(Radius.circular(widget.buttonHeight));
    }
  }

  // Height of the panel according to the panel state;
  double get _panelHeight =>
      (_calculateRowCount(widget.items.length) * 45) +
      ((widget.buttons.isNotEmpty) ? (50 * (widget.buttons.length + 1)) : 60);

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
    final center = _draggablePositionLeft.value + (_buttonWidth.value / 2);

    // Set movement speed to the custom duration property or '300' default;
    _movementSpeed.value = widget.dockAnimDuration ?? 300;

    _buttonWidth.value = widget.buttonWidth;

    // Check if the position of center of the panel is less than half of the
    // page;
    if (center < pageWidth / 2) {
      // Dock to the left edge;
      _draggablePositionLeft.value = 0.0 + _dockBoundary;
      _panelPositionLeft.value = -_buttonWidth.value;
    } else {
      // Dock to the right edge;
      _draggablePositionLeft.value =
          (pageWidth - _buttonWidth.value) - _dockBoundary;
      _panelPositionLeft.value = pageWidth + _buttonWidth.value;
    }
  }

  Color get _itemColor => !context.isDarkMode
      ? adjustColorBrightness(
          context.ispectTheme.colorScheme.primary,
          0.8,
        )
      : adjustColorBrightness(
          context.ispectTheme.colorScheme.primaryContainer,
          0.9,
        );

  int _calculateRowCount(int itemCount) {
    final result = (itemCount / 4).ceil();
    return result;
  }
}

class _HidePanel extends StatelessWidget {
  const _HidePanel({
    required Color itemColor,
    required ValueNotifier<double> positionLeft,
    required ValueNotifier<double> panOffsetLeft,
    required this.pageWidth,
    required this.onTap,
  })  : _itemColor = itemColor,
        _positionLeft = positionLeft,
        _panOffsetLeft = panOffsetLeft;

  final Color _itemColor;
  final ValueNotifier<double> _positionLeft;
  final ValueNotifier<double> _panOffsetLeft;
  final double pageWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 45,
        ),
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: MaterialButton(
              onPressed: onTap,
              color: _itemColor,
              highlightElevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              elevation: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((_positionLeft.value + _panOffsetLeft.value) <
                        pageWidth / 2) ...[
                      const Flexible(
                        flex: 2,
                        child: Icon(
                          Icons.undo_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Flexible(child: Gap(12)),
                    ],
                    Flexible(
                      flex: 2,
                      child: Text(
                        context.ispectL10n.hidePanel,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if ((_positionLeft.value + _panOffsetLeft.value) >
                        pageWidth / 2) ...[
                      const Flexible(child: Gap(12)),
                      const Flexible(
                        flex: 2,
                        child: Icon(
                          Icons.redo_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required Color itemColor,
    required this.pageWidth,
    required this.onTap,
    required this.icon,
    required this.label,
  }) : _itemColor = itemColor;

  final Color _itemColor;
  final double pageWidth;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 45,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 4,
            left: 8,
            right: 8,
          ),
          child: MaterialButton(
            onPressed: onTap,
            color: _itemColor,
            highlightElevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Flexible(child: Gap(12)),
                Flexible(
                  flex: 6,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
