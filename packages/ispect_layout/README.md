<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispect_layout">
      <img src="https://img.shields.io/pub/v/ispect_layout?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&labelColor=0360a9&color=2ab7f6" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=for-the-badge&logo=github&labelColor=0360a9&color=2ab7f6" alt="GitHub stars">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispect_layout/score">
      <img src="https://img.shields.io/pub/likes/ispect_layout?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect_layout/score">
      <img src="https://img.shields.io/pub/points/ispect_layout?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispect_layout/downloads">
      <img src="https://img.shields.io/pub/dm/ispect_layout?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>

**ispect_layout** is a visual layout inspector for Flutter. Tap any widget to see its render box — size, constraints, padding, decoration, text styles, transform matrix, clip shape — and compare two widgets side by side to measure the pixel gap between them.

Part of the [ISpect](https://github.com/yelmuratoff/ispect) debugging toolkit, but works standalone.

Forked from [`inspector`](https://github.com/kekland/inspector) by Erzhan (kekland) — thanks for the original work. This fork continues the package with expanded render-object coverage, a wrapper-ancestors section, richer decoration breakdowns, image source introspection, a `TextField` inspector, and a refactored architecture.

---

## Features

- **Widget selection** with hit-test path visualization.
- **Size, padding, constraints** read directly from the render box.
- **Decoration breakdown:** color, border (per side), shadows (with `spreadRadius`), gradients (with visual preview, stops, `begin/end`, `tileMode`), `DecorationImage`.
- **Border radius** formatted per corner (TL/TR/BR/BL), collapses to a single value when uniform, shows elliptical radii as `x×y`.
- **Text inspection:** plain-text preview, span-by-span style breakdown, `didExceedMaxLines` indicator, `maxLines`, `overflow`, `textScaler`.
- **Render-object coverage:** `RenderFlex`, `RenderStack`, `RenderWrap`, `RenderImage`, `RenderOpacity` / `RenderAnimatedOpacity`, `RenderPhysicalShape` / `RenderPhysicalModel`, `RenderFittedBox`, `RenderAspectRatio`, `RenderCustomPaint`, `RenderTransform` (matrix decomposition), `RenderBackdropFilter`, all `RenderClip*` types, `RenderEditable` (TextField).
- **Wrapper ancestors:** when the selected widget is wrapped in same-size proxies (Transform, ClipRRect, BackdropFilter, Opacity, FittedBox, …) their properties are surfaced as separate sub-sections.
- **Compare mode:** tap Compare (or press `Y`) and select a second widget — see horizontal/vertical gaps or LTRB alignment offsets with a visual overlay.
- **Color picker** with pixel-level sampling and `ColorScheme` hints.
- **Zoom / magnifier** overlay.
- **Keyboard shortcuts** on physical keyboards.

---

## Install

```yaml
dependencies:
  ispect_layout: ^0.1.0
```

## Usage

Wrap your app (or any subtree) with `Inspector`:

```dart
import 'package:flutter/material.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() {
  runApp(
    MaterialApp(
      home: const MyApp(),
      builder: (context, child) => Inspector(
        isEnabled: true, // typically kDebugMode
        child: child!,
      ),
    ),
  );
}
```

Tap the widget-inspector FAB to start selecting widgets. Tap any widget to open the info panel. Tap the **Compare** icon (or press `Y`) to lock the current selection, then tap a second widget to see the pixel distance between them.

See `example/lib/showcase_example.dart` for a tour of every render-object type the inspector handles.

---

## Credits

- **Original package:** [`inspector`](https://github.com/kekland/inspector) by Erzhan (kekland) — MIT.
- Inspired by [inspx](https://github.com/raunofreiberg/inspx).
