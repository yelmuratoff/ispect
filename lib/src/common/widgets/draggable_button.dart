import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/ispect_page.dart';
import 'package:ispect/src/common/controllers/draggable_button_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';

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

/// A StatefulWidget that serves as a UI invoker for the Infospect tool.
/// Depending on the platform and configuration, it displays a floating action-like button
/// which when tapped or dragged can invoke the Infospect tool.
class DraggableButton extends StatefulWidget {
  final Widget child;
  final InvokerState state;
  final ISpectOptions options;
  final GlobalKey<NavigatorState> navigatorKey;

  const DraggableButton({
    required this.child,
    required this.navigatorKey,
    required this.options,
    super.key,
    this.state = InvokerState.collapsible,
  });

  @override
  State<DraggableButton> createState() => _InfospectInvokerState();
}

class _InfospectInvokerState extends State<DraggableButton> {
  final DraggableButtonController controller = DraggableButtonController();

  @override
  void initState() {
    super.initState();
    if (widget.state == InvokerState.autoCollapse) {
      controller.startAutoCollapseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => _ButtonView(
        onTap: () {
          if (widget.state != InvokerState.alwaysOpened) {
            if (!controller.isCollapsed) {
              controller.setIsCollapsed(true);
              if (widget.state == InvokerState.autoCollapse) {
                controller.startAutoCollapseTimer();
              }
            }
          }
        },
        xPos: controller.xPos,
        yPos: controller.yPos,
        screenWidth: screenWidth,
        onPanUpdate: (DragUpdateDetails details) {
          if (!controller.isCollapsed) {
            controller.xPos += details.delta.dx;
            controller.yPos += details.delta.dy;
          }
        },
        onPanEnd: (DragEndDetails details) {
          if (!controller.isCollapsed) {
            final screenWidth = MediaQuery.of(context).size.width;
            const buttonWidth = 50;

            final halfScreenWidth = screenWidth / 2;
            double targetXPos;

            if (controller.xPos + buttonWidth / 2 < halfScreenWidth) {
              targetXPos = 0;
            } else {
              targetXPos = screenWidth - buttonWidth;
            }

            controller.xPos = targetXPos;

            if (widget.state == InvokerState.autoCollapse) {
              controller.startAutoCollapseTimer();
            }
          }
        },
        onButtonTap: () {
          controller.setIsCollapsed(!controller.isCollapsed);
          if (controller.isCollapsed) {
            controller.cancelAutoCollapseTimer();
            _launchInfospect();
          } else if (widget.state == InvokerState.autoCollapse) {
            controller.startAutoCollapseTimer();
          }
        },
        isCollapsed: controller.isCollapsed,
        inLoggerPage: controller.inLoggerPage,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _launchInfospect() {
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (controller.isCollapsed && context != null) {
      if (controller.inLoggerPage) {
        Navigator.pop(context);
      } else {
        Navigator.push(
          widget.navigatorKey.currentContext!,
          MaterialPageRoute<dynamic>(
            builder: (context) => ISpectPage(
              options: widget.options,
            ),
          ),
        ).then((value) {
          controller.setInLoggerPage(false);
        });
        controller.setInLoggerPage(true);
      }
    }
  }
}

class _ButtonView extends StatelessWidget {
  final void Function() onTap;
  final Widget child;
  final double xPos;
  final double yPos;
  final double screenWidth;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;
  final void Function() onButtonTap;
  final bool isCollapsed;
  final bool inLoggerPage;
  const _ButtonView({
    required this.onTap,
    required this.child,
    required this.xPos,
    required this.yPos,
    required this.screenWidth,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onButtonTap,
    required this.isCollapsed,
    required this.inLoggerPage,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          TapRegion(
            onTapOutside: (event) {
              onTap.call();
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
                      color: adjustColorDarken(
                        context.ispectTheme.colorScheme.primaryContainer,
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      reverse: xPos < 50,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_shapes_rounded),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.colorize_rounded),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in_rounded),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_rounded),
                          onPressed: () {},
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
