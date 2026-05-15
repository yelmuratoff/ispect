/// Width applied to the type column when LayoutBuilder reports a viewport
/// narrower than [kDesktopLogCompactBreakpoint]. Wide enough to fit the
/// "TYPE" header alongside the sort icon (sort icon + gap take ~14 px), and
/// matches the data cell widths used in the row layouts.
const double kCompactTypeColumnWidth = 52;

/// Below this viewport width the desktop log/transaction rows switch to a
/// compact layout: the time column disappears and the type column shrinks to
/// [kCompactTypeColumnWidth].
const double kDesktopLogCompactBreakpoint = 480;

/// Proportionally scale type/time column widths so they never overflow.
/// Both columns shrink equally when space is tight.
({double typeWidth, double timeWidth}) scaleColumnWidths({
  required double available,
  required double typeWidth,
  required double timeWidth,
}) {
  final totalColumns = typeWidth + timeWidth;
  if (totalColumns <= 0) return (typeWidth: typeWidth, timeWidth: timeWidth);

  // Columns should use at most half the available width
  final maxForColumns = available * 0.5;
  if (totalColumns > maxForColumns) {
    final scale = maxForColumns / totalColumns;
    return (typeWidth: typeWidth * scale, timeWidth: timeWidth * scale);
  }
  return (typeWidth: typeWidth, timeWidth: timeWidth);
}
