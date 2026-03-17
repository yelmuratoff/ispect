import 'package:flutter/material.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/box_info_widget.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    required this.size,
    required this.boxInfo,
    required this.onEnterCompareMode,
    required this.onExitCompareMode,
    super.key,
    this.comparedBoxInfo,
    this.isCompareMode = false,
  });

  final Size size;
  final BoxInfo? boxInfo;
  final BoxInfo? comparedBoxInfo;
  final bool isCompareMode;
  final VoidCallback onEnterCompareMode;
  final VoidCallback onExitCompareMode;

  @override
  State createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay> {
  final _panelVisibilityNotifier = ValueNotifier<bool>(false);
  int? _frameCallbackId;
  bool _disposed = false;
  Rect? _lastTargetRect;

  @override
  void initState() {
    super.initState();
    _onTick(null);
  }

  @override
  void didUpdateWidget(covariant InspectorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resume frame scheduling when boxInfo becomes non-null.
    if (widget.boxInfo != null && _frameCallbackId == null && !_disposed) {
      _onTick(null);
    }
  }

  @override
  void dispose() {
    final id = _frameCallbackId;
    if (id != null) {
      WidgetsBinding.instance.cancelFrameCallbackWithId(id);
      _frameCallbackId = null;
    }
    _disposed = true;
    _panelVisibilityNotifier.dispose();
    super.dispose();
  }

  void _onTick(Duration? tick) {
    if (_disposed || !mounted) return;

    final boxInfo = widget.boxInfo;
    final currentRect = _canRender && boxInfo != null
        ? getRectFromRenderBox(boxInfo.targetRenderBox)
        : null;

    if (currentRect != _lastTargetRect) {
      _lastTargetRect = currentRect;
      setState(() {});
    }

    // Only continue scheduling frames when there is an active box to track.
    if (boxInfo != null) {
      _frameCallbackId = WidgetsBinding.instance.scheduleFrameCallback(
        _onTick,
        rescheduling: tick != null,
      );
    } else {
      _frameCallbackId = null;
    }
  }

  bool get _canRender => widget.boxInfo?.targetRenderBox.attached ?? false;

  @override
  Widget build(BuildContext context) {
    if (!_canRender) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: ValueListenableBuilder(
        valueListenable: _panelVisibilityNotifier,
        builder: (_, isVisible, __) => BoxInfoWidget(
          boxInfo: widget.boxInfo!,
          comparedBoxInfo: widget.comparedBoxInfo,
          isCompareMode: widget.isCompareMode,
          isPanelVisible: isVisible,
          onPanelVisibilityChanged: (v) => _panelVisibilityNotifier.value = v,
          onEnterCompareMode: widget.onEnterCompareMode,
          onExitCompareMode: widget.onExitCompareMode,
        ),
      ),
    );
  }
}
