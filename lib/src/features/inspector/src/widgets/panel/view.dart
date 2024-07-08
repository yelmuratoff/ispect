part of 'inspector_panel.dart';

class _ButtonView extends StatelessWidget {
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
  final VoidCallback onTap;
  final double xPos;
  final double yPos;
  final double screenWidth;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final void Function(DragEndDetails details) onPanEnd;
  final VoidCallback onButtonTap;
  final bool isCollapsed;
  final bool inLoggerPage;

  final bool isInspectorEnabled;
  final VoidCallback onInspectorToggle;

  final bool isColorPickerEnabled;
  final VoidCallback onColorPickerToggle;

  final bool isZoomEnabled;
  final VoidCallback onZoomToggle;

  final bool isFeedbackEnabled;
  final VoidCallback onFeedbackToggle;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);

    return Stack(
      children: [
        TapRegion(
          onTapOutside: (_) {
            if (!isInspectorEnabled &&
                !isColorPickerEnabled &&
                !isZoomEnabled) {
              onTap.call();
            }
          },
          child: Stack(
            children: [
              Positioned(
                top: yPos,
                left: (xPos < screenWidth / 2) ? xPos + 5 : null,
                right:
                    (xPos > screenWidth / 2) ? (screenWidth - xPos - 55) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: ISpectConstants.draggableButtonHeight,
                  width: isCollapsed
                      ? ISpectConstants.draggableButtonWidth * 0.2
                      : ISpectConstants.draggableButtonWidth * 5.3,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: adjustColorDarken(
                      context.ispectTheme.colorScheme.primaryContainer,
                      0.3,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    reverse: xPos < ISpectConstants.draggableButtonWidth,
                    children: [
                      _PanelIconButton(
                        icon: Icons.monitor_heart_outlined,
                        isActive: iSpect.isPerformanceTrackingEnabled,
                        onPressed: iSpect.togglePerformanceTracking,
                      ),
                      _PanelIconButton(
                        icon: Icons.format_shapes_rounded,
                        isActive: isInspectorEnabled,
                        onPressed: onInspectorToggle.call,
                      ),
                      _PanelIconButton(
                        icon: Icons.colorize_rounded,
                        isActive: isColorPickerEnabled,
                        onPressed: onColorPickerToggle.call,
                      ),
                      _PanelIconButton(
                        icon: Icons.zoom_in_rounded,
                        isActive: isZoomEnabled,
                        onPressed: onZoomToggle.call,
                      ),
                      _PanelIconButton(
                        icon: Icons.camera_alt_rounded,
                        isActive: isFeedbackEnabled,
                        onPressed: onFeedbackToggle.call,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: yPos,
                left: (xPos < ISpectConstants.draggableButtonWidth)
                    ? xPos + 5
                    : null,
                right: (xPos > ISpectConstants.draggableButtonWidth)
                    ? (screenWidth - xPos - 55)
                    : null,
                child: GestureDetector(
                  onPanUpdate: onPanUpdate.call,
                  onPanEnd: onPanEnd.call,
                  onTap: onButtonTap.call,
                  child: AnimatedContainer(
                    width: isCollapsed
                        ? ISpectConstants.draggableButtonWidth * 0.25
                        : ISpectConstants.draggableButtonWidth,
                    height: ISpectConstants.draggableButtonHeight,
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: context.ispectTheme.colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: !isCollapsed
                        ? inLoggerPage
                            ? const Icon(
                                Icons.undo_rounded,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.reorder_rounded,
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
