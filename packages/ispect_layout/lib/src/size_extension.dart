import 'dart:ui';

extension SizeExtension on Size {
  bool isSmallerThan(Size other) => width * height < other.width * other.height;

  bool isGreaterThan(Size other) => width * height > other.width * other.height;
}
