import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ispect_layout/src/number_format.dart';

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
    label: 'radius',
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
// `Instance of '<TypeName>'`. The helpers below read public fields or peek
// at private discriminators so labels stay readable.
//
// Anything depending on Flutter internals is validated once in debug via
// [_assertReleaseSafeContracts] — Flutter renames or shape changes fire an
// assert at first use naming the broken function.

/// Default `Object.toString()` output starts with this prefix (Dart spec);
/// detecting it tells us a `toString()` override was stripped by AOT.
const _kStrippedToStringPrefix = "Instance of '";

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

/// `textScaleFactor` is the only public field shared by every [TextScaler]
/// subclass (linear / system / clamped), even after deprecation.
String describeTextScaler(TextScaler scaler) {
  if (identical(scaler, TextScaler.noScaling)) return 'no scaling';
  // ignore: deprecated_member_use
  final factor = scaler.textScaleFactor;
  if (factor == 1.0) return 'no scaling';
  return '${factor.toStringAsFixed(2)}×';
}

/// [ImageFilter] subclasses (`_GaussianBlurImageFilter` etc. in
/// `dart:ui/painting.dart`) are library-private. Kind is identified by
/// comparing `runtimeType` against factory-constructed sentinels; parameter
/// fields (`sigmaX`, `radiusX`, `innerFilter`, …) are public on the
/// private classes and read via `dynamic`.
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
/// images, asset name for bundled assets, file path for files; falls back
/// to the runtime type for unknown providers. Recurses into [ResizeImage].
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
/// (`_type` / `_color` / `_blendMode` / `_matrix` in `dart:ui/painting.dart`).
/// Resolves through three strategies in order, each returning `null` to
/// delegate down: official `toString()` (debug-only), `==` against parameter-
/// less gamma sentinels, then `dynamic` field probing.
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
    // Field renamed upstream — debug assert in [_assertReleaseSafeContracts]
    // surfaces this; release silently degrades to 'ColorFilter'.
  }
  return null;
}

// ─── Text utilities ──────────────────────────────────────────────────────────

const _kPreviewSampleCap = 120;
const _kPreviewDisplayCap = 80;

/// Flattens all [TextStyle]s found across an [InlineSpan] tree in traversal
/// order.
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
/// [_kPreviewDisplayCap] visible characters; appends `…` when longer.
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

/// A paragraph that paints icon glyphs — Private-Use-Area code points
/// rendered with an icon font (`MaterialIcons`, `CupertinoIcons`, custom
/// packs). Recognised so the inspector can show the actual glyph instead
/// of tofu under the default text preview.
class IconGlyphPreview {
  const IconGlyphPreview({
    required this.codePoints,
    required this.fontFamily,
  });

  final List<int> codePoints;

  /// Icon font family as stored on the [TextSpan]. Flutter encodes the
  /// owning package as a `packages/<pkg>/<family>` prefix here, so no
  /// separate `fontPackage` field is required to re-render the glyph.
  final String fontFamily;

  String get codePointsLabel => codePoints
      .map((cp) => 'U+${cp.toRadixString(16).toUpperCase()}')
      .join(' ');

  String get glyphs => String.fromCharCodes(codePoints);
}

bool _isPrivateUseCodePoint(int cp) =>
    (cp >= 0xE000 && cp <= 0xF8FF) ||
    (cp >= 0xF0000 && cp <= 0xFFFFD) ||
    (cp >= 0x100000 && cp <= 0x10FFFD);

bool _isIconFontFamily(String? family) {
  if (family == null) return false;
  return family.contains('Icons') || family.startsWith('Cupertino');
}

/// Returns an [IconGlyphPreview] when [span] is composed entirely of icon
/// glyphs, otherwise `null`. Recognition is intentionally conservative —
/// a single non-icon character or non-icon font family anywhere in the
/// tree disqualifies the span, so plain text never gets misread as an
/// icon.
IconGlyphPreview? describeAsIconGlyphs(InlineSpan span) {
  final codePoints = <int>[];
  String? fontFamily;
  var ok = true;

  void inspect(InlineSpan node) {
    if (!ok) return;
    if (node is! TextSpan) {
      ok = false;
      return;
    }
    final text = node.text;
    if (text != null && text.isNotEmpty) {
      final family = node.style?.fontFamily;
      if (!_isIconFontFamily(family)) {
        ok = false;
        return;
      }
      for (final cp in text.runes) {
        if (!_isPrivateUseCodePoint(cp)) {
          ok = false;
          return;
        }
        codePoints.add(cp);
      }
      fontFamily ??= family;
    }
    final children = node.children;
    if (children != null) {
      for (final c in children) {
        inspect(c);
        if (!ok) return;
      }
    }
  }

  inspect(span);

  if (!ok || codePoints.isEmpty || fontFamily == null) return null;
  return IconGlyphPreview(
    codePoints: List.unmodifiable(codePoints),
    fontFamily: fontFamily!,
  );
}

// ─── Debug-only contract validation ──────────────────────────────────────────

bool _contractsValidated = false;

bool _assertReleaseSafeContracts() {
  if (_contractsValidated) return true;
  _contractsValidated = true;

  // Source: dart:ui/painting.dart, `class ColorFilter`.
  const modeFilter = ColorFilter.mode(Color(0xFF010203), BlendMode.srcIn);
  final dynColor = modeFilter as dynamic;
  assert(
    dynColor._color is Color && dynColor._blendMode is BlendMode,
    'ColorFilter._color/_blendMode renamed in Flutter; '
    'update _describeColorFilterFromFields in value_descriptors.dart',
  );

  // Source: dart:ui/painting.dart, `_GaussianBlurImageFilter` etc.
  final blur = ImageFilter.blur(sigmaX: 1, sigmaY: 2);
  final dynBlur = blur as dynamic;
  assert(
    dynBlur.sigmaX == 1.0 && dynBlur.sigmaY == 2.0,
    'ImageFilter.blur sigmaX/sigmaY renamed in Flutter; '
    'update the blur branch of describeImageFilter',
  );
  final dilate = ImageFilter.dilate(radiusX: 3, radiusY: 4);
  final dynDilate = dilate as dynamic;
  assert(
    dynDilate.radiusX == 3.0 && dynDilate.radiusY == 4.0,
    'ImageFilter.dilate/erode radiusX/radiusY renamed in Flutter; '
    'update the dilate/erode branches of describeImageFilter',
  );
  final compose = ImageFilter.compose(outer: blur, inner: dilate);
  final dynCompose = compose as dynamic;
  assert(
    dynCompose.innerFilter is ImageFilter &&
        dynCompose.outerFilter is ImageFilter,
    'ImageFilter.compose innerFilter/outerFilter renamed in Flutter; '
    'update the compose branch of describeImageFilter',
  );

  return true;
}
