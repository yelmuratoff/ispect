import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

/// A horizontal split view with a draggable divider between two children.
///
/// Typical for IDE-like web layouts: log list on the left, detail on the right,
/// with a grabbable divider in the middle.
class ResizableSplitView extends StatefulWidget {
  const ResizableSplitView({
    required this.left,
    required this.right,
    this.initialRatio = 0.4,
    this.minRatio = 0.2,
    this.maxRatio = 0.8,
    this.dividerWidth = 8,
    this.dividerColor,
    this.onRatioChanged,
    super.key,
  });

  final Widget left;
  final Widget right;

  /// Initial width ratio for the left panel (0.0 to 1.0).
  final double initialRatio;

  /// Minimum width ratio for the left panel.
  final double minRatio;

  /// Maximum width ratio for the left panel.
  final double maxRatio;

  /// Width of the draggable divider area.
  final double dividerWidth;

  /// Color of the divider line.
  final Color? dividerColor;

  /// Called when the user finishes dragging the divider.
  final ValueChanged<double>? onRatioChanged;

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _ratio;
  bool _isDragging = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final dividerHalf = widget.dividerWidth / 2;
          final leftWidth = (totalWidth * _ratio) - dividerHalf;
          final rightWidth = totalWidth * (1 - _ratio) - dividerHalf;

          return Row(
            children: [
              SizedBox(
                width: leftWidth.clamp(0, totalWidth),
                child: widget.left,
              ),
              _DragDivider(
                width: widget.dividerWidth,
                isDragging: _isDragging,
                isHovered: _isHovered,
                dividerColor: widget.dividerColor ??
                    context.ispectTheme.divider?.resolve(context),
                onHoverChanged: (hovered) =>
                    setState(() => _isHovered = hovered),
                onDragStart: () => setState(() => _isDragging = true),
                onDragUpdate: (dx) {
                  setState(() {
                    _ratio = (_ratio + dx / totalWidth).clamp(
                      widget.minRatio,
                      widget.maxRatio,
                    );
                  });
                },
                onDragEnd: () {
                  setState(() => _isDragging = false);
                  widget.onRatioChanged?.call(_ratio);
                },
              ),
              SizedBox(
                width: rightWidth.clamp(0, totalWidth),
                child: widget.right,
              ),
            ],
          );
        },
      );
}

class _DragDivider extends StatelessWidget {
  const _DragDivider({
    required this.width,
    required this.isDragging,
    required this.isHovered,
    required this.onHoverChanged,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.dividerColor,
  });

  final double width;
  final bool isDragging;
  final bool isHovered;
  final Color? dividerColor;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final isActive = isDragging || isHovered;
    final primaryColor = context.appTheme.colorScheme.primary;
    final defaultColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.08);
    final lineColor =
        isActive ? primaryColor.withValues(alpha: 0.5) : defaultColor;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
        onHorizontalDragEnd: (_) => onDragEnd(),
        child: SizedBox(
          width: width,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isActive ? 3 : 1,
              height: double.infinity,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
