---
name: ispect-layout-setup
description: >-
  Add or troubleshoot the standalone ispect_layout Flutter inspector for widget measurements, compare mode, color picking, and zoom in internal builds.
---

# Layout inspector setup

Add `ispect_layout` and import `package:ispect_layout/ispect_layout.dart`.
The package is standalone; a logger or the full ISpect panel is unnecessary.

## Integration

- Wrap the existing `MaterialApp.builder` or `WidgetsApp.builder` child with
  `Inspector`, preserving other wrappers.
- Use `isEnabled` as the runtime switch. `isPanelVisible: false` only hides
  the panel; keyboard shortcuts can still operate the inspector.
- Let `Inspector` own its controller for simple integrations. If supplying
  `InspectorController`, keep it stable across rebuilds and dispose it in the
  owner's lifecycle. Set theme and render-tree clipboard limits on that
  controller when supplying one.

```dart
import 'package:flutter/material.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() => runApp(
      MaterialApp(
        builder: (_, child) => Inspector(
          isEnabled: true,
          initialPanelExpanded: false,
          decimalPlaces: 2,
          child: child!,
        ),
        home: const Scaffold(body: Center(child: Text('Inspect this widget'))),
      ),
    );
```

## Build and inspection boundaries

Use `flutter run --dart-define=ISPECT_ENABLED=true` for internal builds. Omit
the define from public releases. `kISpectLayoutEnabled` is the absolute gate;
`isEnabled: true` cannot bypass it. With the flag present, the runtime default
enables the inspector outside release mode; use `isEnabled: true` for explicitly
authorized internal release inspection.

Default shortcuts are `Alt+W` for selection, `Alt+Y` for compare, `Alt+C` for
color picking, and `Alt+Z` for zoom. Custom shortcuts take `ShortcutActivator`s
on `InspectorController`. Compare needs an initial selection and a second widget.

Measurements work in profile/release, but obfuscation changes type labels and
`dart:ui` does not expose `ColorFilter` parameters in release. Treat render-tree
clipboard text and visible content as potentially sensitive; inspect controlled
screens and review clipboard output before sharing.

Verify selection, measurements, and compare in an enabled internal build, then
verify inactive controls when the define is omitted.
