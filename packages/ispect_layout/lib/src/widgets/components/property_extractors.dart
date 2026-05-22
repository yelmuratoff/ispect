import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';
import 'package:ispect_layout/src/widgets/components/value_descriptors.dart';

export 'package:ispect_layout/src/widgets/components/value_descriptors.dart';

/// Below this magnitude a transform component (translate / scale - 1) is
/// considered noise and the corresponding chip is suppressed.
const _kTransformEpsilon = 0.001;

/// Below this magnitude (degrees) the rotation chip is suppressed.
const _kRotationEpsilon = 0.01;

String _fmt(double v, int decimalPlaces) =>
    formatInspectorDouble(v, decimalPlaces: decimalPlaces);

/// Recovers the [ImageProvider] that produced a [RenderImage] via its
/// [RenderObject.debugCreator]. Only debug builds populate it; returns
/// `null` in release/profile.
ImageProvider? resolveImageProvider(RenderImage target) {
  if (!kDebugMode) return null;
  final creator = target.debugCreator;
  if (creator is! DebugCreator) return null;
  final widget = creator.element.widget;
  if (widget is Image) return widget.image;
  return null;
}

// ─── Common chip builders ────────────────────────────────────────────────────

PropSpec? _clipBehaviorProp(Clip clipBehavior) => clipBehavior == Clip.none
    ? null
    : (
        icon: Icons.crop,
        subtitle: 'clip behavior',
        child: Text(clipBehavior.name),
      );

/// Renders a clipper as a [shapeBorderProps] section when it is a
/// [ShapeBorderClipper], else as a single chip with the runtime type name.
List<PropSpec> _clipperProps(
  CustomClipper<dynamic>? clipper, {
  int decimalPlaces = 1,
}) {
  if (clipper == null) return const [];
  if (clipper is ShapeBorderClipper) {
    return shapeBorderProps(clipper.shape, decimalPlaces: decimalPlaces);
  }
  return [
    (
      icon: Icons.brush,
      subtitle: 'clipper',
      child: Text(clipper.runtimeType.toString()),
    ),
  ];
}

// ─── Property extractors ─────────────────────────────────────────────────────

List<PropSpec> constraintsProps(BoxConstraints c, {int decimalPlaces = 1}) {
  String fmt(double min, double max) {
    if (min == max) return '=${_fmt(min, decimalPlaces)}';
    final hi = max == double.infinity ? '∞' : _fmt(max, decimalPlaces);
    return '${_fmt(min, decimalPlaces)}–$hi';
  }

  return [
    (
      icon: Icons.swap_horiz,
      subtitle: 'width',
      child: Text(fmt(c.minWidth, c.maxWidth)),
    ),
    (
      icon: Icons.swap_vert,
      subtitle: 'height',
      child: Text(fmt(c.minHeight, c.maxHeight)),
    ),
  ];
}

List<PropSpec> paragraphProps(
  RenderParagraph target, {
  int decimalPlaces = 1,
}) =>
    [
      (
        icon: Icons.format_align_left,
        subtitle: 'text align',
        child: Text(target.textAlign.name),
      ),
      if (target.maxLines != null)
        (
          icon: Icons.format_list_numbered,
          subtitle: 'max lines',
          child: Text('${target.maxLines}'),
        ),
      if (target.didExceedMaxLines)
        (
          icon: Icons.warning_amber,
          subtitle: 'overflow',
          child: const Text('exceeded'),
        ),
      if (target.overflow != TextOverflow.clip)
        (
          icon: Icons.more_horiz,
          subtitle: 'overflow',
          child: Text(target.overflow.name),
        ),
      if (!target.softWrap)
        (
          icon: Icons.wrap_text,
          subtitle: 'soft wrap',
          child: const Text('off'),
        ),
      if (target.textScaler != TextScaler.noScaling)
        (
          icon: Icons.text_fields,
          subtitle: 'text scale',
          child: Text(describeTextScaler(target.textScaler)),
        ),
    ];

List<PropSpec> spanProps(TextStyle style, {int decimalPlaces = 1}) => [
      if (style.fontFamily != null)
        (
          icon: Icons.font_download,
          subtitle: 'font family',
          child: Text(style.fontFamily!),
        ),
      if (style.fontSize != null)
        (
          icon: Icons.format_size,
          subtitle: 'font size',
          child: Text(_fmt(style.fontSize!, decimalPlaces)),
        ),
      if (style.fontWeight != null)
        (
          icon: Icons.line_weight,
          subtitle: 'weight',
          child: Text(describeFontWeight(style.fontWeight!)),
        ),
      if (style.fontStyle != null)
        (
          icon: Icons.format_italic,
          subtitle: 'style',
          child: Text(describeFontStyle(style.fontStyle!)),
        ),
      if (style.color != null)
        (
          icon: Icons.color_lens,
          subtitle: 'color',
          child: ColorHexChip(style.color!),
        ),
      if (style.height != null)
        (
          icon: Icons.height,
          subtitle: 'height',
          child: Text(_fmt(style.height!, decimalPlaces)),
        ),
      if (style.letterSpacing != null)
        (
          icon: Icons.horizontal_distribute,
          subtitle: 'letter spacing',
          child: Text(_fmt(style.letterSpacing!, decimalPlaces)),
        ),
      if (style.wordSpacing != null)
        (
          icon: Icons.space_bar,
          subtitle: 'word spacing',
          child: Text(_fmt(style.wordSpacing!, decimalPlaces)),
        ),
      if (style.decoration != null && style.decoration != TextDecoration.none)
        (
          icon: Icons.text_format,
          subtitle: 'decoration',
          child: Text(describeTextDecoration(style.decoration!)),
        ),
      if (style.backgroundColor != null)
        (
          icon: Icons.format_color_fill,
          subtitle: 'bg color',
          child: ColorHexChip(style.backgroundColor!),
        ),
    ];

List<PropSpec> shapeBorderProps(
  ShapeBorder shape, {
  int decimalPlaces = 1,
}) =>
    [
      (
        icon: Icons.circle_outlined,
        subtitle: 'shape',
        child: Text(shape.runtimeType.toString()),
      ),
      if (extractShapeBorderRadius(shape) case final borderRadius?)
        if (formatBorderRadius(borderRadius, decimalPlaces: decimalPlaces)
            case final br?)
          (
            icon: Icons.rounded_corner,
            subtitle: br.label,
            child: buildBorderRadiusChild(
              borderRadius,
              decimalPlaces: decimalPlaces,
            ),
          ),
    ];

List<PropSpec> decorationProps(BoxDecoration d, {int decimalPlaces = 1}) => [
      if (d.color != null)
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: ColorHexChip(d.color!),
        ),
      if (formatBorderRadius(
        d.borderRadius ?? BorderRadius.zero,
        decimalPlaces: decimalPlaces,
      )
          case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: buildBorderRadiusChild(
            d.borderRadius ?? BorderRadius.zero,
            decimalPlaces: decimalPlaces,
          ),
        ),
      if (d.shape != BoxShape.rectangle)
        (
          icon: Icons.circle_outlined,
          subtitle: 'shape',
          child: Text(d.shape.name),
        ),
      if (d.border != null)
        ..._borderProps(d.border!, decimalPlaces: decimalPlaces),
      if (d.boxShadow != null && d.boxShadow!.isNotEmpty)
        (
          icon: Icons.blur_on,
          subtitle: 'shadows',
          child: ShadowsView(d.boxShadow!, decimalPlaces: decimalPlaces),
        ),
      if (d.gradient != null)
        (
          icon: Icons.gradient,
          subtitle: 'gradient',
          child: GradientView(d.gradient!, decimalPlaces: decimalPlaces),
        ),
      if (d.image != null) ..._decorationImageProps(d.image!),
    ];

List<PropSpec> _decorationImageProps(DecorationImage img) => [
      (
        icon: Icons.image,
        subtitle: 'bg image',
        child: EllipsizedText(describeImageProvider(img.image)),
      ),
      (
        icon: Icons.fit_screen,
        subtitle: 'bg fit',
        child: Text(img.fit?.name ?? 'scaleDown'),
      ),
      if (img.alignment != Alignment.center)
        (
          icon: Icons.crop_free,
          subtitle: 'bg alignment',
          child: EllipsizedText(describeAlignment(img.alignment)),
        ),
      if (img.repeat != ImageRepeat.noRepeat)
        (
          icon: Icons.repeat,
          subtitle: 'bg repeat',
          child: Text(img.repeat.name),
        ),
      if (img.colorFilter != null)
        (
          icon: Icons.filter_b_and_w,
          subtitle: 'bg filter',
          child: EllipsizedText(describeColorFilter(img.colorFilter!)),
        ),
    ];

// ─── Border ──────────────────────────────────────────────────────────────────

List<PropSpec> _borderProps(BoxBorder border, {int decimalPlaces = 1}) {
  if (border is! Border) {
    return [
      (
        icon: Icons.border_all,
        subtitle: 'border',
        child: Text(border.runtimeType.toString()),
      ),
    ];
  }

  if (_uniformActiveBorderColor(border) case final color?) {
    return [
      (
        icon: Icons.border_all,
        subtitle: 'border',
        child: BorderSideValue(
          color: color,
          width: _formatBorderWidths(border, decimalPlaces),
        ),
      ),
    ];
  }

  return [
    for (final side in _activeSidesWithLabels(border))
      (
        icon: Icons.border_all,
        subtitle: 'border ${side.label}',
        child: BorderSideValue(
          color: side.side.color,
          width: _fmt(side.side.width, decimalPlaces),
        ),
      ),
  ];
}

/// Color shared by every active (width > 0) side, or `null` when sides
/// differ in color or no side is active.
Color? _uniformActiveBorderColor(Border border) {
  final active = [border.top, border.right, border.bottom, border.left]
      .where((s) => s.width > 0);
  if (active.isEmpty) return null;
  final color = active.first.color;
  return active.every((s) => s.color == color) ? color : null;
}

String _formatBorderWidths(Border border, int decimalPlaces) {
  final sides = [border.top, border.right, border.bottom, border.left];
  final widths = sides.map((s) => s.width).toSet();
  return widths.length == 1
      ? _fmt(widths.first, decimalPlaces)
      : sides.map((s) => _fmt(s.width, decimalPlaces)).join('/');
}

List<({String label, BorderSide side})> _activeSidesWithLabels(Border border) {
  const labels = ['T', 'R', 'B', 'L'];
  final sides = [border.top, border.right, border.bottom, border.left];
  return [
    for (var i = 0; i < sides.length; i++)
      if (sides[i].width > 0) (label: labels[i], side: sides[i]),
  ];
}

// ─── Per-render-box extractors ───────────────────────────────────────────────

List<PropSpec> stackProps(RenderStack target) => [
      (
        icon: Icons.align_vertical_bottom,
        subtitle: 'alignment',
        child: EllipsizedText(describeAlignment(target.alignment)),
      ),
      if (target.fit != StackFit.loose)
        (
          icon: Icons.fit_screen,
          subtitle: 'fit',
          child: Text(target.fit.name),
        ),
    ];

List<PropSpec> wrapProps(RenderWrap target, {int decimalPlaces = 1}) => [
      (
        icon: Icons.swap_horiz,
        subtitle: 'direction',
        child: Text(target.direction.name),
      ),
      if (target.spacing != 0)
        (
          icon: Icons.space_bar,
          subtitle: 'spacing',
          child: Text(_fmt(target.spacing, decimalPlaces)),
        ),
      if (target.runSpacing != 0)
        (
          icon: Icons.height,
          subtitle: 'run spacing',
          child: Text(_fmt(target.runSpacing, decimalPlaces)),
        ),
      if (target.alignment != WrapAlignment.start)
        (
          icon: Icons.format_align_left,
          subtitle: 'alignment',
          child: Text(target.alignment.name),
        ),
      if (target.runAlignment != WrapAlignment.start)
        (
          icon: Icons.vertical_align_top,
          subtitle: 'run alignment',
          child: Text(target.runAlignment.name),
        ),
    ];

List<PropSpec> clipRRectProps(
  RenderClipRRect target, {
  int decimalPlaces = 1,
}) =>
    [
      if (formatBorderRadius(target.borderRadius, decimalPlaces: decimalPlaces)
          case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: buildBorderRadiusChild(
            target.borderRadius,
            decimalPlaces: decimalPlaces,
          ),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipRSuperellipseProps(
  RenderClipRSuperellipse target, {
  int decimalPlaces = 1,
}) =>
    [
      if (formatBorderRadius(target.borderRadius, decimalPlaces: decimalPlaces)
          case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: buildBorderRadiusChild(
            target.borderRadius,
            decimalPlaces: decimalPlaces,
          ),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipRectProps(RenderClipRect target) => [
      ..._clipperProps(target.clipper),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipOvalProps(RenderClipOval target) => [
      ..._clipperProps(target.clipper),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipPathProps(
  RenderClipPath target, {
  int decimalPlaces = 1,
}) =>
    [
      ..._clipperProps(target.clipper, decimalPlaces: decimalPlaces),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> customPaintProps(RenderCustomPaint target) => [
      if (target.painter != null)
        (
          icon: Icons.brush,
          subtitle: 'painter',
          child: Text(target.painter.runtimeType.toString()),
        ),
      if (target.foregroundPainter != null)
        (
          icon: Icons.brush,
          subtitle: 'fg painter',
          child: Text(target.foregroundPainter.runtimeType.toString()),
        ),
    ];

List<PropSpec> flexProps(RenderFlex target) => [
      (
        icon: Icons.swap_horiz,
        subtitle: 'direction',
        child: Text(target.direction.name),
      ),
      (
        icon: Icons.space_bar,
        subtitle: 'main axis',
        child: Text(target.mainAxisAlignment.name),
      ),
      (
        icon: Icons.vertical_align_center,
        subtitle: 'cross axis',
        child: Text(target.crossAxisAlignment.name),
      ),
      if (target.mainAxisSize != MainAxisSize.max)
        (
          icon: Icons.compress,
          subtitle: 'main size',
          child: Text(target.mainAxisSize.name),
        ),
      if (target.verticalDirection != VerticalDirection.down)
        (
          icon: Icons.swap_vert,
          subtitle: 'vertical dir',
          child: Text(target.verticalDirection.name),
        ),
    ];

List<PropSpec> imageProps(RenderImage target, {int decimalPlaces = 1}) {
  final provider = resolveImageProvider(target);
  final rawImage = target.image;
  return [
    if (provider != null)
      (
        icon: Icons.image,
        subtitle: 'source',
        child: EllipsizedText(describeImageProvider(provider)),
      ),
    if (rawImage != null)
      (
        icon: Icons.photo_size_select_large,
        subtitle: 'raw px',
        child: Text('${rawImage.width}×${rawImage.height}'),
      ),
    if (target.fit != null)
      (
        icon: Icons.fit_screen,
        subtitle: 'fit',
        child: Text(target.fit!.name),
      ),
    (
      icon: Icons.crop_free,
      subtitle: 'alignment',
      child: EllipsizedText(describeAlignment(target.alignment)),
    ),
    if (target.width != null)
      (
        icon: Icons.swap_horiz,
        subtitle: 'width',
        child: Text(_fmt(target.width!, decimalPlaces)),
      ),
    if (target.height != null)
      (
        icon: Icons.swap_vert,
        subtitle: 'height',
        child: Text(_fmt(target.height!, decimalPlaces)),
      ),
    if (target.repeat != ImageRepeat.noRepeat)
      (
        icon: Icons.repeat,
        subtitle: 'repeat',
        child: Text(target.repeat.name),
      ),
    if (target.color != null)
      (
        icon: Icons.color_lens,
        subtitle: 'color tint',
        child: ColorHexChip(target.color!),
      ),
  ];
}

List<PropSpec> opacityProps(RenderOpacity target, {int decimalPlaces = 1}) => [
      (
        icon: Icons.opacity,
        subtitle: 'opacity',
        child: Text(_fmt(target.opacity, decimalPlaces)),
      ),
    ];

List<PropSpec> animatedOpacityProps(
  RenderAnimatedOpacity target, {
  int decimalPlaces = 1,
}) =>
    [
      (
        icon: Icons.opacity,
        subtitle: 'opacity',
        child: Text(_fmt(target.opacity.value, decimalPlaces)),
      ),
    ];

List<PropSpec> _physicalFinishProps({
  required Color color,
  required double elevation,
  required Color shadowColor,
  int decimalPlaces = 1,
}) =>
    [
      (icon: Icons.palette, subtitle: 'color', child: ColorHexChip(color)),
      if (elevation > 0)
        (
          icon: Icons.layers,
          subtitle: 'elevation',
          child: Text(_fmt(elevation, decimalPlaces)),
        ),
      (
        icon: Icons.blur_on,
        subtitle: 'shadow color',
        child: ColorHexChip(shadowColor),
      ),
    ];

List<PropSpec> physicalShapeProps(
  RenderPhysicalShape target, {
  int decimalPlaces = 1,
}) =>
    [
      ..._physicalFinishProps(
        color: target.color,
        elevation: target.elevation,
        shadowColor: target.shadowColor,
        decimalPlaces: decimalPlaces,
      ),
      ..._clipperProps(target.clipper, decimalPlaces: decimalPlaces),
    ];

List<PropSpec> physicalModelProps(
  RenderPhysicalModel target, {
  int decimalPlaces = 1,
}) =>
    [
      ..._physicalFinishProps(
        color: target.color,
        elevation: target.elevation,
        shadowColor: target.shadowColor,
        decimalPlaces: decimalPlaces,
      ),
      (
        icon: Icons.circle_outlined,
        subtitle: 'shape',
        child: Text(target.shape.name),
      ),
      if (formatBorderRadius(
        target.borderRadius ?? BorderRadius.zero,
        decimalPlaces: decimalPlaces,
      )
          case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: buildBorderRadiusChild(
            target.borderRadius ?? BorderRadius.zero,
            decimalPlaces: decimalPlaces,
          ),
        ),
    ];

List<PropSpec> fittedBoxProps(RenderFittedBox target) => [
      (
        icon: Icons.fit_screen,
        subtitle: 'fit',
        child: Text(target.fit.name),
      ),
      if (target.alignment != Alignment.center)
        (
          icon: Icons.crop_free,
          subtitle: 'alignment',
          child: EllipsizedText(describeAlignment(target.alignment)),
        ),
    ];

List<PropSpec> aspectRatioProps(
  RenderAspectRatio target, {
  int decimalPlaces = 1,
}) =>
    [
      (
        icon: Icons.aspect_ratio,
        subtitle: 'aspect ratio',
        child: Text(_fmt(target.aspectRatio, decimalPlaces)),
      ),
    ];

List<PropSpec> transformProps(
  RenderTransform target, {
  int decimalPlaces = 1,
}) {
  final matrix = Matrix4.identity();
  final child = target.child;
  if (child != null) target.applyPaintTransform(child, matrix);
  final m = matrix.storage;
  final tx = m[12];
  final ty = m[13];
  final scaleX = math.sqrt(m[0] * m[0] + m[1] * m[1]);
  final scaleY = math.sqrt(m[4] * m[4] + m[5] * m[5]);
  final rotationDeg = math.atan2(m[1], m[0]) * 180 / math.pi;
  String f(double v) => _fmt(v, decimalPlaces);

  return [
    if (tx.abs() > _kTransformEpsilon || ty.abs() > _kTransformEpsilon)
      (
        icon: Icons.open_with,
        subtitle: 'translate',
        child: OffsetValue(dx: f(tx), dy: f(ty)),
      ),
    if ((scaleX - 1).abs() > _kTransformEpsilon ||
        (scaleY - 1).abs() > _kTransformEpsilon)
      (
        icon: Icons.zoom_out_map,
        subtitle: 'scale',
        child: Text(
          scaleX == scaleY ? f(scaleX) : '${f(scaleX)}, ${f(scaleY)}',
        ),
      ),
    if (rotationDeg.abs() > _kRotationEpsilon)
      (
        icon: Icons.rotate_right,
        subtitle: 'rotation°',
        child: Text(f(rotationDeg)),
      ),
    if (target.origin != null)
      (
        icon: Icons.place,
        subtitle: 'origin',
        child: OffsetValue(
          dx: _fmt(target.origin!.dx, decimalPlaces),
          dy: _fmt(target.origin!.dy, decimalPlaces),
        ),
      ),
    if (target.alignment != null)
      (
        icon: Icons.crop_free,
        subtitle: 'alignment',
        child: EllipsizedText(describeAlignment(target.alignment!)),
      ),
    if (!target.transformHitTests)
      (
        icon: Icons.touch_app,
        subtitle: 'hit tests',
        child: const Text('untransformed'),
      ),
  ];
}

List<PropSpec> backdropFilterProps(RenderBackdropFilter target) => [
      (
        icon: Icons.blur_on,
        subtitle: 'filter',
        // `filter` is deprecated in Flutter >=3.40 in favour of `filterConfig`,
        // but the pinned CI Flutter (3.32.6) only exposes `filter`.
        // ignore: deprecated_member_use
        child: EllipsizedText(describeImageFilter(target.filter)),
      ),
      if (target.blendMode != BlendMode.srcOver)
        (
          icon: Icons.layers,
          subtitle: 'blend mode',
          child: Text(target.blendMode.name),
        ),
    ];

List<PropSpec> editableProps(RenderEditable target) => [
      (
        icon: Icons.format_align_left,
        subtitle: 'text align',
        child: Text(target.textAlign.name),
      ),
      if (target.cursorColor != null)
        (
          icon: Icons.text_fields,
          subtitle: 'cursor',
          child: ColorHexChip(target.cursorColor!),
        ),
      if (target.selectionColor != null)
        (
          icon: Icons.select_all,
          subtitle: 'selection',
          child: ColorHexChip(target.selectionColor!),
        ),
      if (target.obscureText)
        (
          icon: Icons.password,
          subtitle: 'obscure',
          child: const Text('on'),
        ),
      if (target.readOnly)
        (
          icon: Icons.lock_outline,
          subtitle: 'read only',
          child: const Text('on'),
        ),
      if (target.maxLines != 1)
        (
          icon: Icons.format_list_numbered,
          subtitle: 'max lines',
          child: Text(target.maxLines?.toString() ?? '∞'),
        ),
      if (target.minLines != null)
        (
          icon: Icons.format_list_numbered,
          subtitle: 'min lines',
          child: Text(target.minLines.toString()),
        ),
      if (target.enableInteractiveSelection == false)
        (
          icon: Icons.select_all,
          subtitle: 'interactive sel.',
          child: const Text('off'),
        ),
    ];

// ─── Registry-driven dispatcher ──────────────────────────────────────────────
//
// Single source of truth for both [typeProps] and [hasTypeProps]. Add one
// entry per supported render-box; both functions pick it up automatically.
//
// `wrapper: true` means the box may legitimately appear as a same-size proxy
// in the parent chain. Layout-shaping types (Stack, Flex, Wrap, Image,
// Editable, Paragraph) own their geometry and are not wrappers.

typedef _Rule = ({
  bool Function(RenderBox) match,
  List<PropSpec> Function(RenderBox, int decimalPlaces) build,
  bool wrapper,
});

_Rule _rule<T extends RenderBox>(
  List<PropSpec> Function(T, int decimalPlaces) build, {
  required bool wrapper,
  bool Function(T)? where,
}) =>
    (
      match: (b) => b is T && (where == null || where(b)),
      build: (b, dp) => build(b as T, dp),
      wrapper: wrapper,
    );

final List<_Rule> _propsRules = [
  _rule<RenderStack>((b, _) => stackProps(b), wrapper: false),
  _rule<RenderFlex>((b, _) => flexProps(b), wrapper: false),
  _rule<RenderWrap>(
    (b, dp) => wrapProps(b, decimalPlaces: dp),
    wrapper: false,
  ),
  _rule<RenderImage>(
    (b, dp) => imageProps(b, decimalPlaces: dp),
    wrapper: false,
  ),
  _rule<RenderEditable>((b, _) => editableProps(b), wrapper: false),
  _rule<RenderOpacity>(
    (b, dp) => opacityProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderAnimatedOpacity>(
    (b, dp) => animatedOpacityProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderPhysicalShape>(
    (b, dp) => physicalShapeProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderPhysicalModel>(
    (b, dp) => physicalModelProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderClipRRect>(
    (b, dp) => clipRRectProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderClipRSuperellipse>(
    (b, dp) => clipRSuperellipseProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderClipRect>((b, _) => clipRectProps(b), wrapper: true),
  _rule<RenderClipOval>((b, _) => clipOvalProps(b), wrapper: true),
  _rule<RenderClipPath>(
    (b, dp) => clipPathProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  // Skip in the wrapper chain when neither painter is set — the section
  // would render as an empty header.
  _rule<RenderCustomPaint>(
    (b, _) => customPaintProps(b),
    wrapper: true,
    where: (b) => b.painter != null || b.foregroundPainter != null,
  ),
  _rule<RenderFittedBox>((b, _) => fittedBoxProps(b), wrapper: true),
  _rule<RenderAspectRatio>(
    (b, dp) => aspectRatioProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderTransform>(
    (b, dp) => transformProps(b, decimalPlaces: dp),
    wrapper: true,
  ),
  _rule<RenderBackdropFilter>(
    (b, _) => backdropFilterProps(b),
    wrapper: true,
  ),
];

/// Type-specific props for any [RenderBox]. Returns an empty list when no
/// rule matches.
///
/// [RenderParagraph] is intentionally absent: `box_info_panel_widget.dart`
/// renders paragraphs through dedicated `text` / `typography` sections, so
/// dispatching them through the generic `type` section would duplicate
/// output.
List<PropSpec> typeProps(RenderBox target, {int decimalPlaces = 1}) => [
      for (final rule in _propsRules)
        if (rule.match(target)) ...rule.build(target, decimalPlaces),
    ];

/// Whether [box] is worth surfacing as a same-size wrapper in the parent
/// chain. Driven by the same registry as [typeProps].
bool hasTypeProps(RenderBox box) =>
    _propsRules.any((r) => r.wrapper && r.match(box));
