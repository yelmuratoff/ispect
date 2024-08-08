library wormy_effect_button;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WormyEffectButton extends StatefulWidget {
  /// the underlying widgets that will be animated
  final List<Widget> children;

  /// the initial offset of the button
  final Offset initialOffset;

  /// the onPressed function
  final Function onPressed;

  /// the delay between the movement of the underlying widgets
  final int motionDelay;

  /// the way that the widgets animates`
  final Curve curve;

  /// indicates whether the button will return back to its initial offset or not
  final bool holdPosition;

  /// hide the underlying widgets in the static condition
  final bool hideUnderlying;

  // ignore: use_key_in_widget_constructors
  const WormyEffectButton({
    Key? key,
    this.initialOffset = const Offset(340, 610),
    this.motionDelay = 200,
    this.curve = Curves.fastLinearToSlowEaseIn,
    this.holdPosition = false,
    this.hideUnderlying = false,
    required this.children,
    required this.onPressed,
  });

  @override
  State<StatefulWidget> createState() => _WormyEffectButtonState();
}

class _WormyEffectButtonState extends State<WormyEffectButton> {
  bool _isDragging = false;
  late Offset _offset;
  late Offset _minOffset;
  late Offset _maxOffset;
  bool hide = true;

  /// set the initial offset of the button
  @override
  void initState() {
    /// Set initial offset
    super.initState();
    _offset = widget.initialOffset;
    WidgetsBinding.instance?.addPostFrameCallback(_setBoundary);
  }

  /// set the boundaries of dragging the button
  void _setBoundary(_) {
    try {
      setState(() {
        var padding = MediaQuery.of(context).viewPadding;
        _minOffset = Offset(padding.left, padding.top + kToolbarHeight);
        _maxOffset = Offset(MediaQuery.of(context).size.width * 0.9 - padding.right,
            MediaQuery.of(context).size.height - padding.bottom - kToolbarHeight);
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  /// Update the button position
  void _updatePosition(
    PointerEvent pointerMoveEvent,
  ) {
    setState(() {
      hide = false;
    });
    var newOffsetX = _offset.dx + pointerMoveEvent.delta.dx;
    var newOffsetY = _offset.dy + pointerMoveEvent.delta.dy;

    /// ensure position within the limits
    if (newOffsetX < _minOffset.dx) {
      newOffsetX = _minOffset.dx;
    } else if (newOffsetX > _maxOffset.dx) {
      newOffsetX = _maxOffset.dx;
    }
    if (newOffsetY < _minOffset.dy) {
      newOffsetY = _minOffset.dy;
    } else if (newOffsetY > _maxOffset.dy) {
      newOffsetY = _maxOffset.dy;
    }

    /// update position
    setState(() {
      _offset = Offset(newOffsetX, newOffsetY);
    });
  }

  List<Widget> getAnimatedPositionedWidgets() {
    final children = <Widget>[];
    final len = widget.children.length;

    /// to keep the widgets order
    for (var i = len - 1; i >= 0; i--) {
      children.add(
        AnimatedPositioned(
          curve: Curves.linearToEaseOut,
          left: _offset.dx,
          top: _offset.dy,
          onEnd: () {
            setState(() {
              hide = true;
            });
          },
          duration: Duration(milliseconds: (i + 5) * (i + 1) * widget.motionDelay ~/ 4 - i * widget.motionDelay + 50),
          child: Listener(
            onPointerMove: (PointerEvent details) {
              _updatePosition(details);
              setState(() {
                _isDragging = true;
              });
            },
            onPointerUp: (PointerEvent details) {
              if (_isDragging) {
                setState(() {
                  /// return to the origin
                  _isDragging = false;
                  _offset = widget.holdPosition ? _offset : widget.initialOffset;
                });
              } else if (i == 0) {
                /// the button was clicked not dragged
                /// add the onPressed function to the top widget only
                widget.onPressed();
              }
            },
            child: Visibility(
              /// the key is the widget order
              key: ValueKey(i),
              child: widget.children[i],
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              // TODO: need to be more realistic
              visible: !widget.hideUnderlying
                  ? true
                  : (i == 0 // the top widget
                      || // if we are not holding positions, show me unless I reach the initial position
                      (!hide)),
            ),
          ),
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: getAnimatedPositionedWidgets());
  }
}
