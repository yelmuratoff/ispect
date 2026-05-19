import 'package:flutter/material.dart';
import 'package:ispect_layout/src/theme.dart';
import 'package:ispect_layout/src/widgets/inspector/render_box_extension.dart';

import '../inspector/box_info.dart';
import '../inspector/compare_overlay_painter.dart';
import 'box_info_panel_widget.dart';
import 'information_box_widget.dart';
import 'overlay_painter.dart';

class BoxInfoWidget extends StatelessWidget {
  const BoxInfoWidget({
    super.key,
    this.boxInfo,
    required this.decimalPlaces,
    required this.theme,
    this.hoveredBoxInfo,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
    this.onSelectFromPath,
  });

  final BoxInfo? boxInfo;
  final int decimalPlaces;
  final InspectorTheme theme;
  final BoxInfo? hoveredBoxInfo;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;
  final void Function(RenderBox box)? onSelectFromPath;

  Widget _buildTargetBoxSizeWidget(BuildContext context) {
    return Positioned(
      top: calculateBoxPosition(
        rect: boxInfo!.targetRectShifted,
        height: InformationBoxWidget.preferredHeight,
      ),
      left: boxInfo!.targetRectShifted.left,
      child: IgnorePointer(
        child: Align(
          child: InformationBoxWidget.size(
            size: boxInfo!.targetRenderBox.displaySize,
            decimalPlaces: decimalPlaces,
            color: theme.selectedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetBoxInfoPanel(BuildContext context) {
    return BoxInfoPanelWidget(
      boxInfo: boxInfo!,
      decimalPlaces: decimalPlaces,
      comparedBoxInfo: comparedBoxInfo,
      onCompare: onCompare,
      isCompareActive: isCompareActive,
      onSelectFromPath: onSelectFromPath,
    );
  }

  /// Places the info panel on the side of the screen opposite to the target,
  /// so selection details never cover the widget being inspected. Respects
  /// safe-area insets so the panel doesn't collide with the status bar or
  /// the bottom gesture area.
  Widget _buildPanelSlot(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final targetCenterY = boxInfo!.targetRectShifted.center.dy;
    final panelOnTop = targetCenterY > screenHeight / 2;

    const gap = 12.0;
    return Positioned(
      left: gap,
      right: gap,
      top: panelOnTop ? mq.padding.top + gap : null,
      bottom: panelOnTop ? null : mq.padding.bottom + gap,
      child: _buildTargetBoxInfoPanel(context),
    );
  }

  Widget _buildBoxOverlay(
    BuildContext context,
    BoxInfo boxInfo, {
    required OverlayRole role,
    required Color accentColor,
    bool showContainerRenderBox = true,
  }) {
    return IgnorePointer(
      child: CustomPaint(
        painter: OverlayPainter(
          boxInfo: boxInfo,
          role: role,
          accentColor: accentColor,
          containerColor: showContainerRenderBox ? theme.containerColor : null,
          showContainerRenderBox: showContainerRenderBox,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (boxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(
            context,
            boxInfo!,
            role: OverlayRole.selected,
            accentColor: theme.selectedColor,
          ),
        if (hoveredBoxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(
            context,
            hoveredBoxInfo!,
            role: OverlayRole.hovered,
            accentColor: theme.hoveredColor,
            showContainerRenderBox: false,
          ),
        if (comparedBoxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(
            context,
            comparedBoxInfo!,
            role: OverlayRole.compared,
            accentColor: theme.comparedColor,
            showContainerRenderBox: false,
          ),
        if (boxInfo?.targetRenderBox.attached == true &&
            comparedBoxInfo?.targetRenderBox.attached == true)
          IgnorePointer(
            child: CustomPaint(
              painter: CompareOverlayPainter(
                boxInfoA: boxInfo!,
                boxInfoB: comparedBoxInfo!,
                lineColor: theme.compareLineColor ?? Colors.green.shade700,
              ),
            ),
          ),
        if (boxInfo?.targetRenderBox.attached == true) ...[
          _buildTargetBoxSizeWidget(context),
          _buildPanelSlot(context),
        ],
      ],
    );
  }
}
