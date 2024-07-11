// ignore_for_file: avoid_positional_fields_in_records
import 'package:feedback_plus/feedback_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/ispect_page.dart';
import 'package:ispect/src/common/controllers/draggable_button_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/res/constants/ispect_constants.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:share_plus/share_plus.dart';

part 'panel_icon_button.dart';
part 'view.dart';

/// state for the invoker widget (defaults to alwaysOpened)
///
/// `alwaysOpened`:
/// This will force the the invoker widget to be opened always
///
/// `collapsible`:
/// This will make the widget to collapse and expand on demand
/// By default it will be in collapsed state
/// Tap or outwards will expand the widget
/// When expanded, tapping on it will navigate to Infospect screen.
/// And swiping it inwards will change it to collapsed state
///
/// `autoCollapse`: This will auto change the widget state from expanded to collapse after 5 seconds
/// By default it will be in collapsed state
/// Tap or outwards will expand the widget and if not tapped within 5 secs, it will change to
/// collapsed state.
/// When expanded, tapping on it will navigate to Infospect screen and will change it to
/// collapsed state
/// And swiping it inwards will change it to collapsed state
enum InvokerState { alwaysOpened, collapsible, autoCollapse }

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    required this.isInspectorEnabled,
    required this.isColorPickerEnabled,
    required this.isColorPickerLoading,
    required this.isZoomEnabled,
    required this.isZoomLoading,
    required this.options,
    required this.onPositionChanged,
    this.initialPosition,
    this.navigatorKey,
    super.key,
    this.onInspectorStateChanged,
    this.onColorPickerStateChanged,
    this.onZoomStateChanged,
    this.state = InvokerState.collapsible,
  });

  final bool isInspectorEnabled;
  final ValueChanged<bool>? onInspectorStateChanged;

  final bool isColorPickerEnabled;
  final ValueChanged<bool>? onColorPickerStateChanged;

  final bool isZoomEnabled;
  final ValueChanged<bool>? onZoomStateChanged;

  final bool isColorPickerLoading;
  final bool isZoomLoading;
  final (double x, double y)? initialPosition;

  ///
  final InvokerState state;
  final ISpectOptions options;
  final GlobalKey<NavigatorState>? navigatorKey;
  final void Function(double x, double y)? onPositionChanged;

  @override
  State createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  bool get _isInspectorEnabled => widget.onInspectorStateChanged != null;
  bool get _isColorPickerEnabled => widget.onColorPickerStateChanged != null;
  bool get _isZoomEnabled => widget.onZoomStateChanged != null;

  final DraggableButtonController _controller = DraggableButtonController();

  @override
  void initState() {
    super.initState();

    _controller.setIsCollapsed(true);
    if (widget.initialPosition != null) {
      _controller
        ..xPos = widget.initialPosition!.$1
        ..yPos = widget.initialPosition!.$2;
    }
    if (widget.state == InvokerState.autoCollapse) {
      _controller.startAutoCollapseTimer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleInspectorState() {
    assert(_isInspectorEnabled);
    widget.onInspectorStateChanged!(!widget.isInspectorEnabled);
  }

  void _toggleColorPickerState() {
    assert(_isColorPickerEnabled);
    widget.onColorPickerStateChanged!(!widget.isColorPickerEnabled);
  }

  void _toogleZoomState() {
    assert(_isZoomEnabled);
    widget.onZoomStateChanged!(!widget.isZoomEnabled);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, constraints) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _ButtonView(
            onTap: () {
              if (widget.state != InvokerState.alwaysOpened) {
                if (!_controller.isCollapsed) {
                  _controller.setIsCollapsed(true);
                  _buttonToEnd(context);
                  if (widget.state == InvokerState.autoCollapse) {
                    _controller.startAutoCollapseTimer();
                  }
                }
              }
            },
            xPos: _controller.xPos,
            yPos: _controller.yPos,
            screenWidth: constraints.maxWidth,
            onPanUpdate: (details) {
              if (!_controller.isCollapsed) {
                _controller
                  ..xPos += details.delta.dx
                  ..yPos += details.delta.dy
                  ..xPos = _controller.xPos.clamp(
                    0.0,
                    constraints.maxWidth - ISpectConstants.draggableButtonWidth,
                  )
                  ..yPos = _controller.yPos.clamp(
                    0.0,
                    MediaQuery.sizeOf(context).height -
                        ISpectConstants.draggableButtonHeight,
                  );
              }
            },
            onPanEnd: (_) {
              if (!_controller.isCollapsed) {
                _buttonToEnd(context);

                if (widget.state == InvokerState.autoCollapse) {
                  _controller.startAutoCollapseTimer();
                }
              }
            },
            onButtonTap: () {
              _controller.setIsCollapsed(!_controller.isCollapsed);
              if (_controller.isCollapsed) {
                _controller.cancelAutoCollapseTimer();
                _launchInfospect(context);
              } else if (widget.state == InvokerState.autoCollapse) {
                _controller.startAutoCollapseTimer();
              }
            },
            isCollapsed: _controller.isCollapsed,
            inLoggerPage: _controller.inLoggerPage,
            isInspectorEnabled: widget.isInspectorEnabled,
            onInspectorToggle: _toggleInspectorState,
            isColorPickerEnabled: widget.isColorPickerEnabled,
            onColorPickerToggle: _toggleColorPickerState,
            isZoomEnabled: widget.isZoomEnabled,
            onZoomToggle: _toogleZoomState,
            isFeedbackEnabled: BetterFeedback.of(context).isVisible,
            onFeedbackToggle: () {
              if (!BetterFeedback.of(context).isVisible) {
                BetterFeedback.of(context).show((feedback) async {
                  final screenshotFilePath =
                      await writeImageToStorage(feedback.screenshot);

                  await Share.shareXFiles(
                    [screenshotFilePath],
                    text: feedback.text,
                  );
                });
              } else {
                BetterFeedback.of(context).hide();
              }
              // ignore: avoid_empty_blocks
              setState(() {});
            },
          ),
        ),
      );

  void _buttonToEnd(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final halfScreenWidth = screenWidth / 2;
    double targetXPos;

    if (_controller.xPos + ISpectConstants.draggableButtonWidth / 2 <
        halfScreenWidth) {
      targetXPos = 0;
    } else {
      targetXPos = screenWidth - ISpectConstants.draggableButtonWidth;
    }

    setState(() {
      _controller
        ..xPos = targetXPos
        ..yPos = _controller.yPos.clamp(
          0.0,
          MediaQuery.sizeOf(context).height -
              ISpectConstants.draggableButtonHeight,
        );
    });

    widget.onPositionChanged?.call(_controller.xPos, _controller.yPos);
  }

  void _launchInfospect(BuildContext context) {
    final context0 = widget.navigatorKey?.currentContext ?? context;
    if (_controller.isCollapsed) {
      if (_controller.inLoggerPage) {
        Navigator.pop(context0);
      } else {
        // ignore: prefer_async_await
        Navigator.push(
          context0,
          MaterialPageRoute<dynamic>(
            builder: (_) => ISpectPage(
              options: widget.options,
            ),
          ),
        ).then((_) {
          _controller.setInLoggerPage(false);
        });
        _controller.setInLoggerPage(true);
      }
    }
  }
}
