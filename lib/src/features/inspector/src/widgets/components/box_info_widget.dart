import 'package:flutter/material.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/box_info_panel_widget.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/information_box_widget.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/overlay_painter.dart';
import 'package:ispect/src/features/inspector/src/widgets/inspector/box_info.dart';

class BoxInfoWidget extends StatelessWidget {
  const BoxInfoWidget({
    required this.boxInfo,
    required this.isPanelVisible,
    required this.onPanelVisibilityChanged,
    super.key,
  });

  final BoxInfo boxInfo;

  final bool isPanelVisible;
  final ValueChanged<bool> onPanelVisibilityChanged;

  Color get _targetColor => Colors.blue.shade700;
  Color get _containerColor => Colors.yellow.shade700;

  Widget _buildTargetBoxSizeWidget(BuildContext context) => Positioned(
        top: calculateBoxPosition(
          rect: boxInfo.targetRectShifted,
          height: InformationBoxWidget.preferredHeight,
        ),
        left: boxInfo.targetRectShifted.left,
        child: IgnorePointer(
          child: Align(
            child: InformationBoxWidget.size(
              size: boxInfo.targetRect.size,
              color: _targetColor,
            ),
          ),
        ),
      );

  Widget _buildTargetBoxInfoPanel(BuildContext context) => BoxInfoPanelWidget(
        boxInfo: boxInfo,
        targetColor: _targetColor,
        containerColor: _containerColor,
        isVisible: isPanelVisible,
        onVisibilityChanged: onPanelVisibilityChanged,
      );

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: OverlayPainter(
                boxInfo: boxInfo,
                targetRectColor: _targetColor.withOpacity(0.35),
                containerRectColor: _containerColor.withOpacity(0.35),
              ),
            ),
          ),
          // ..._buildPaddingWidgets(context),
          _buildTargetBoxSizeWidget(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildTargetBoxInfoPanel(context),
            ),
          ),
        ],
      );
}
