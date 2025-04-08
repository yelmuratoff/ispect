import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that takes a fixed amount of space in the direction of its parent.
///
/// It only works in the following cases:
/// - It is a descendant of a `Row`, [Column], or [Flex],
/// and the path from the `Gap` widget to its enclosing [Row], [Column], or
/// `Flex` must contain only [StatelessWidget]s or [StatefulWidget]s (not other
/// kinds of widgets, like `RenderObjectWidget`s).
/// - It is a descendant of a `Scrollable`.
///
/// See also:
///
///  * `MaxGap`, a gap that can take, at most, the amount of space specified.
///  * `SliverGap`, the sliver version of this widget.
class Gap extends StatelessWidget {
  /// Creates a widget that takes a fixed `mainAxisExtent` of space in the
  /// direction of its parent.
  ///
  /// The `mainAxisExtent` must not be null and must be positive.
  /// The `crossAxisExtent` must be either null or positive.
  const Gap(
    this.mainAxisExtent, {
    super.key,
    this.crossAxisExtent,
    this.color,
  })  : assert(mainAxisExtent >= 0 && mainAxisExtent < double.infinity),
        assert(crossAxisExtent == null || crossAxisExtent >= 0);

  /// Creates a widget that takes a fixed `mainAxisExtent` of space in the
  /// direction of its parent and expands in the cross axis direction.
  ///
  /// The `mainAxisExtent` must not be null and must be positive.
  const Gap.expand(
    double mainAxisExtent, {
    Key? key,
    Color? color,
  }) : this(
          mainAxisExtent,
          key: key,
          crossAxisExtent: double.infinity,
          color: color,
        );

  /// The amount of space this widget takes in the direction of its parent.
  ///
  /// For example:
  /// - If the parent is a `Column` this is the height of this widget.
  /// - If the parent is a `Row` this is the width of this widget.
  ///
  /// Must not be null and must be positive.
  final double mainAxisExtent;

  /// The amount of space this widget takes in the opposite direction of the
  /// parent.
  ///
  /// For example:
  /// - If the parent is a `Column` this is the width of this widget.
  /// - If the parent is a `Row` this is the height of this widget.
  ///
  /// Must be positive or null. If it's null (the default) the cross axis extent
  /// will be the same as the constraints of the parent in the opposite
  /// direction.
  final double? crossAxisExtent;

  /// The color used to fill the gap.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scrollableState = Scrollable.maybeOf(context);
    final axisDirection = scrollableState?.axisDirection;
    final fallbackDirection =
        axisDirection == null ? null : axisDirectionToAxis(axisDirection);

    return _RawGap(
      mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      color: color,
      fallbackDirection: fallbackDirection,
    );
  }
}

/// A widget that takes, at most, an amount of space in a `Row`, [Column],
/// or `Flex` widget.
///
/// A `MaxGap` widget must be a descendant of a [Row], [Column], or [Flex],
/// and the path from the `MaxGap` widget to its enclosing [Row], [Column], or
/// `Flex` must contain only [StatelessWidget]s or [StatefulWidget]s (not other
/// kinds of widgets, like `RenderObjectWidget`s).
///
/// See also:
///
///  * `Gap`, the unflexible version of this widget.
class MaxGap extends StatelessWidget {
  /// Creates a widget that takes, at most, the specified `mainAxisExtent` of
  /// space in a `Row`, [Column], or [Flex] widget.
  ///
  /// The `mainAxisExtent` must not be null and must be positive.
  /// The `crossAxisExtent` must be either null or positive.
  const MaxGap(
    this.mainAxisExtent, {
    super.key,
    this.crossAxisExtent,
    this.color,
  });

  /// Creates a widget that takes, at most, the specified `mainAxisExtent` of
  /// space in a `Row`, [Column], or [Flex] widget and expands in the cross axis
  /// direction.
  ///
  /// The `mainAxisExtent` must not be null and must be positive.
  /// The `crossAxisExtent` must be either null or positive.
  const MaxGap.expand(
    double mainAxisExtent, {
    Key? key,
    Color? color,
  }) : this(
          mainAxisExtent,
          key: key,
          crossAxisExtent: double.infinity,
          color: color,
        );

  /// The amount of space this widget takes in the direction of the parent.
  ///
  /// If the parent is a `Column` this is the height of this widget.
  /// If the parent is a `Row` this is the width of this widget.
  ///
  /// Must not be null and must be positive.
  final double mainAxisExtent;

  /// The amount of space this widget takes in the opposite direction of the
  /// parent.
  ///
  /// If the parent is a `Column` this is the width of this widget.
  /// If the parent is a `Row` this is the height of this widget.
  ///
  /// Must be positive or null. If it's null (the default) the cross axis extent
  /// will be the same as the constraints of the parent in the opposite
  /// direction.
  final double? crossAxisExtent;

  /// The color used to fill the gap.
  final Color? color;

  @override
  Widget build(BuildContext context) => Flexible(
        child: _RawGap(
          mainAxisExtent,
          crossAxisExtent: crossAxisExtent,
          color: color,
        ),
      );
}

class _RawGap extends LeafRenderObjectWidget {
  const _RawGap(
    this.mainAxisExtent, {
    this.crossAxisExtent,
    this.color,
    this.fallbackDirection,
  })  : assert(mainAxisExtent >= 0 && mainAxisExtent < double.infinity),
        assert(crossAxisExtent == null || crossAxisExtent >= 0);

  final double mainAxisExtent;

  final double? crossAxisExtent;

  final Color? color;

  final Axis? fallbackDirection;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderGap(
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent ?? 0,
        color: color,
        fallbackDirection: fallbackDirection,
      );

  @override
  void updateRenderObject(BuildContext context, RenderGap renderObject) {
    renderObject
      ..mainAxisExtent = mainAxisExtent
      ..crossAxisExtent = crossAxisExtent ?? 0
      ..color = color
      ..fallbackDirection = fallbackDirection;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(DoubleProperty('crossAxisExtent', crossAxisExtent, defaultValue: 0))
      ..add(ColorProperty('color', color))
      ..add(EnumProperty<Axis>('fallbackDirection', fallbackDirection));
  }
}

class RenderGap extends RenderBox {
  RenderGap({
    required double mainAxisExtent,
    double? crossAxisExtent,
    Axis? fallbackDirection,
    Color? color,
  })  : _mainAxisExtent = mainAxisExtent,
        _crossAxisExtent = crossAxisExtent,
        _color = color,
        _fallbackDirection = fallbackDirection;

  double get mainAxisExtent => _mainAxisExtent;
  double _mainAxisExtent;
  set mainAxisExtent(double value) {
    if (_mainAxisExtent != value) {
      _mainAxisExtent = value;
      markNeedsLayout();
    }
  }

  double? get crossAxisExtent => _crossAxisExtent;
  double? _crossAxisExtent;
  set crossAxisExtent(double? value) {
    if (_crossAxisExtent != value) {
      _crossAxisExtent = value;
      markNeedsLayout();
    }
  }

  Axis? get fallbackDirection => _fallbackDirection;
  Axis? _fallbackDirection;
  set fallbackDirection(Axis? value) {
    if (_fallbackDirection != value) {
      _fallbackDirection = value;
      markNeedsLayout();
    }
  }

  Axis? get _direction {
    final parentNode = parent;
    if (parentNode is RenderFlex) {
      return parentNode.direction;
    } else {
      return fallbackDirection;
    }
  }

  Color? get color => _color;
  Color? _color;
  set color(Color? value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => _computeIntrinsicExtent(
        Axis.horizontal,
        () => super.computeMinIntrinsicWidth(height),
      )!;

  @override
  double computeMaxIntrinsicWidth(double height) => _computeIntrinsicExtent(
        Axis.horizontal,
        () => super.computeMaxIntrinsicWidth(height),
      )!;

  @override
  double computeMinIntrinsicHeight(double width) => _computeIntrinsicExtent(
        Axis.vertical,
        () => super.computeMinIntrinsicHeight(width),
      )!;

  @override
  double computeMaxIntrinsicHeight(double width) => _computeIntrinsicExtent(
        Axis.vertical,
        () => super.computeMaxIntrinsicHeight(width),
      )!;

  double? _computeIntrinsicExtent(Axis axis, double Function() compute) {
    final direction = _direction;
    if (direction == axis) {
      return _mainAxisExtent;
    } else {
      if (_crossAxisExtent!.isFinite) {
        return _crossAxisExtent;
      } else {
        return compute();
      }
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final direction = _direction;

    if (direction != null) {
      if (direction == Axis.horizontal) {
        return constraints.constrain(Size(mainAxisExtent, crossAxisExtent!));
      } else {
        return constraints.constrain(Size(crossAxisExtent!, mainAxisExtent));
      }
    } else {
      throw FlutterError(
        'A Gap widget must be placed directly inside a Flex widget '
        'or its fallbackDirection must not be null',
      );
    }
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (color != null) {
      final paint = Paint()..color = color!;
      context.canvas.drawRect(offset & size, paint);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(DoubleProperty('crossAxisExtent', crossAxisExtent))
      ..add(ColorProperty('color', color))
      ..add(EnumProperty<Axis>('fallbackDirection', fallbackDirection));
  }
}
