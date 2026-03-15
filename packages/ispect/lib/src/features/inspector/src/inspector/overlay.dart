import 'package:flutter/material.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/box_info_widget.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    required this.size,
    required this.boxInfo,
    super.key,
  });

  final Size size;
  final BoxInfo? boxInfo;

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
        ? boxInfo.targetRenderBox.localToGlobal(Offset.zero) &
            boxInfo.targetRenderBox.size
        : null;

    if (currentRect != _lastTargetRect) {
      _lastTargetRect = currentRect;
      setState(() {});
    }

    _frameCallbackId = WidgetsBinding.instance.scheduleFrameCallback(
      _onTick,
      rescheduling: tick != null,
    );
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
          isPanelVisible: isVisible,
          onPanelVisibilityChanged: (v) => _panelVisibilityNotifier.value = v,
        ),
      ),
    );
  }
}
