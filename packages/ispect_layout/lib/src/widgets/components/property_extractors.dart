import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';

// ─── Format helpers ──────────────────────────────────────────────────────────

String _fmt(double v, int decimalPlaces) =>
    formatInspectorDouble(v, decimalPlaces: decimalPlaces);

String _fmtOffset(Offset o, int decimalPlaces) =>
    formatInspectorOffset(o, decimalPlaces: decimalPlaces);

/// Formats a single [Radius], collapsing to a scalar when x == y.
String formatRadius(
  Radius r, {
  int decimalPlaces = 1,
}) =>
    r.x == r.y
        ? _fmt(r.x, decimalPlaces)
        : '${_fmt(r.x, decimalPlaces)}×${_fmt(r.y, decimalPlaces)}';

/// Formats a [BorderRadiusGeometry], collapsing uniform values and showing
/// elliptical `(x×y)` radii only when x != y.
///
/// Returns `null` when the radius is zero — callers should skip the chip.
({String label, String value})? formatBorderRadius(
  BorderRadiusGeometry geometry, {
  int decimalPlaces = 1,
}) {
  final r = geometry.resolve(TextDirection.ltr);
  if (r == BorderRadius.zero) return null;
  final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
  if (corners.every((c) => c == corners.first)) {
    return (
      label: 'border radius',
      value: formatRadius(corners.first, decimalPlaces: decimalPlaces),
    );
  }
  return (
    label: 'radius TL/TR/BR/BL',
    value: corners
        .map((corner) => formatRadius(corner, decimalPlaces: decimalPlaces))
        .join(', '),
  );
}

String describeShapeBorder(ShapeBorder shape) => shape.runtimeType.toString();

// ─── Release-safe value formatters ───────────────────────────────────────────
//
// Flutter's AOT release build strips `toString()` overrides on several
// painting / dart:ui types (FontWeight, TextDecoration, AlignmentGeometry,
// SystemTextScaler, ImageFilter, ColorFilter, …), falling back to
// `Instance of '<TypeName>'`. The helpers below read public fields (or
// safely peek at private discriminators) so labels stay readable.

String describeAlignment(AlignmentGeometry alignment) {
  String fmt(double v) => v.toStringAsFixed(1);
  if (alignment is Alignment) {
    return switch ((alignment.x, alignment.y)) {
      (-1.0, -1.0) => 'topLeft',
      (0.0, -1.0) => 'topCenter',
      (1.0, -1.0) => 'topRight',
      (-1.0, 0.0) => 'centerLeft',
      (0.0, 0.0) => 'center',
      (1.0, 0.0) => 'centerRight',
      (-1.0, 1.0) => 'bottomLeft',
      (0.0, 1.0) => 'bottomCenter',
      (1.0, 1.0) => 'bottomRight',
      _ => '(${fmt(alignment.x)}, ${fmt(alignment.y)})',
    };
  }
  if (alignment is AlignmentDirectional) {
    return switch ((alignment.start, alignment.y)) {
      (-1.0, -1.0) => 'topStart',
      (0.0, -1.0) => 'topCenter',
      (1.0, -1.0) => 'topEnd',
      (-1.0, 0.0) => 'centerStart',
      (0.0, 0.0) => 'center',
      (1.0, 0.0) => 'centerEnd',
      (-1.0, 1.0) => 'bottomStart',
      (0.0, 1.0) => 'bottomCenter',
      (1.0, 1.0) => 'bottomEnd',
      _ => 'directional(${fmt(alignment.start)}, ${fmt(alignment.y)})',
    };
  }
  return alignment.runtimeType.toString();
}

String describeFontWeight(FontWeight weight) => 'w${weight.value}';

String describeFontStyle(FontStyle style) => style.name;

String describeTextDecoration(TextDecoration decoration) {
  final parts = <String>[
    if (decoration.contains(TextDecoration.underline)) 'underline',
    if (decoration.contains(TextDecoration.overline)) 'overline',
    if (decoration.contains(TextDecoration.lineThrough)) 'lineThrough',
  ];
  return parts.isEmpty ? 'none' : parts.join(' + ');
}

/// `textScaleFactor` is deprecated but is the only public field shared by
/// all [TextScaler] subclasses (linear, system, clamped).
String describeTextScaler(TextScaler scaler) {
  if (identical(scaler, TextScaler.noScaling)) return 'no scaling';
  // ignore: deprecated_member_use
  final factor = scaler.textScaleFactor;
  if (factor == 1.0) return 'no scaling';
  return '${factor.toStringAsFixed(2)}×';
}

/// [ImageFilter] subclasses (`_GaussianBlurImageFilter`, `_MatrixImageFilter`,
/// …) are private, so when `toString()` is stripped we fall back to matching
/// substrings of the runtime type name.
String describeImageFilter(ImageFilter filter) {
  final raw = filter.toString();
  if (!raw.startsWith("Instance of '")) return raw;
  final type = filter.runtimeType.toString();
  if (type.contains('Blur')) return 'ImageFilter.blur';
  if (type.contains('Dilate')) return 'ImageFilter.dilate';
  if (type.contains('Erode')) return 'ImageFilter.erode';
  if (type.contains('Matrix')) return 'ImageFilter.matrix';
  if (type.contains('Compose')) return 'ImageFilter.compose';
  if (type.contains('Shader')) return 'ImageFilter.shader';
  return type;
}

BorderRadiusGeometry? extractShapeBorderRadius(ShapeBorder shape) {
  if (shape is RoundedRectangleBorder) return shape.borderRadius;
  if (shape is BeveledRectangleBorder) return shape.borderRadius;
  if (shape is ContinuousRectangleBorder) return shape.borderRadius;
  return null;
}

List<PropSpec> shapeBorderProps(
  ShapeBorder shape, {
  int decimalPlaces = 1,
}) =>
    [
      (
        icon: Icons.circle_outlined,
        subtitle: 'shape',
        child: Text(describeShapeBorder(shape)),
      ),
      if (extractShapeBorderRadius(shape) case final borderRadius?)
        if (formatBorderRadius(
          borderRadius,
          decimalPlaces: decimalPlaces,
        )
            case final br?)
          (
            icon: Icons.rounded_corner,
            subtitle: br.label,
            child: Text(br.value),
          ),
    ];

/// Best-effort short description of an [ImageProvider]: URL for network
/// images, asset name for bundled assets, file path for files, else runtime
/// type. Recurses into [ResizeImage].
String describeImageProvider(ImageProvider provider) {
  if (provider is NetworkImage) return provider.url;
  if (provider is AssetImage) return provider.assetName;
  if (provider is ExactAssetImage) return provider.assetName;
  if (provider is FileImage) return provider.file.path;
  if (provider is MemoryImage) return 'MemoryImage(${provider.bytes.length}B)';
  if (provider is ResizeImage) {
    return '${provider.width ?? '?'}×${provider.height ?? '?'} '
        '${describeImageProvider(provider.imageProvider)}';
  }
  return provider.runtimeType.toString();
}

/// [ColorFilter] exposes no public accessors, so in debug we parse
/// `toString()`, and in release we peek at the private `_type` / `_blendMode`
/// / `_color` fields via dynamic dispatch. The `_type` constants come from
/// dart:ui (`_kTypeMode = 1`, `_kTypeMatrix = 2`,
/// `_kTypeLinearToSrgbGamma = 3`, `_kTypeSrgbToLinearGamma = 4`).
String describeColorFilter(ColorFilter f) {
  final s = f.toString();
  if (!s.startsWith("Instance of '")) {
    final blend = RegExp(r'BlendMode\.(\w+)').firstMatch(s);
    if (s.startsWith('ColorFilter.mode') && blend != null) {
      return 'mode · ${blend.group(1)}';
    }
    return s.replaceFirst('ColorFilter.', '');
  }
  return _describeColorFilterViaPrivateFields(f);
}

String _describeColorFilterViaPrivateFields(ColorFilter f) {
  try {
    final dyn = f as dynamic;
    final type = dyn._type as int;
    switch (type) {
      case 1: // mode
        final blend = dyn._blendMode as BlendMode?;
        final color = dyn._color as Color?;
        if (blend != null && color != null) {
          final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
          return 'mode · ${blend.name} · #$hex';
        }
        if (blend != null) return 'mode · ${blend.name}';
        return 'mode';
      case 2:
        return 'matrix';
      case 3:
        return 'linearToSrgbGamma';
      case 4:
        return 'srgbToLinearGamma';
      default:
        return 'ColorFilter';
    }
  } catch (_) {
    return 'ColorFilter';
  }
}

/// Flattens all [TextStyle]s found across an [InlineSpan] tree in traversal
/// order. Used to show each distinct span style as its own subsection.
List<TextStyle> extractTextStyles(InlineSpan span, [List<TextStyle>? out]) {
  out ??= [];
  if (span.style != null) out.add(span.style!);
  if (span is TextSpan && span.children != null) {
    for (final c in span.children!) {
      extractTextStyles(c, out);
    }
  }
  return out;
}

/// Truncated, newline-escaped plain-text preview of an [InlineSpan]. Caps at
/// 80 visible characters; appends `…` when the underlying text is longer.
String previewText(InlineSpan span) {
  final buf = StringBuffer();
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null) buf.write(child.text);
    return buf.length < 120;
  });
  final raw = buf.toString().replaceAll('\n', '⏎');
  return raw.length <= 80 ? raw : '${raw.substring(0, 80)}…';
}

/// Recovers the [ImageProvider] that produced a [RenderImage] via its
/// `debugCreator`. Only works in debug builds where Flutter populates
/// [RenderObject.debugCreator]; returns `null` in release/profile.
ImageProvider? resolveImageProvider(RenderImage target) {
  if (!kDebugMode) return null;
  final creator = target.debugCreator;
  if (creator is! DebugCreator) return null;
  final widget = creator.element.widget;
  if (widget is Image) return widget.image;
  return null;
}

// ─── Property extractors ─────────────────────────────────────────────────────

List<PropSpec> constraintsProps(
  BoxConstraints c, {
  int decimalPlaces = 1,
}) {
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

List<PropSpec> spanProps(
  TextStyle style, {
  int decimalPlaces = 1,
}) =>
    [
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

List<PropSpec> decorationProps(
  BoxDecoration d, {
  int decimalPlaces = 1,
}) =>
    [
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
          child: Text(br.value),
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

List<PropSpec> _borderProps(
  BoxBorder border, {
  int decimalPlaces = 1,
}) {
  if (border is! Border) {
    return [
      (
        icon: Icons.border_all,
        subtitle: 'border',
        child: Text(border.runtimeType.toString()),
      ),
    ];
  }

  final sides = [border.top, border.right, border.bottom, border.left];
  final widths = sides.map((s) => s.width).toSet();
  final activeSides = sides.where((s) => s.width > 0).toList();
  final colors = activeSides.map((s) => s.color).toSet();

  Widget sideChild(Color color, String wStr) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [ColorHexChip(color), Text(wStr)],
      );

  // Uniform border — single chip
  if (colors.length == 1 && activeSides.isNotEmpty) {
    final wStr = widths.length == 1
        ? 'w:${_fmt(widths.first, decimalPlaces)}'
        : 'w:${sides.map((s) => _fmt(s.width, decimalPlaces)).join('/')}';
    return [
      (
        icon: Icons.border_all,
        subtitle: 'border',
        child: sideChild(colors.first, wStr),
      ),
    ];
  }

  // Non-uniform border — one chip per active side
  const sideLabels = ['T', 'R', 'B', 'L'];
  return [
    for (var i = 0; i < sides.length; i++)
      if (sides[i].width > 0)
        (
          icon: Icons.border_all,
          subtitle: 'border ${sideLabels[i]}',
          child: sideChild(
            sides[i].color,
            'w:${_fmt(sides[i].width, decimalPlaces)}',
          ),
        ),
  ];
}

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

List<PropSpec> wrapProps(
  RenderWrap target, {
  int decimalPlaces = 1,
}) =>
    [
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

PropSpec? _clipBehaviorProp(Clip clipBehavior) => clipBehavior == Clip.none
    ? null
    : (
        icon: Icons.crop,
        subtitle: 'clip behavior',
        child: Text(clipBehavior.name),
      );

List<PropSpec> clipRRectProps(
  RenderClipRRect target, {
  int decimalPlaces = 1,
}) =>
    [
      if (formatBorderRadius(
        target.borderRadius,
        decimalPlaces: decimalPlaces,
      )
          case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: Text(br.value),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipRSuperellipseProps(
  RenderClipRSuperellipse target, {
  int decimalPlaces = 1,
}) =>
    [
      if (formatBorderRadius(
        target.borderRadius,
        decimalPlaces: decimalPlaces,
      )
          case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: Text(br.value),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipRectProps(RenderClipRect target) =>
    _genericClipProps(target.clipper?.runtimeType, target.clipBehavior);

List<PropSpec> clipOvalProps(RenderClipOval target) =>
    _genericClipProps(target.clipper?.runtimeType, target.clipBehavior);

List<PropSpec> clipPathProps(
  RenderClipPath target, {
  int decimalPlaces = 1,
}) =>
    [
      if (target.clipper case final ShapeBorderClipper clipper)
        ...shapeBorderProps(clipper.shape, decimalPlaces: decimalPlaces)
      else if (target.clipper != null)
        (
          icon: Icons.brush,
          subtitle: 'clipper',
          child: Text(target.clipper.runtimeType.toString()),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> _genericClipProps(Type? clipperType, Clip clipBehavior) => [
      if (clipperType != null)
        (
          icon: Icons.brush,
          subtitle: 'clipper',
          child: Text(clipperType.toString()),
        ),
      if (_clipBehaviorProp(clipBehavior) case final c?) c,
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

List<PropSpec> imageProps(
  RenderImage target, {
  int decimalPlaces = 1,
}) {
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

List<PropSpec> opacityProps(
  RenderOpacity target, {
  int decimalPlaces = 1,
}) =>
    [
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
      if (target.clipper case final ShapeBorderClipper clipper)
        ...shapeBorderProps(clipper.shape, decimalPlaces: decimalPlaces)
      else
        (
          icon: Icons.brush,
          subtitle: 'clipper',
          child: Text(target.clipper.runtimeType.toString()),
        ),
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
          child: Text(br.value),
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
    if (tx.abs() > 0.001 || ty.abs() > 0.001)
      (
        icon: Icons.open_with,
        subtitle: 'translate',
        child: Text('(${f(tx)}, ${f(ty)})'),
      ),
    if ((scaleX - 1).abs() > 0.001 || (scaleY - 1).abs() > 0.001)
      (
        icon: Icons.zoom_out_map,
        subtitle: 'scale',
        child: Text(
          scaleX == scaleY ? f(scaleX) : '${f(scaleX)}, ${f(scaleY)}',
        ),
      ),
    if (rotationDeg.abs() > 0.01)
      (
        icon: Icons.rotate_right,
        subtitle: 'rotation°',
        child: Text(f(rotationDeg)),
      ),
    if (target.origin != null)
      (
        icon: Icons.place,
        subtitle: 'origin',
        child: EllipsizedText(_fmtOffset(target.origin!, decimalPlaces)),
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

/// Type-specific props for any [RenderBox]. Returns an empty list when the
/// type has no known extractor.
List<PropSpec> typeProps(
  RenderBox target, {
  int decimalPlaces = 1,
}) =>
    [
      if (target is RenderStack) ...stackProps(target),
      if (target is RenderFlex) ...flexProps(target),
      if (target is RenderWrap)
        ...wrapProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderImage)
        ...imageProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderOpacity)
        ...opacityProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderAnimatedOpacity)
        ...animatedOpacityProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderPhysicalShape)
        ...physicalShapeProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderPhysicalModel)
        ...physicalModelProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderClipRRect)
        ...clipRRectProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderClipRSuperellipse)
        ...clipRSuperellipseProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderClipRect) ...clipRectProps(target),
      if (target is RenderClipOval) ...clipOvalProps(target),
      if (target is RenderClipPath)
        ...clipPathProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderCustomPaint) ...customPaintProps(target),
      if (target is RenderFittedBox) ...fittedBoxProps(target),
      if (target is RenderAspectRatio)
        ...aspectRatioProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderTransform)
        ...transformProps(target, decimalPlaces: decimalPlaces),
      if (target is RenderBackdropFilter) ...backdropFilterProps(target),
      if (target is RenderEditable) ...editableProps(target),
    ];

/// Whether [typeProps] produces something for a type. Used to filter
/// same-size ancestors in the parent chain when surfacing wrapper sections.
///
/// Narrower than [typeProps]'s full dispatcher: layout-shaping types
/// (Stack, Flex, Wrap, Image, Editable, Paragraph) never act as
/// same-size proxy wrappers around an inner target, so they are excluded.
bool hasTypeProps(RenderBox box) =>
    box is RenderTransform ||
    box is RenderBackdropFilter ||
    box is RenderClipRect ||
    box is RenderClipRRect ||
    box is RenderClipRSuperellipse ||
    box is RenderClipOval ||
    box is RenderClipPath ||
    box is RenderFittedBox ||
    box is RenderAspectRatio ||
    box is RenderOpacity ||
    box is RenderAnimatedOpacity ||
    box is RenderPhysicalShape ||
    box is RenderPhysicalModel ||
    box is RenderCustomPaint;
