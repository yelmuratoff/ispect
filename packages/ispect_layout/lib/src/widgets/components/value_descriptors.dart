import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ispect_layout/src/number_format.dart';

// ─── Internal numeric helpers (re-exported via formatRadius etc.) ────────────

const _kAlignmentDecimals = 1;

String _fmt(double v, int decimalPlaces) =>
    formatInspectorDouble(v, decimalPlaces: decimalPlaces);

// ─── Geometry formatters ─────────────────────────────────────────────────────

/// Formats a single [Radius], collapsing to a scalar when x == y.
String formatRadius(Radius r, {int decimalPlaces = 1}) => r.x == r.y
    ? _fmt(r.x, decimalPlaces)
    : '${_fmt(r.x, decimalPlaces)}×${_fmt(r.y, decimalPlaces)}';

/// Formats a [BorderRadiusGeometry], collapsing uniform values and showing
/// elliptical `(x×y)` radii only when x != y. Returns `null` when the radius
/// is zero — callers should skip the chip.
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

/// Returns the [BorderRadiusGeometry] of common rectangular [ShapeBorder]s.
BorderRadiusGeometry? extractShapeBorderRadius(ShapeBorder shape) {
  if (shape is RoundedRectangleBorder) return shape.borderRadius;
  if (shape is BeveledRectangleBorder) return shape.borderRadius;
  if (shape is ContinuousRectangleBorder) return shape.borderRadius;
  return null;
}

// ─── Release-safe value formatters ───────────────────────────────────────────
//
// Flutter's AOT release build strips `toString()` overrides on several
// painting / dart:ui types (FontWeight, TextDecoration, AlignmentGeometry,
// SystemTextScaler, ImageFilter, ColorFilter, …), falling back to
// `Instance of '<TypeName>'`. The helpers below read public fields (or
// safely peek at private discriminators) so labels stay readable.
//
// Anything that pokes at Flutter internals (private fields, factory-derived
// runtime types) is validated once in debug via [_assertReleaseSafeContracts]
// — if a Flutter upgrade renames a field or changes a class shape, the
// assert fires at first use pointing at the broken function instead of
// silently degrading to `'ColorFilter'` / `'ImageFilter'`.

/// Default `Object.toString()` returns this prefix (Dart specification);
/// detecting it tells us a class's `toString()` override was stripped by AOT.
const _kStrippedToStringPrefix = "Instance of '";

String describeAlignment(AlignmentGeometry alignment) {
  String fmt(double v) => v.toStringAsFixed(_kAlignmentDecimals);
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

/// Reads `textScaleFactor` (deprecated but is the only public field shared by
/// every [TextScaler] subclass — linear, system, clamped).
String describeTextScaler(TextScaler scaler) {
  if (identical(scaler, TextScaler.noScaling)) return 'no scaling';
  // ignore: deprecated_member_use
  final factor = scaler.textScaleFactor;
  if (factor == 1.0) return 'no scaling';
  return '${factor.toStringAsFixed(2)}×';
}

/// [ImageFilter] subclasses (`_GaussianBlurImageFilter` etc.) are library-
/// private. We identify the kind by comparing `runtimeType` against factory-
/// constructed sentinels (no hardcoded class-name strings) and read parameter
/// fields via `dynamic`. The fields themselves (`sigmaX`, `radiusX`,
/// `innerFilter`, …) are public on the private classes —
/// see `dart:ui/painting.dart` `_GaussianBlurImageFilter` and friends.
String describeImageFilter(ImageFilter filter) {
  assert(_assertReleaseSafeContracts());
  final raw = filter.toString();
  if (!raw.startsWith(_kStrippedToStringPrefix)) return raw;
  final kind = _ImageFilterKind.lookup(filter.runtimeType);
  if (kind == null) return 'ImageFilter';
  try {
    final dyn = filter as dynamic;
    String d(Object? v) => (v as double).toStringAsFixed(1);
    return switch (kind) {
      _ImageFilterKind.blur => 'blur(${d(dyn.sigmaX)}, ${d(dyn.sigmaY)})',
      _ImageFilterKind.dilate => 'dilate(${d(dyn.radiusX)}, ${d(dyn.radiusY)})',
      _ImageFilterKind.erode => 'erode(${d(dyn.radiusX)}, ${d(dyn.radiusY)})',
      _ImageFilterKind.matrix => 'matrix',
      _ImageFilterKind.compose =>
        'compose(${describeImageFilter(dyn.innerFilter as ImageFilter)} '
            '→ ${describeImageFilter(dyn.outerFilter as ImageFilter)})',
    };
  } catch (_) {
    return 'ImageFilter.${kind.name}';
  }
}

/// `Type → kind` registry built by constructing one filter per public
/// factory; survives renames of the private subclasses.
enum _ImageFilterKind {
  blur,
  dilate,
  erode,
  matrix,
  compose;

  static final Map<Type, _ImageFilterKind> _byType = () {
    final identity4x4 = Float64List.fromList(<double>[
      1, 0, 0, 0, //
      0, 1, 0, 0, //
      0, 0, 1, 0, //
      0, 0, 0, 1, //
    ]);
    final blurFilter = ImageFilter.blur();
    return {
      blurFilter.runtimeType: blur,
      ImageFilter.dilate().runtimeType: dilate,
      ImageFilter.erode().runtimeType: erode,
      ImageFilter.matrix(identity4x4).runtimeType: matrix,
      ImageFilter.compose(outer: blurFilter, inner: blurFilter).runtimeType:
          compose,
    };
  }();

  static _ImageFilterKind? lookup(Type t) => _byType[t];
}

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

/// [ColorFilter] is a single class discriminated by private fields
/// (`_type`, `_color`, `_blendMode`, `_matrix` — see `dart:ui/painting.dart`).
/// Tries three strategies in order: parse the official `toString()` (works
/// in debug), match parameter-less gamma sentinels via `==`, then probe
/// fields via `dynamic`. Each strategy returns `null` to delegate to the
/// next.
String describeColorFilter(ColorFilter f) {
  assert(_assertReleaseSafeContracts());
  return _describeColorFilterFromToString(f) ??
      _describeColorFilterFromSentinel(f) ??
      _describeColorFilterFromFields(f) ??
      'ColorFilter';
}

String? _describeColorFilterFromToString(ColorFilter f) {
  final s = f.toString();
  if (s.startsWith(_kStrippedToStringPrefix)) return null;
  final blend = RegExp(r'BlendMode\.(\w+)').firstMatch(s);
  if (s.startsWith('ColorFilter.mode') && blend != null) {
    return 'mode · ${blend.group(1)}';
  }
  return s.replaceFirst('ColorFilter.', '');
}

const _linearToSrgbGamma = ColorFilter.linearToSrgbGamma();
const _srgbToLinearGamma = ColorFilter.srgbToLinearGamma();

String? _describeColorFilterFromSentinel(ColorFilter f) {
  if (f == _linearToSrgbGamma) return 'linearToSrgbGamma';
  if (f == _srgbToLinearGamma) return 'srgbToLinearGamma';
  return null;
}

String? _describeColorFilterFromFields(ColorFilter f) {
  try {
    final dyn = f as dynamic;
    final color = dyn._color as Color?;
    final blend = dyn._blendMode as BlendMode?;
    if (color != null && blend != null) {
      final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
      return 'mode · ${blend.name} · #$hex';
    }
    if (dyn._matrix != null) return 'matrix';
  } catch (_) {
    // Private field renamed upstream — debug assert in
    // [_assertReleaseSafeContracts] catches this loudly; we degrade silently
    // in release.
  }
  return null;
}

// ─── Text utilities ──────────────────────────────────────────────────────────

const _kPreviewSampleCap = 120;
const _kPreviewDisplayCap = 80;

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
/// [_kPreviewDisplayCap] visible characters; appends `…` when the underlying
/// text is longer.
String previewText(InlineSpan span) {
  final buf = StringBuffer();
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null) buf.write(child.text);
    return buf.length < _kPreviewSampleCap;
  });
  final raw = buf.toString().replaceAll('\n', '⏎');
  return raw.length <= _kPreviewDisplayCap
      ? raw
      : '${raw.substring(0, _kPreviewDisplayCap)}…';
}

// ─── Debug-only contract validation ──────────────────────────────────────────
//
// Runs once at first call to any helper that depends on Flutter internals.
// If a Flutter upgrade renames a private field or changes a class shape, the
// assert fires with a message naming the broken function — fix points are
// localised, no silent UI degradation in development.

bool _contractsValidated = false;

bool _assertReleaseSafeContracts() {
  if (_contractsValidated) return true;
  _contractsValidated = true;

  // ColorFilter — used by [_describeColorFilterFromFields].
  // Source: dart:ui/painting.dart, `class ColorFilter`.
  const modeFilter = ColorFilter.mode(Color(0xFF010203), BlendMode.srcIn);
  final dynColor = modeFilter as dynamic;
  assert(
    dynColor._color is Color && dynColor._blendMode is BlendMode,
    'describeColorFilter: ColorFilter._color/_blendMode renamed in Flutter; '
    'update _describeColorFilterFromFields in value_descriptors.dart',
  );

  // ImageFilter — used by [describeImageFilter] for value extraction.
  // Source: dart:ui/painting.dart, `_GaussianBlurImageFilter` etc.
  final blur = ImageFilter.blur(sigmaX: 1, sigmaY: 2);
  final dynBlur = blur as dynamic;
  assert(
    dynBlur.sigmaX == 1.0 && dynBlur.sigmaY == 2.0,
    'describeImageFilter: blur sigmaX/sigmaY renamed in Flutter; '
    'update the blur branch of describeImageFilter',
  );
  final dilate = ImageFilter.dilate(radiusX: 3, radiusY: 4);
  final dynDilate = dilate as dynamic;
  assert(
    dynDilate.radiusX == 3.0 && dynDilate.radiusY == 4.0,
    'describeImageFilter: dilate/erode radiusX/radiusY renamed in Flutter; '
    'update the dilate/erode branches of describeImageFilter',
  );
  final compose = ImageFilter.compose(outer: blur, inner: dilate);
  final dynCompose = compose as dynamic;
  assert(
    dynCompose.innerFilter is ImageFilter &&
        dynCompose.outerFilter is ImageFilter,
    'describeImageFilter: compose innerFilter/outerFilter renamed in Flutter; '
    'update the compose branch of describeImageFilter',
  );

  return true;
}
