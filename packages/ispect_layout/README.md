<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispect_layout.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispect_layout">
      <img src="https://img.shields.io/pub/v/ispect_layout?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&labelColor=0360a9&color=2ab7f6" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=for-the-badge&logo=github&labelColor=0360a9&color=2ab7f6" alt="GitHub stars">
    </a>
    <a href="https://codecov.io/gh/yelmuratoff/ispect">
      <img src="https://img.shields.io/codecov/c/github/yelmuratoff/ispect?style=for-the-badge&logo=codecov&labelColor=0360a9&color=2ab7f6" alt="Coverage">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispect_layout/score">
      <img src="https://img.shields.io/pub/likes/ispect_layout?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect_layout/score">
      <img src="https://img.shields.io/pub/points/ispect_layout?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispect_layout">
      <img src="https://img.shields.io/pub/dm/ispect_layout?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


`ispect_layout` is a visual layout inspector for Flutter. Tap any widget at runtime to read its render box (size, constraints, padding, decoration, text styles, transform matrix, clip shape), or compare two widgets to measure the pixel gap between them.

A standalone package. It works on its own, without the rest of the [ISpect toolkit](#the-ispect-toolkit).

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/text.png?raw=true" width="220" alt="Typography" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/rich_text.png?raw=true" width="220" alt="Rich text" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/borders.png?raw=true" width="220" alt="Borders and radii" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/gradient.png?raw=true" width="220" alt="Gradient" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/dark_gradient.png?raw=true" width="220" alt="Dark theme gradient" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/shadow_blur.png?raw=true" width="220" alt="Shadow and blur" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/rotated_box.png?raw=true" width="220" alt="Transform and clip" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/compare.png?raw=true" width="220" alt="Compare two widgets" />
</div>

## What it surfaces

- Render box: size, padding, constraints, hit-test path visualisation.
- Decoration: colour, per-side border, shadows (including `spreadRadius`), gradients (visual preview, stops, `begin` / `end`, `tileMode`), and `DecorationImage`.
- Border radius formatted per corner (TL, TR, BR, BL), collapsed when uniform. Elliptical radii rendered as `x×y`.
- Text: plain-text preview, span-by-span style breakdown, `didExceedMaxLines`, `maxLines`, `overflow`, `textScaler`.
- Render-object coverage: `RenderFlex`, `RenderStack`, `RenderWrap`, `RenderImage`, `RenderOpacity`, `RenderAnimatedOpacity`, `RenderPhysicalShape`, `RenderPhysicalModel`, `RenderFittedBox`, `RenderAspectRatio`, `RenderCustomPaint`, `RenderTransform` (matrix decomposition), `RenderBackdropFilter`, every `RenderClip*`, and `RenderEditable` (text fields).
- Wrapper ancestors: when the selection is wrapped in same-size proxies (Transform, ClipRRect, BackdropFilter, Opacity, FittedBox, and the rest), each ancestor's properties appear as a separate sub-section.
- Compare mode: tap Compare (or press `Alt+Y`) and pick a second widget to see horizontal and vertical gaps or LTRB offsets with a visual overlay.
- Colour picker with pixel-level sampling, `ColorScheme` hints, a zoom/magnifier overlay, and physical-keyboard shortcuts.

## Install

```yaml
dependencies:
  ispect_layout: ^5.2.0-dev.24
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

Tap the widget-inspector FAB to start selecting. Tap the Compare icon (or press `Alt+Y`) to lock the current selection, then tap a second widget to see the pixel distance.

## Defaults and configuration

Default keyboard shortcuts are chosen so they do not collide with normal typing:

- `Alt+W`, widget inspector.
- `Alt+Y`, compare the selected widget with another widget.
- `Alt+C`, colour picker.
- `Alt+Z`, zoom overlay.

Panel state and value precision are configured on `Inspector` itself:

```dart
Inspector(
  isEnabled: true,
  initialPanelExpanded: false,
  decimalPlaces: 3,
  child: child!,
)
```

For custom multi-key shortcuts, pass `ShortcutActivator`s to `InspectorController`:

```dart
import 'package:flutter/services.dart';
import 'package:ispect_layout/ispect_layout.dart';

final controller = InspectorController(
  zoomShortcutActivators: const [
    SingleActivator(LogicalKeyboardKey.keyZ, alt: true, meta: true),
  ],
  colorPickerShortcutActivators: const [
    SingleActivator(LogicalKeyboardKey.keyC, control: true, alt: true),
  ],
);

Inspector(
  controller: controller,
  child: child!,
)
```

See [`example/lib/showcase_example.dart`](https://github.com/yelmuratoff/ispect/blob/main/packages/ispect_layout/example/lib/showcase_example.dart) for a tour of every render-object type the inspector handles.

## Attribution

Forked from [`inspector`](https://github.com/kekland/inspector) by Erzhan (kekland), with thanks for the original work. The fork continues the package with expanded render-object coverage, a wrapper-ancestors section, richer decoration breakdowns, image-source introspection, an input-fields inspector, and a refactored architecture. Inspired by [inspx](https://github.com/raunofreiberg/inspx).

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI: debug panel, log viewer, navigation observer, inspector integration. |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core: typed log entries, filtering, tracing, observers. |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction. |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction. |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | Provider-agnostic WebSocket capture (any client) with automatic redaction. |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing for SQL, ORMs, and KV stores. |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event, state, transition, and error observer. |
| [`ispectify_riverpod`](https://pub.dev/packages/ispectify_riverpod) | Riverpod provider add, update, dispose, and failure observer. |


## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT. See [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
