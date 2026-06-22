import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/widgets/components/element_resolver.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';
import 'package:ispect_layout/src/widgets/components/value_descriptors.dart';

String _fmt(double v, int decimalPlaces) =>
    formatInspectorDouble(v, decimalPlaces: decimalPlaces);

/// How far up the element tree the walk may climb to reach the [Image] that
/// owns a [RawImage]. Generous enough to clear the wrappers ([Semantics],
/// `frameBuilder`) an [Image] inserts above its render object, bounded so an
/// unrelated ancestor [Image] can't be mistaken for the owner.
const _kImageAncestorWalkLimit = 16;

/// Recovers the [ImageProvider] that produced a [RenderImage]. Release-safe.
///
/// A [RenderImage]'s owning widget is the [RawImage] leaf, which holds the
/// decoded `ui.Image` but not the [ImageProvider] — that lives on the [Image]
/// widget that built the [RawImage]. So the owning element is located via
/// [elementForRenderObject], then it and a bounded number of its ancestors are
/// checked for the nearest [Image].
ImageProvider? resolveImageProvider(RenderImage target) {
  final element = elementForRenderObject(target);
  if (element == null) return null;

  final ownWidget = element.widget;
  if (ownWidget is Image) return ownWidget.image;

  ImageProvider? provider;
  var depth = 0;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Image) {
      provider = widget.image;
      return false;
    }
    return ++depth < _kImageAncestorWalkLimit;
  });
  return provider;
}

/// Human-readable source of a [RenderImage]: the URL, asset name, or file path.
///
/// Prefers [RenderImage.debugImageLabel] — the [Image] widget forwards the
/// provider's label here unconditionally, so it is the cheapest path when the
/// image has decoded. Falls back to resolving the provider from the element
/// tree. Returns `null` when neither is available (e.g. an undecoded image).
String? imageSourceLabel(RenderImage target) {
  final label = target.debugImageLabel;
  if (label != null && label.isNotEmpty) return label;
  final provider = resolveImageProvider(target);
  return provider == null ? null : describeImageProvider(provider);
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

String _rawPixelLabel(int width, int height) =>
    // ~4 bytes/pixel (RGBA) estimates the decoded footprint, not the file size.
    '$width×$height · ~${_formatBytes(width * height * 4)}';

String _rectLabel(Rect r, int decimalPlaces) =>
    'L${_fmt(r.left, decimalPlaces)} T${_fmt(r.top, decimalPlaces)} '
    'R${_fmt(r.right, decimalPlaces)} B${_fmt(r.bottom, decimalPlaces)}';

/// Inspector props for a [RenderImage] — `Image.network` / `.asset` /
/// `.memory` / `.file` and any other raster image. Defaults are suppressed so
/// only intentional overrides surface.
List<PropSpec> imageProps(RenderImage target, {int decimalPlaces = 1}) {
  final source = imageSourceLabel(target);
  final rawImage = target.image;
  return [
    if (source != null)
      (
        icon: Icons.image,
        subtitle: 'source',
        child: EllipsizedText(source),
      ),
    if (rawImage != null)
      (
        icon: Icons.photo_size_select_large,
        subtitle: 'raw px',
        child: Text(_rawPixelLabel(rawImage.width, rawImage.height)),
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
    if (target.scale != 1.0)
      (
        icon: Icons.zoom_in,
        subtitle: 'scale',
        child: Text('${_fmt(target.scale, decimalPlaces)}×'),
      ),
    // Image widget defaults to FilterQuality.medium; surface only overrides.
    if (target.filterQuality != FilterQuality.medium)
      (
        icon: Icons.tune,
        subtitle: 'filter quality',
        child: Text(target.filterQuality.name),
      ),
    if (target.repeat != ImageRepeat.noRepeat)
      (
        icon: Icons.repeat,
        subtitle: 'repeat',
        child: Text(target.repeat.name),
      ),
    if (target.centerSlice != null)
      (
        icon: Icons.crop_din,
        subtitle: 'center slice',
        child: EllipsizedText(_rectLabel(target.centerSlice!, decimalPlaces)),
      ),
    if (target.color != null)
      (
        icon: Icons.color_lens,
        subtitle: 'color tint',
        child: ColorHexChip(target.color!),
      ),
    if (target.color != null && target.colorBlendMode != null)
      (
        icon: Icons.layers,
        subtitle: 'blend mode',
        child: Text(target.colorBlendMode!.name),
      ),
    if (target.invertColors)
      (
        icon: Icons.invert_colors,
        subtitle: 'invert colors',
        child: const Text('on'),
      ),
    if (target.matchTextDirection)
      (
        icon: Icons.format_textdirection_l_to_r,
        subtitle: 'match text dir',
        child: const Text('on'),
      ),
    if (target.isAntiAlias)
      (
        icon: Icons.deblur,
        subtitle: 'anti-alias',
        child: const Text('on'),
      ),
  ];
}
