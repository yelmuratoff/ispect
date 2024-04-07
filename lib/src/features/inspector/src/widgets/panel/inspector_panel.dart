import 'package:feedback_plus/feedback_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect_page.dart';
import 'package:share_plus/share_plus.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    super.key,
    required this.isInspectorEnabled,
    required this.isColorPickerEnabled,
    this.onInspectorStateChanged,
    this.onColorPickerStateChanged,
    required this.isColorPickerLoading,
    required this.isZoomEnabled,
    this.onZoomStateChanged,
    required this.isZoomLoading,
    this.backgroundColor,
    this.textColor,
    this.selectedColor,
    this.selectedTextColor,
  });

  final bool isInspectorEnabled;
  final ValueChanged<bool>? onInspectorStateChanged;

  final bool isColorPickerEnabled;
  final ValueChanged<bool>? onColorPickerStateChanged;

  final bool isZoomEnabled;
  final ValueChanged<bool>? onZoomStateChanged;

  final bool isColorPickerLoading;
  final bool isZoomLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? selectedColor;
  final Color? selectedTextColor;

  @override
  State createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  bool _isVisible = true;

  bool get _isInspectorEnabled => widget.onInspectorStateChanged != null;
  bool get _isColorPickerEnabled => widget.onColorPickerStateChanged != null;
  bool get _isZoomEnabled => widget.onZoomStateChanged != null;

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
  }

  void _toggleInspectorState() {
    assert(_isInspectorEnabled);
    widget.onInspectorStateChanged!(!widget.isInspectorEnabled);
  }

  void _toggleColorPickerState() {
    assert(_isColorPickerEnabled);
    widget.onColorPickerStateChanged!(!widget.isColorPickerEnabled);
  }

  void _toogleZoomState() {
    assert(_isZoomEnabled);
    widget.onZoomStateChanged!(!widget.isZoomEnabled);
  }

  IconData get _visibilityButtonIcon {
    if (_isVisible) return Icons.chevron_right_rounded;

    if (widget.isInspectorEnabled) {
      return Icons.format_shapes;
    } else if (widget.isColorPickerEnabled) {
      return Icons.colorize;
    } else if (widget.isZoomEnabled) {
      return Icons.zoom_in;
    }

    return Icons.chevron_left_rounded;
  }

  Color get _visibilityButtonBackgroundColor {
    if (_isVisible) return widget.backgroundColor ?? Colors.white;

    if (widget.isInspectorEnabled || widget.isColorPickerEnabled || widget.isZoomEnabled) {
      return widget.selectedColor ?? Colors.blue;
    }

    return widget.backgroundColor ?? Colors.white;
  }

  Color get _visibilityButtonForegroundColor {
    if (_isVisible) return widget.textColor ?? Colors.black54;

    if (widget.isInspectorEnabled || widget.isColorPickerEnabled || widget.isZoomEnabled) {
      return widget.selectedTextColor ?? Colors.white;
    }

    return widget.textColor ?? Colors.black54;
  }

  @override
  Widget build(BuildContext context) {
    final height = 16.0 + (_isInspectorEnabled ? 56.0 : 0.0) + (_isColorPickerEnabled ? 64.0 : 0.0) + (_isZoomEnabled ? 64.0 : 0.0);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: widget.selectedColor?.withOpacity(0.5) ?? Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: _toggleVisibility,
            backgroundColor: _visibilityButtonBackgroundColor,
            foregroundColor: _visibilityButtonForegroundColor,
            child: Icon(_visibilityButtonIcon),
          ),
          if (_isVisible) ...[
            const SizedBox(height: 16.0),
            if (_isInspectorEnabled)
              FloatingActionButton(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: widget.selectedColor?.withOpacity(0.5) ?? Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: _toggleInspectorState,
                backgroundColor: widget.isInspectorEnabled ? widget.selectedColor ?? Colors.blue : widget.backgroundColor ?? Colors.white,
                foregroundColor: widget.isInspectorEnabled ? widget.selectedTextColor ?? Colors.white : widget.textColor ?? Colors.black54,
                child: const Icon(Icons.format_shapes),
              ),
            if (_isColorPickerEnabled) ...[
              const SizedBox(height: 8.0),
              FloatingActionButton(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: widget.selectedColor?.withOpacity(0.5) ?? Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: _toggleColorPickerState,
                backgroundColor: widget.isColorPickerEnabled ? widget.selectedColor ?? Colors.blue : widget.backgroundColor ?? Colors.white,
                foregroundColor: widget.isColorPickerEnabled ? widget.selectedTextColor ?? Colors.white : widget.textColor ?? Colors.black54,
                child: widget.isColorPickerLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.colorize),
              ),
              if (_isZoomEnabled) ...[
                const SizedBox(height: 8.0),
                FloatingActionButton(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: widget.selectedColor?.withOpacity(0.5) ?? Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: _toogleZoomState,
                  backgroundColor: widget.isZoomEnabled ? widget.selectedColor ?? Colors.blue : widget.backgroundColor ?? Colors.white,
                  foregroundColor: widget.isZoomEnabled ? widget.selectedTextColor ?? Colors.white : widget.textColor ?? Colors.black54,
                  child: widget.isZoomLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.zoom_in),
                ),
              ],
              const SizedBox(height: 8.0),
              AnimatedBuilder(
                animation: BetterFeedback.of(context),
                builder: (context, child) {
                  final feedback = BetterFeedback.of(context);
                  return FloatingActionButton(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: widget.selectedColor?.withOpacity(0.5) ?? Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () {
                      if (!BetterFeedback.of(context).isVisible) {
                        feedback.show((UserFeedback feedback) async {
                          final screenshotFilePath = await writeImageToStorage(feedback.screenshot);

                          await Share.shareXFiles(
                            [screenshotFilePath],
                            text: feedback.text,
                          );
                        });
                      } else {
                        feedback.hide();
                      }
                      setState(() {});
                    },
                    backgroundColor: feedback.isVisible ? widget.selectedColor ?? Colors.blue : widget.backgroundColor ?? Colors.white,
                    foregroundColor: feedback.isVisible ? widget.selectedTextColor ?? Colors.white : widget.textColor ?? Colors.black54,
                    child: const Icon(Icons.camera_alt_rounded),
                  );
                },
              ),
            ],
          ] else
            SizedBox(height: height),
        ],
      ),
    );
  }
}
