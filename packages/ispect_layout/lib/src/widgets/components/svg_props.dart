import 'package:flutter/material.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/widgets/components/element_resolver.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';
import 'package:ispect_layout/src/widgets/components/value_descriptors.dart';

// flutter_svg paints through private render objects (`vector_graphics`), so
// there is no public render type to match on. Instead the `SvgPicture` *widget*
// is recovered from the live element tree — identified only by its runtime type
// name — and its public fields are read by duck typing. Every read is guarded:
// an unknown shape degrades to an empty section rather than throwing, keeping
// the inspector resilient across flutter_svg versions and free of a dependency
// on the package.

String _fmt(double v, int decimalPlaces) =>
    formatInspectorDouble(v, decimalPlaces: decimalPlaces);

const _kSvgPictureType = 'SvgPicture';

/// How far up the element tree the walk may climb to reach the `SvgPicture`
/// that owns a vector-graphics render object. Bounded so an unrelated ancestor
/// can't be mistaken for the owner.
const _kSvgAncestorWalkLimit = 16;

/// Recovers a flutter_svg `SvgPicture` widget that owns (or wraps the owner of)
/// [target], without depending on the package. Release-safe: the owning element
/// is located via [elementForRenderObject], then it and a bounded number of its
/// ancestors are matched by runtime type name. Returns `null` when none is
/// found within the walk bound.
Widget? resolveSvgPicture(RenderBox target) {
  final element = elementForRenderObject(target);
  if (element == null) return null;

  bool isSvg(Widget w) => w.runtimeType.toString() == _kSvgPictureType;
  if (isSvg(element.widget)) return element.widget;

  Widget? found;
  var depth = 0;
  element.visitAncestorElements((ancestor) {
    if (isSvg(ancestor.widget)) {
      found = ancestor.widget;
      return false;
    }
    return ++depth < _kSvgAncestorWalkLimit;
  });
  return found;
}

/// Reads a duck-typed field, returning `null` on a type mismatch, a missing
/// member, or a null value — so an unexpected flutter_svg shape is skipped
/// rather than surfaced or thrown.
T? _svgField<T>(T Function() read) {
  try {
    return read();
  } catch (_) {
    return null;
  }
}

/// Best-effort description of an `SvgPicture.bytesLoader` source: asset name,
/// URL, or file path. Inline string/byte loaders intentionally show only their
/// type name — never the raw payload.
String? _svgSourceLabel(Object loader) {
  final dyn = loader as dynamic;
  final assetName = _svgField<String>(() => dyn.assetName as String);
  if (assetName != null) {
    final pkg = _svgField<String>(() => dyn.packageName as String);
    return pkg == null ? assetName : 'packages/$pkg/$assetName';
  }
  final url = _svgField<String>(() => dyn.url as String);
  if (url != null) return url;
  final filePath =
      _svgField<String>(() => (dyn.file as dynamic).path as String);
  if (filePath != null) return filePath;
  return loader.runtimeType.toString();
}

/// Props for a flutter_svg `SvgPicture` widget recovered by [resolveSvgPicture].
/// All fields are read defensively; an unrecognised widget yields `[]`.
List<PropSpec> svgProps(Widget svg, {int decimalPlaces = 1}) {
  final dyn = svg as dynamic;
  final props = <PropSpec>[];

  final loader = _svgField<Object>(() => dyn.bytesLoader as Object);
  if (loader != null) {
    final source = _svgSourceLabel(loader);
    if (source != null) {
      props.add(
        (icon: Icons.image, subtitle: 'source', child: EllipsizedText(source)),
      );
    }
  }

  final fit = _svgField<BoxFit>(() => dyn.fit as BoxFit);
  if (fit != null) {
    props.add(
      (icon: Icons.fit_screen, subtitle: 'fit', child: Text(fit.name)),
    );
  }

  final alignment = _svgField<AlignmentGeometry>(
    () => dyn.alignment as AlignmentGeometry,
  );
  if (alignment != null && alignment != Alignment.center) {
    props.add(
      (
        icon: Icons.crop_free,
        subtitle: 'alignment',
        child: EllipsizedText(describeAlignment(alignment)),
      ),
    );
  }

  final colorFilter =
      _svgField<ColorFilter>(() => dyn.colorFilter as ColorFilter);
  if (colorFilter != null) {
    // ColorFilter's debug toString() ('ColorFilter.mode(...)') is enough for
    // the inspector and, unlike `describeColorFilter`, never probes dart:ui
    // private fields — so it can't throw across the library boundary.
    props.add(
      (
        icon: Icons.filter_b_and_w,
        subtitle: 'color filter',
        child: EllipsizedText(colorFilter.toString()),
      ),
    );
  }

  final width = _svgField<double>(() => dyn.width as double);
  if (width != null) {
    props.add(
      (
        icon: Icons.swap_horiz,
        subtitle: 'width',
        child: Text(_fmt(width, decimalPlaces)),
      ),
    );
  }

  final height = _svgField<double>(() => dyn.height as double);
  if (height != null) {
    props.add(
      (
        icon: Icons.swap_vert,
        subtitle: 'height',
        child: Text(_fmt(height, decimalPlaces)),
      ),
    );
  }

  return props;
}
