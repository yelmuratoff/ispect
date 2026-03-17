import 'package:flutter/material.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/box_info_panel_widget.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/compare_overlay_painter.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/information_box_widget.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/overlay_painter.dart';

class BoxInfoWidget extends StatelessWidget {
  const BoxInfoWidget({
    required this.boxInfo,
    required this.isPanelVisible,
    required this.onPanelVisibilityChanged,
    required this.onEnterCompareMode,
    required this.onExitCompareMode,
    super.key,
    this.comparedBoxInfo,
    this.hoveredBoxInfo,
    this.isCompareMode = false,
  });

  final BoxInfo boxInfo;
  final BoxInfo? comparedBoxInfo;
  final BoxInfo? hoveredBoxInfo;
  final bool isCompareMode;

  final bool isPanelVisible;
  final ValueChanged<bool> onPanelVisibilityChanged;
  final VoidCallback onEnterCompareMode;
  final VoidCallback onExitCompareMode;

  Color get _targetColor => Colors.blue.shade700;
  Color get _containerColor => Colors.yellow.shade700;
  Color get _comparedColor => Colors.green.shade700;
  Color get _hoveredColor => Colors.orange.shade700;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Primary selection overlay
          IgnorePointer(
            child: CustomPaint(
              painter: OverlayPainter(
                boxInfo: boxInfo,
                targetRectColor: _targetColor.withValues(alpha: 0.35),
                containerRectColor: _containerColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Compared box overlay
          if (comparedBoxInfo?.targetRenderBox.attached ?? false)
            IgnorePointer(
              child: CustomPaint(
                painter: OverlayPainter(
                  boxInfo: comparedBoxInfo!,
                  targetRectColor: _comparedColor.withValues(alpha: 0.35),
                  containerRectColor: Colors.transparent,
                ),
              ),
            ),
          // Hovered box overlay (desktop compare preview)
          if (hoveredBoxInfo?.targetRenderBox.attached ?? false)
            IgnorePointer(
              child: CustomPaint(
                painter: OverlayPainter(
                  boxInfo: hoveredBoxInfo!,
                  targetRectColor: _hoveredColor.withValues(alpha: 0.25),
                  containerRectColor: Colors.transparent,
                ),
              ),
            ),
          // Distance lines between compared boxes
          if (comparedBoxInfo?.targetRenderBox.attached ?? false)
            IgnorePointer(
              child: CustomPaint(
                painter: CompareOverlayPainter(
                  boxInfoA: boxInfo,
                  boxInfoB: comparedBoxInfo!,
                  lineColor: _comparedColor,
                ),
              ),
            ),
          _TargetBoxSizeWidget(
            boxInfo: boxInfo,
            targetColor: _targetColor,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BoxInfoPanelWidget(
                boxInfo: boxInfo,
                comparedBoxInfo: comparedBoxInfo,
                isCompareMode: isCompareMode,
                targetColor: _targetColor,
                containerColor: _containerColor,
                isVisible: isPanelVisible,
                onVisibilityChanged: onPanelVisibilityChanged,
                onEnterCompareMode: onEnterCompareMode,
                onExitCompareMode: onExitCompareMode,
              ),
            ),
          ),
        ],
      );
}

class _TargetBoxSizeWidget extends StatelessWidget {
  const _TargetBoxSizeWidget({
    required this.boxInfo,
    required this.targetColor,
  });
  final BoxInfo boxInfo;
  final Color targetColor;

  @override
  Widget build(BuildContext context) {
    final targetRectShifted = boxInfo.targetRectShifted;
    final targetRect = boxInfo.targetRect;
    if (targetRectShifted == null || targetRect == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: calculateBoxPosition(
        rect: targetRectShifted,
        height: InformationBoxWidget.preferredHeight,
      ),
      left: targetRectShifted.left,
      child: IgnorePointer(
        child: Align(
          child: InformationBoxWidget.size(
            size: targetRect.size,
            color: targetColor,
          ),
        ),
      ),
    );
  }
}
