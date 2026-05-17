/// Width of the type column in the compact log-row layout.
const double kCompactTypeColumnWidth = 52;

/// Viewport width below which desktop log rows switch to the compact layout.
const double kDesktopLogCompactBreakpoint = 480;

/// Below this width the HTTP transaction row hides its hover-action cluster.
const double kHoverActionsMinWidth = 400;

/// Below this width Request/Response chips render as icon-only buttons.
const double kFullChipLabelsMinWidth = 720;

({double typeWidth, double timeWidth}) scaleColumnWidths({
  required double available,
  required double typeWidth,
  required double timeWidth,
}) {
  final totalColumns = typeWidth + timeWidth;
  if (totalColumns <= 0) return (typeWidth: typeWidth, timeWidth: timeWidth);

  final maxForColumns = available * 0.5;
  if (totalColumns > maxForColumns) {
    final scale = maxForColumns / totalColumns;
    return (typeWidth: typeWidth * scale, timeWidth: timeWidth * scale);
  }
  return (typeWidth: typeWidth, timeWidth: timeWidth);
}
