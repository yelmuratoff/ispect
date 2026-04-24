import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../components/box_info_widget.dart';
import 'box_info.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    super.key,
    required this.size,
    required this.boxInfo,
    required this.decimalPlaces,
    this.hoveredBoxInfo,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
  });

  final Size size;
  final BoxInfo? boxInfo;
  final int decimalPlaces;
  final BoxInfo? hoveredBoxInfo;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  @override
  State<InspectorOverlay> createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Cached rects to detect changes from outside (zoom / pan / scroll).
  Rect? _lastBoxInfoTargetRect;
  Rect? _lastHoverBoxInfoTargetRect;
  Rect? _lastComparedBoxInfoTargetRect;

  bool _canRender(BoxInfo? boxInfo) =>
      boxInfo?.targetRenderBox.attached ?? false;

  bool get _anyBoxActive =>
      _canRender(widget.boxInfo) ||
      _canRender(widget.hoveredBoxInfo) ||
      _canRender(widget.comparedBoxInfo);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _syncTickerState();
  }

  @override
  void didUpdateWidget(covariant InspectorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTickerState();
  }

  // Keep the ticker running only while there is something to observe.
  // Idle ticking at 60 fps is wasted work when no box is selected.
  void _syncTickerState() {
    final shouldTick = _anyBoxActive;
    if (shouldTick && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldTick && _ticker.isActive) {
      _ticker.stop();
      _lastBoxInfoTargetRect = null;
      _lastHoverBoxInfoTargetRect = null;
      _lastComparedBoxInfoTargetRect = null;
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final canRenderBox = _canRender(widget.boxInfo);
    final canRenderHovered = _canRender(widget.hoveredBoxInfo);
    final canRenderCompared = _canRender(widget.comparedBoxInfo);

    if (!canRenderBox && !canRenderHovered && !canRenderCompared) return;

    final currentBoxRect =
        canRenderBox ? widget.boxInfo!.targetRectShifted : null;
    final currentHoverRect =
        canRenderHovered ? widget.hoveredBoxInfo!.targetRectShifted : null;
    final currentComparedRect =
        canRenderCompared ? widget.comparedBoxInfo!.targetRectShifted : null;

    if (currentBoxRect != _lastBoxInfoTargetRect ||
        currentHoverRect != _lastHoverBoxInfoTargetRect ||
        currentComparedRect != _lastComparedBoxInfoTargetRect) {
      _lastBoxInfoTargetRect = currentBoxRect;
      _lastHoverBoxInfoTargetRect = currentHoverRect;
      _lastComparedBoxInfoTargetRect = currentComparedRect;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender(widget.boxInfo) && !_canRender(widget.hoveredBoxInfo)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: BoxInfoWidget(
        boxInfo: widget.boxInfo,
        decimalPlaces: widget.decimalPlaces,
        hoveredBoxInfo: widget.hoveredBoxInfo,
        comparedBoxInfo: widget.comparedBoxInfo,
        onCompare: widget.onCompare,
        isCompareActive: widget.isCompareActive,
      ),
    );
  }
}
