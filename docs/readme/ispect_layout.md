<!-- partial:header -->

**ispect_layout** is a visual layout inspector for Flutter — tap any widget at runtime to read its render box (size, constraints, padding, decoration, text styles, transform matrix, clip shape) and compare two widgets side-by-side to measure the pixel gap between them.

Standalone package — works independently of the rest of the [ISpect toolkit](#the-ispect-toolkit).

<div align="center">
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/1.jpg" width="220" />
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/2.jpg" width="220" />
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/3.jpg" width="220" />
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/4.jpg" width="220" />
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/5.jpg" width="220" />
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/6.jpg" width="220" />
  <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/7.jpg" width="220" />
</div>

## What it surfaces

- **Render box**: size, padding, constraints, and hit-test path visualisation.
- **Decoration**: colour, per-side border, shadows (incl. `spreadRadius`), gradients (visual preview, stops, `begin` / `end`, `tileMode`), `DecorationImage`.
- **Border radius** formatted per corner (TL / TR / BR / BL), collapsed when uniform, elliptical radii rendered as `x×y`.
- **Text**: plain-text preview, span-by-span style breakdown, `didExceedMaxLines`, `maxLines`, `overflow`, `textScaler`.
- **Render-object coverage**: `RenderFlex`, `RenderStack`, `RenderWrap`, `RenderImage`, `RenderOpacity` / `RenderAnimatedOpacity`, `RenderPhysicalShape` / `RenderPhysicalModel`, `RenderFittedBox`, `RenderAspectRatio`, `RenderCustomPaint`, `RenderTransform` (matrix decomposition), `RenderBackdropFilter`, every `RenderClip*`, and `RenderEditable` (text fields).
- **Wrapper ancestors**: when the selection is wrapped in same-size proxies (Transform, ClipRRect, BackdropFilter, Opacity, FittedBox, …), each ancestor's properties are surfaced as a separate sub-section.
- **Compare mode**: tap **Compare** (or press `Y`) and pick a second widget to see horizontal / vertical gaps or LTRB offsets with a visual overlay.
- **Colour picker** with pixel-level sampling, `ColorScheme` hints, a zoom / magnifier overlay, and physical-keyboard shortcuts.

## Install

```yaml
dependencies:
  ispect_layout: ^{{version}}
```

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() {
  runApp(
    MaterialApp(
      home: const MyApp(),
      builder: (context, child) => Inspector(
        isEnabled: true, // typically `kDebugMode`.
        child: child!,
      ),
    ),
  );
}
```

Tap the widget-inspector FAB to start selecting. Tap the **Compare** icon (or press `Y`) to lock the current selection, then tap a second widget to see the pixel distance.

See [`example/lib/showcase_example.dart`](https://github.com/yelmuratoff/ispect/blob/main/packages/ispect_layout/example/lib/showcase_example.dart) for a tour of every render-object type the inspector handles.

## Attribution

Forked from [`inspector`](https://github.com/kekland/inspector) by Erzhan (kekland) — thanks for the original work. The fork continues the package with expanded render-object coverage, a wrapper-ancestors section, richer decoration breakdowns, image-source introspection, an input-fields inspector, and a refactored architecture. Inspired by [inspx](https://github.com/raunofreiberg/inspx).

<!-- partial:install_matrix -->

<!-- partial:footer -->
