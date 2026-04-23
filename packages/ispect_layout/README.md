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

**ispect_layout** is a standalone visual layout inspector for Flutter. Tap any widget in a running app to read its render box — size, constraints, padding, decoration, text styles, transform matrix, clip shape — then tap a second widget to measure the pixel gap between them. Sample any pixel's color and magnify pixel-dense regions without leaving the app.

Works on its own — no dependency on the rest of the ISpect toolkit.

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/1.jpg?raw=true" width="260" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/2.jpg?raw=true" width="260" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/3.jpg?raw=true" width="260" />
</div>

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/4.jpg?raw=true" width="260" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/5.jpg?raw=true" width="260" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/6.jpg?raw=true" width="260" />
</div>

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/7.jpg?raw=true" width="260" />
</div>

---

## Features

| Mode             | What it does                                                                                                                            | Default shortcut |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| **Inspector**    | Tap a widget, see a full render-object breakdown and the hit-test path visualised over the UI.                                          | `Alt` / `Meta`   |
| **Compare**      | Lock a selection, tap a second widget, and read the horizontal/vertical gap or LTRB offset with an overlay between the two boxes.       | `Y`              |
| **Color picker** | Hover/tap any on-screen pixel to capture its color. A zoomable magnifier shows neighbouring pixels and the closest `ColorScheme` token. | `Shift`          |
| **Zoom**         | Pixel-level magnifier for dense UI — mouse-wheel / trackpad changes zoom level in-place.                                                | `Z`              |

### Render-object coverage

The inspector surfaces the actual render object, not just the widget name, so wrappers that share the same bounds are shown separately under **Wrapper ancestors**:

- **Layout:** `RenderFlex`, `RenderStack`, `RenderWrap`, `RenderAspectRatio`, `RenderFittedBox`, `RenderCustomPaint`
- **Decoration:** color, per-side border, shadows (incl. `spreadRadius`), gradients (visual preview + stops, `begin`/`end`, `tileMode`), `DecorationImage`, per-corner border radius (collapsed when uniform, elliptical radii rendered as `x×y`)
- **Effects:** `RenderOpacity` / `RenderAnimatedOpacity`, `RenderPhysicalShape` / `RenderPhysicalModel`, `RenderTransform` (matrix decomposition), `RenderBackdropFilter`, every `RenderClip*`
- **Text:** plain-text preview, span-by-span style breakdown, `didExceedMaxLines`, `maxLines`, `overflow`, `textScaler`
- **Images:** `RenderImage` with image-source introspection (network, asset, file, memory)
- **Fields:** `RenderEditable` — live `TextField` inspection (selection, obscure state, text style)

---

## Install

```yaml
dependencies:
  ispect_layout: ^5.0.0-dev15
```

```dart
import 'package:ispect_layout/ispect_layout.dart';
```

Platforms: Android, iOS, web, macOS, Windows, Linux. Flutter ≥ 3.22, Dart ≥ 3.6.

---

## Quick Start

Wrap your app with `Inspector` via `MaterialApp.builder`. The default FAB panel appears on the right edge of the screen in debug builds.

```dart
import 'package:flutter/material.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() {
  runApp(
    MaterialApp(
      home: const MyHomePage(),
      builder: (context, child) => Inspector(
        isEnabled: true, // omit to auto-disable in release
        child: child!,
      ),
    ),
  );
}
```

### Production safety

When `isEnabled` is `null`, the inspector automatically disables itself in release builds (`kReleaseMode`). For explicit control, gate it behind your own flag:

```dart
Inspector(
  isEnabled: kDebugMode, // or a --dart-define flag
  child: child!,
)
```

When disabled, `Inspector` returns the child verbatim — no overlay, no keyboard handler, no gesture listener.

---

## Inspector Configuration

All modes, shortcuts, and feature toggles live on `InspectorController`. Pass a pre-configured one to `Inspector(controller: ...)` if you need to override defaults or drive the inspector from outside the widget tree.

```dart
final controller = InspectorController(
  isEnabled: true,
  // Feature toggles — each mode can be disabled independently.
  isWidgetInspectorEnabled: true,
  isWidgetInspectAndCompareEnabled: true,
  isColorPickerEnabled: true,
  isColorSchemeHintEnabled: true, // suggests closest ColorScheme token
  isZoomEnabled: true,

  // Keyboard shortcuts (desktop & web). Hold to activate, release to exit.
  widgetInspectorShortcuts: const [
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  ],
  widgetInspectAndCompareShortcuts: const [LogicalKeyboardKey.keyY],
  colorPickerShortcuts: const [
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  ],
  zoomShortcuts: const [LogicalKeyboardKey.keyZ],
);

Inspector(controller: controller, child: child!);
```

### Programmatic control

`InspectorController` exposes a `modeNotifier` you can observe and `setMode` to drive it:

```dart
// Switch modes from your own UI / button
controller.setMode(InspectorMode.inspector);
controller.setMode(InspectorMode.colorPicker);
controller.setMode(InspectorMode.zoom);
controller.setMode(InspectorMode.none); // disable

// React to mode changes
ListenableBuilder(
  listenable: controller.modeNotifier,
  builder: (_, __) => Text('Mode: ${controller.modeNotifier.value.name}'),
);
```

Additional notifiers you can listen to:

- `currentRenderBoxNotifier` — currently selected `BoxInfo`
- `hoveredRenderBoxNotifier` — box under the pointer while hovering
- `comparedRenderBoxNotifier` — the second box in Compare mode
- `selectedColorStateNotifier` — color under the pointer in Color Picker
- `zoomScaleNotifier` — live zoom level (scroll/pinch adjusts it)

---

## Custom Panel

The default floating control panel can be replaced wholesale with `panelBuilder`. Use this to integrate the inspector into your own dev toolbar or drop in a different panel library:

```dart
Inspector(
  child: child!,
  panelBuilder: (context, controller, content) {
    return ListenableBuilder(
      listenable: controller.modeNotifier,
      child: content,
      builder: (context, child) => MyCustomPanel(
        inspectorActive: controller.modeNotifier.value == InspectorMode.inspector,
        onToggleInspector: () => controller.setMode(
          controller.modeNotifier.value == InspectorMode.inspector
              ? InspectorMode.none
              : InspectorMode.inspector,
        ),
        child: child,
      ),
    );
  },
)
```

The `content` parameter is the full render tree + overlays — put it wherever your panel lays things out. See [`example/lib/custom_inspector_example.dart`](example/lib/custom_inspector_example.dart) for a complete walkthrough using [`draggable_panel`](https://pub.dev/packages/draggable_panel).

To hide the built-in panel but keep keyboard shortcuts working, pass `isPanelVisible: false`:

```dart
Inspector(
  isPanelVisible: false, // FAB hidden; Alt/Shift/Y/Z still work
  child: child!,
);
```

---

## Compare Mode

Compare mode measures the pixel distance between two widgets. Flow:

1. Enter **Inspector** mode, tap a widget.
2. Press `Y` (or tap the **Compare** button on the selection overlay).
3. Tap a second widget. The overlay renders the horizontal/vertical gap, or LTRB offsets if the boxes overlap.

Drive it from code:

```dart
controller.enterCompareMode();  // requires a current selection
controller.exitCompareMode();
```

---

## Example

The package ships with two runnable examples:

- [`example/lib/main.dart`](example/lib/main.dart) — minimal integration with a scrollable list.
- [`example/lib/showcase_example.dart`](example/lib/showcase_example.dart) — a tour of every render-object type the inspector handles (Typography, Layout, Decoration, Spacing, Mixed, Transform & Clip, Fields, Images).

```bash
cd packages/ispect_layout/example
flutter run -t lib/showcase_example.dart
```

---

## Attribution

Forked from [`inspector`](https://github.com/kekland/inspector) 4.1.0 by Erzhan ([kekland](https://github.com/kekland)) — thanks for the original work. This fork continues the package inside the ISpect monorepo with:

- Expanded render-object coverage (`RenderTransform` matrix decomposition, `RenderBackdropFilter`, all `RenderClip*`, `RenderEditable` for `TextField`).
- A dedicated **Wrapper ancestors** section for same-size proxies (`Transform`, `ClipRRect`, `BackdropFilter`, `Opacity`, `FittedBox`, …).
- Richer decoration breakdowns: gradients with visual preview, shadow `spreadRadius`, per-corner border radius, `DecorationImage`.
- Image-source introspection for `RenderImage` (network / asset / file / memory).
- RichText preview and span-by-span style breakdown.
- A refactored `BoxInfoPanelWidget` split into testable extractor and widget modules.

Inspired by [inspx](https://github.com/raunofreiberg/inspx).

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>
