import 'package:flutter/material.dart';
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
    this.hoveredBoxInfo,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
  });

  final BoxInfo? boxInfo;
  final BoxInfo? hoveredBoxInfo;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  static const Color _selectedColor = Color(0xFF2962FF);
  static const Color _comparedColor = Color(0xFFFF6D00);
  static const Color _hoveredColor = Color(0xFF448AFF);
  static const Color _containerColor = Color(0xFFFFB300);

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
            color: _selectedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetBoxInfoPanel(BuildContext context) {
    return BoxInfoPanelWidget(
      boxInfo: boxInfo!,
      comparedBoxInfo: comparedBoxInfo,
      onCompare: onCompare,
      isCompareActive: isCompareActive,
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
          containerColor: showContainerRenderBox ? _containerColor : null,
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
            accentColor: _selectedColor,
          ),
        if (hoveredBoxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(
            context,
            hoveredBoxInfo!,
            role: OverlayRole.hovered,
            accentColor: _hoveredColor,
            showContainerRenderBox: false,
          ),
        if (comparedBoxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(
            context,
            comparedBoxInfo!,
            role: OverlayRole.compared,
            accentColor: _comparedColor,
            showContainerRenderBox: false,
          ),
        if (boxInfo?.targetRenderBox.attached == true &&
            comparedBoxInfo?.targetRenderBox.attached == true)
          IgnorePointer(
            child: CustomPaint(
              painter: CompareOverlayPainter(
                boxInfoA: boxInfo!,
                boxInfoB: comparedBoxInfo!,
                lineColor: Colors.green.shade700,
              ),
            ),
          ),
        // ..._buildPaddingWidgets(context),
        if (boxInfo?.targetRenderBox.attached == true) ...[
          _buildTargetBoxSizeWidget(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildTargetBoxInfoPanel(context),
            ),
          ),
        ],
      ],
    );
  }
}
