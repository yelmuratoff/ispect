import 'dart:ui';

extension SizeExtension on Size {
  /// Area-based "smaller than" — used to pick the innermost hit-test target.
  /// Area is a single-scalar ordering, so it collapses for rects of equal
  /// area but different aspect (100×1 vs 10×10); in practice child boxes
  /// nested via [RenderBox] layout are fully contained, so ties are rare
  /// and further resolved by [isMeaningful] in BoxInfo.fromHitTestResults.
  bool isSmallerThan(Size other) => width * height < other.width * other.height;

  bool isGreaterThan(Size other) => width * height > other.width * other.height;
}
