import 'package:flutter/material.dart';
import 'package:ispect_layout/src/inspector_controller.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    super.key,
    required this.controller,
    this.initialIsVisible = true,
  });

  final InspectorController controller;
  final bool initialIsVisible;

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  late bool _isVisible;

  InspectorController get controller => widget.controller;

  Color get _activeColor => controller.theme.chromeAccentColor;
  Color get _surfaceColor => controller.theme.chromeSurfaceColor;
  Color get _onSurfaceColor => controller.theme.chromeOnSurfaceColor;
  Color get _onActiveColor => controller.theme.chromeOnAccentColor;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initialIsVisible;
  }

  @override
  void didUpdateWidget(covariant InspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsVisible != widget.initialIsVisible) {
      _isVisible = widget.initialIsVisible;
    }
  }

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
  }

  IconData get _visibilityButtonIcon {
    if (_isVisible) return Icons.chevron_right;

    final mode = controller.modeNotifier.value;
    switch (mode) {
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
        return Icons.format_shapes;
      case InspectorMode.compareSelect:
        return Icons.format_shapes;
      case InspectorMode.colorPicker:
        return Icons.colorize;
      case InspectorMode.zoom:
        return Icons.zoom_in;
      case InspectorMode.none:
        return Icons.chevron_left;
    }
  }

  Color get _visibilityButtonBackgroundColor {
    if (_isVisible) return _surfaceColor;

    if (controller.modeNotifier.value != InspectorMode.none) {
      return _activeColor;
    }

    return _surfaceColor;
  }

  Color get _visibilityButtonForegroundColor {
    if (_isVisible) return _onSurfaceColor;

    if (controller.modeNotifier.value != InspectorMode.none) {
      return _onActiveColor;
    }

    return _onSurfaceColor;
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe locally so the panel updates correctly when used outside
    // Inspector.build (e.g., via a custom panelBuilder that doesn't wrap
    // InspectorPanel in its own ValueListenableBuilder).
    return ListenableBuilder(
      listenable: controller.modeNotifier,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final mode = controller.modeNotifier.value;

    final height = 16.0 +
        (controller.isWidgetInspectorEnabled ? 56.0 : 0.0) +
        (controller.isColorPickerEnabled ? 64.0 : 0.0) +
        (controller.isZoomEnabled ? 64.0 : 0.0);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: _toggleVisibility,
            backgroundColor: _visibilityButtonBackgroundColor,
            foregroundColor: _visibilityButtonForegroundColor,
            child: Icon(_visibilityButtonIcon),
          ),
          if (_isVisible) ...[
            const SizedBox(height: 16.0),
            if (controller.isWidgetInspectorEnabled)
              FloatingActionButton(
                onPressed: () => controller.setMode(
                  (mode == InspectorMode.inspector ||
                          mode == InspectorMode.compareSelect)
                      ? InspectorMode.none
                      : InspectorMode.inspector,
                ),
                backgroundColor: (mode == InspectorMode.inspector ||
                        mode == InspectorMode.compareSelect)
                    ? _activeColor
                    : _surfaceColor,
                foregroundColor: (mode == InspectorMode.inspector ||
                        mode == InspectorMode.compareSelect)
                    ? _onActiveColor
                    : _onSurfaceColor,
                child: const Icon(Icons.format_shapes),
              ),
            if (controller.isColorPickerEnabled) ...[
              const SizedBox(height: 8.0),
              FloatingActionButton(
                onPressed: () => controller.setMode(
                  mode == InspectorMode.colorPicker
                      ? InspectorMode.none
                      : InspectorMode.colorPicker,
                  context: context,
                ),
                backgroundColor: mode == InspectorMode.colorPicker
                    ? _activeColor
                    : _surfaceColor,
                foregroundColor: mode == InspectorMode.colorPicker
                    ? _onActiveColor
                    : _onSurfaceColor,
                child: const Icon(Icons.colorize),
              ),
            ],
            if (controller.isZoomEnabled) ...[
              const SizedBox(height: 8.0),
              FloatingActionButton(
                onPressed: () => controller.setMode(
                  mode == InspectorMode.zoom
                      ? InspectorMode.none
                      : InspectorMode.zoom,
                ),
                backgroundColor:
                    mode == InspectorMode.zoom ? _activeColor : _surfaceColor,
                foregroundColor: mode == InspectorMode.zoom
                    ? _onActiveColor
                    : _onSurfaceColor,
                child: const Icon(Icons.zoom_in),
              ),
            ],
          ] else
            SizedBox(height: height),
        ],
      ),
    );
  }
}
