import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/column_widths.dart';

/// A sticky table header row for the desktop log table.
class DesktopLogTableHeader extends StatelessWidget {
  const DesktopLogTableHeader({
    super.key,
    this.backgroundColor,
    this.sortColumn,
    this.sortDirection,
    this.onSortTap,
    this.typeColumnWidth = 100,
    this.timeColumnWidth = 140,
    this.onColumnResize,
  });

  final Color? backgroundColor;
  final int? sortColumn;
  final int? sortDirection;
  final void Function(int column)? onSortTap;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final void Function(int column, double delta)? onColumnResize;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.08);
    final labelColor = onSurface.withValues(alpha: 0.45);
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.appTheme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < kDesktopLogCompactBreakpoint;
          final scaled = scaleColumnWidths(
            available: constraints.maxWidth,
            typeWidth: isCompact ? kCompactTypeColumnWidth : typeColumnWidth,
            timeWidth: isCompact ? 0 : timeColumnWidth,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const Gap(8),
                _SortableColumnHeader(
                  label: 'TYPE',
                  width: scaled.typeWidth,
                  columnIndex: 0,
                  isActive: sortColumn == 0,
                  isAscending: sortDirection == 0,
                  onTap: onSortTap,
                  labelStyle: labelStyle,
                  labelColor: labelColor,
                  onResize: isCompact ? null : onColumnResize,
                ),
                const Gap(8),
                if (!isCompact) ...[
                  _SortableColumnHeader(
                    label: 'TIME',
                    width: scaled.timeWidth,
                    columnIndex: 1,
                    isActive: sortColumn == 1,
                    isAscending: sortDirection == 0,
                    onTap: onSortTap,
                    labelStyle: labelStyle,
                    labelColor: labelColor,
                    onResize: isCompact ? null : onColumnResize,
                  ),
                  const Gap(12),
                ],
                Expanded(
                  child: _SortableColumnHeader(
                    label: 'MESSAGE',
                    columnIndex: 2,
                    isActive: sortColumn == 2,
                    isAscending: sortDirection == 0,
                    onTap: onSortTap,
                    labelStyle: labelStyle,
                    labelColor: labelColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SortableColumnHeader extends StatelessWidget {
  const _SortableColumnHeader({
    required this.label,
    required this.columnIndex,
    required this.isActive,
    required this.isAscending,
    required this.labelStyle,
    required this.labelColor,
    this.width,
    this.onTap,
    this.onResize,
  });

  final String label;
  final int columnIndex;
  final double? width;
  final bool isActive;
  final bool isAscending;
  final void Function(int column)? onTap;
  final TextStyle labelStyle;
  final Color labelColor;
  final void Function(int column, double delta)? onResize;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.7);

    final sortHint = isActive
        ? (isAscending ? 'sorted ascending' : 'sorted descending')
        : 'not sorted';

    Widget header = Semantics(
      button: true,
      label: 'Sort by $label, $sortHint',
      onTap: onTap != null ? () => onTap!(columnIndex) : null,
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: onTap != null ? () => onTap!(columnIndex) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: labelStyle.copyWith(
                    color: isActive ? activeColor : labelColor,
                  ),
                ),
              ),
              const Gap(2),
              Icon(
                isActive
                    ? (isAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 12,
                color:
                    isActive ? activeColor : labelColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );

    if (width != null) {
      header = SizedBox(
        width: width,
        child: Row(
          children: [
            Expanded(child: header),
            if (onResize != null)
              Semantics(
                label: 'Resize $label column',
                slider: true,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) =>
                        onResize!(columnIndex, details.delta.dx),
                    child: SizedBox(
                      width: 12,
                      height: 20,
                      child: Center(
                        child: Container(
                          width: 2,
                          height: 14,
                          decoration: BoxDecoration(
                            color: labelColor.withValues(alpha: 0.3),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return header;
  }
}
