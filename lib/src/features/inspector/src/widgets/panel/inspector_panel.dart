import 'package:feedback_plus/feedback_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect_page.dart';
import 'package:ispect/src/common/controllers/draggable_button_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/utils/ispect_options.dart';
import 'package:share_plus/share_plus.dart';

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
    super.key,
    required this.isInspectorEnabled,
    required this.isColorPickerEnabled,
    this.onInspectorStateChanged,
    this.onColorPickerStateChanged,
    required this.isColorPickerLoading,
    required this.isZoomEnabled,
    this.onZoomStateChanged,
    required this.isZoomLoading,
    required this.navigatorKey,
    this.state = InvokerState.collapsible,
    required this.options,
  });

  final bool isInspectorEnabled;
  final ValueChanged<bool>? onInspectorStateChanged;

  final bool isColorPickerEnabled;
  final ValueChanged<bool>? onColorPickerStateChanged;

  final bool isZoomEnabled;
  final ValueChanged<bool>? onZoomStateChanged;

  final bool isColorPickerLoading;
  final bool isZoomLoading;

  ///
  final InvokerState state;
  final ISpectOptions options;
  final GlobalKey<NavigatorState> navigatorKey;

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
    if (widget.state == InvokerState.autoCollapse) {
      _controller.startAutoCollapseTimer();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _ButtonView(
          onTap: () {
            if (widget.state != InvokerState.alwaysOpened) {
              if (!_controller.isCollapsed) {
                _controller.setIsCollapsed(true);
                if (widget.state == InvokerState.autoCollapse) {
                  _controller.startAutoCollapseTimer();
                }
              }
            }
          },
          xPos: _controller.xPos,
          yPos: _controller.yPos,
          screenWidth: screenWidth,
          onPanUpdate: (DragUpdateDetails details) {
            if (!_controller.isCollapsed) {
              _controller.xPos += details.delta.dx;
              _controller.yPos += details.delta.dy;
            }
          },
          onPanEnd: (DragEndDetails details) {
            if (!_controller.isCollapsed) {
              final screenWidth = MediaQuery.of(context).size.width;
              const buttonWidth = 50;

              final halfScreenWidth = screenWidth / 2;
              double targetXPos;

              if (_controller.xPos + buttonWidth / 2 < halfScreenWidth) {
                targetXPos = 0;
              } else {
                targetXPos = screenWidth - buttonWidth;
              }

              _controller.xPos = targetXPos;

              if (widget.state == InvokerState.autoCollapse) {
                _controller.startAutoCollapseTimer();
              }
            }
          },
          onButtonTap: () {
            _controller.setIsCollapsed(!_controller.isCollapsed);
            if (_controller.isCollapsed) {
              _controller.cancelAutoCollapseTimer();
              _launchInfospect();
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
              BetterFeedback.of(context).show((UserFeedback feedback) async {
                final screenshotFilePath = await writeImageToStorage(feedback.screenshot);

                await Share.shareXFiles(
                  [screenshotFilePath],
                  text: feedback.text,
                );
              });
            } else {
              BetterFeedback.of(context).hide();
            }
            setState(() {});
          },
        );
      },
    );
  }

  void _launchInfospect() {
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (_controller.isCollapsed && context != null) {
      if (_controller.inLoggerPage) {
        Navigator.pop(context);
      } else {
        Navigator.push(
          widget.navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (context) => ISpectPage(
              options: widget.options,
            ),
          ),
        ).then((value) {
          _controller.setInLoggerPage(false);
        });
        _controller.setInLoggerPage(true);
      }
    }
  }
}

class _ButtonView extends StatelessWidget {
  final Function() onTap;
  final double xPos;
  final double yPos;
  final double screenWidth;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final Function() onButtonTap;
  final bool isCollapsed;
  final bool inLoggerPage;

  final bool isInspectorEnabled;
  final Function() onInspectorToggle;

  final bool isColorPickerEnabled;
  final Function() onColorPickerToggle;

  final bool isZoomEnabled;
  final Function() onZoomToggle;

  final bool isFeedbackEnabled;
  final Function() onFeedbackToggle;
  const _ButtonView({
    required this.onTap,
    required this.xPos,
    required this.yPos,
    required this.screenWidth,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onButtonTap,
    required this.isCollapsed,
    required this.inLoggerPage,
    required this.isInspectorEnabled,
    required this.onInspectorToggle,
    required this.isColorPickerEnabled,
    required this.onColorPickerToggle,
    required this.isZoomEnabled,
    required this.onZoomToggle,
    required this.isFeedbackEnabled,
    required this.onFeedbackToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TapRegion(
          onTapOutside: (event) {
            if (!isInspectorEnabled && !isColorPickerEnabled && !isZoomEnabled) {
              onTap.call();
            }
          },
          child: Stack(
            children: [
              Positioned(
                top: yPos,
                left: (xPos < 50) ? xPos + 5 : null,
                right: (xPos > 50) ? (screenWidth - xPos - 45) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 50,
                  width: isCollapsed ? 50 * 0.2 : 50 * 5,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: adjustColorDarken(context.ispectTheme.colorScheme.primaryContainer, 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    reverse: xPos < 50,
                    children: [
                      _PanelIconButton(
                        icon: Icons.format_shapes_rounded,
                        isActive: isInspectorEnabled,
                        onPressed: () {
                          onInspectorToggle.call();
                        },
                      ),
                      _PanelIconButton(
                        icon: Icons.colorize_rounded,
                        isActive: isColorPickerEnabled,
                        onPressed: () {
                          onColorPickerToggle.call();
                        },
                      ),
                      _PanelIconButton(
                        icon: Icons.zoom_in_rounded,
                        isActive: isZoomEnabled,
                        onPressed: () {
                          onZoomToggle.call();
                        },
                      ),
                      _PanelIconButton(
                        icon: Icons.camera_alt_rounded,
                        isActive: isFeedbackEnabled,
                        onPressed: () {
                          onFeedbackToggle.call();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: yPos,
                left: (xPos < 50) ? xPos + 5 : null,
                right: (xPos > 50) ? (screenWidth - xPos - 45) : null,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    onPanUpdate.call(details);
                  },
                  onPanEnd: (details) {
                    onPanEnd.call(details);
                  },
                  onTap: () {
                    onButtonTap.call();
                  },
                  child: AnimatedContainer(
                    width: isCollapsed ? 50 * 0.2 : 50,
                    height: 50,
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: context.ispectTheme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: !isCollapsed
                        ? inLoggerPage
                            ? const Icon(
                                Icons.undo_rounded,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.monitor_heart,
                                color: Colors.white,
                              )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Function() onPressed;
  const _PanelIconButton({required this.icon, required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      icon: Icon(icon),
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        backgroundColor: MaterialStateProperty.all<Color>(isActive ? context.ispectTheme.colorScheme.primaryContainer : Colors.transparent),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      onPressed: () {
        onPressed.call();
      },
    );
  }
}
