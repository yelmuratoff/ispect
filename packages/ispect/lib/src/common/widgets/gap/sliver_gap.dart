import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A sliver that takes a fixed amount of space.
///
/// See also:
///
///  * [Gap], the render box version of this widget.
class SliverGap extends LeafRenderObjectWidget {
  /// Creates a sliver that takes a fixed [mainAxisExtent] of space.
  ///
  /// The [mainAxisExtent] must not be null and must be positive.
  const SliverGap(
    this.mainAxisExtent, {
    super.key,
    this.color,
  }) : assert(mainAxisExtent >= 0 && mainAxisExtent < double.infinity);

  /// The amount of space this widget takes in the direction of the parent.
  ///
  /// Must not be null and must be positive.
  final double mainAxisExtent;

  /// The color used to fill the gap.
  final Color? color;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSliverGap(
        mainAxisExtent: mainAxisExtent,
        color: color,
      );

  @override
  void updateRenderObject(BuildContext context, RenderSliverGap renderObject) {
    renderObject
      ..mainAxisExtent = mainAxisExtent
      ..color = color;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(ColorProperty('color', color));
  }
}

class RenderSliverGap extends RenderSliver {
  RenderSliverGap({
    required double mainAxisExtent,
    Color? color,
  })  : _mainAxisExtent = mainAxisExtent,
        _color = color;

  double get mainAxisExtent => _mainAxisExtent;
  double _mainAxisExtent;
  set mainAxisExtent(double value) {
    if (_mainAxisExtent != value) {
      _mainAxisExtent = value;
      markNeedsLayout();
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
  void performLayout() {
    final paintExtent = calculatePaintOffset(
      constraints,
      from: 0,
      to: mainAxisExtent,
    );
    final cacheExtent = calculateCacheOffset(
      constraints,
      from: 0,
      to: mainAxisExtent,
    );

    assert(paintExtent.isFinite);
    assert(paintExtent >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: mainAxisExtent,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: mainAxisExtent,
      hitTestExtent: paintExtent,
      hasVisualOverflow: mainAxisExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (color != null) {
      final paint = Paint()..color = color!;
      final size = constraints
          .asBoxConstraints(
            minExtent: geometry!.paintExtent,
            maxExtent: geometry!.paintExtent,
          )
          .constrain(Size.zero);
      context.canvas.drawRect(offset & size, paint);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(ColorProperty('color', color));
  }
}
