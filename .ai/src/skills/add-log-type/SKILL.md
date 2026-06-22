---
name: add-log-type
description: Use this skill when adding, registering, or theming a new ISpect log type / log key (e.g. "add a ws-state log", "register a new log key", "new trace category", "my custom log has no color/icon"). It is the checklist for wiring a key end to end so nothing is missed — core registration, console color, UI color, icon, title, and localized description.
---

# Add A Log Type

A log key lives in two packages with **two independent color systems**. Miss a
step and the key silently falls back to defaults (gray console line, no icon,
key shown as its raw string). Wire every item below.

## Where each piece lives

### Core — `packages/ispectify`
1. `lib/src/models/log_type.dart`
   - Declare `static const xxx = ISpectLogType('my-key', category: TraceCategoryIds.foo, isError: …, level: …)`.
   - Add it to the `builtIn` list — this is what the filter UI enumerates; omit it and the type is undiscoverable.
   - Add an **ANSI console pen** to the `_defaultPens` map (`'my-key': AnsiPen()..xterm(NN)`). This is the **console** color, separate from the UI palette below — keep the two visually consistent.
2. New category only: add the id to `lib/src/trace/trace_category_ids.dart` (and its `builtIn` set), then a `ISpectTraceCategory` in `lib/src/trace/trace_categories.dart`.
3. Emitter: add a method on the domain extension in `lib/src/trace/extensions/<domain>.dart` that calls `traceCategory(...)`. If the key is **not** the success/error/secondary of a request/response (e.g. a lifecycle/state event), pass an explicit `logKey: ISpectLogType.xxx.key` — `ISpectTraceCategory.pickLogKey` only maps success/error/secondary and would otherwise mislabel it.

### UI — `packages/ispect`
4. `lib/src/core/res/constants/ispect_log_palette.dart` — add the key to **both** the light map and the dark map.
5. `lib/src/core/res/constants/ispect_log_icons.dart` — add an icon.
6. `lib/src/core/res/constants/ispect_log_descriptions.dart` — add `LogDescription(key: 'my-key', title: 'My Key', description: l10n.myKeyLogDesc)`.
7. Localization (ARB is the source; generated files are rebuilt):
   - Add `"myKeyLogDesc": "…"` to `lib/src/core/localization/translations/intl_en.arb` (the template — required).
   - Optionally add real translations to other `intl_*.arb`; locales without it fall back to the English template (the existing `ws-error` precedent).
   - Regenerate: `cd packages/ispect && flutter gen-l10n`. Never hand-edit `lib/src/core/localization/generated/**`. `untranslated.json` is a generated, git-ignored report — do not commit it.

## Verify
- `cd packages/ispectify && dart analyze --fatal-infos && dart test`
- `cd packages/ispect && flutter analyze --fatal-infos && flutter test`
- `dart format` the changed Dart files.

## Gotchas
- **Two color systems.** Console color = ANSI pen in `log_type.dart`; UI color = palette in `ispect`. Updating one and not the other is the most common miss (a gray console line next to a colored chip).
- **`builtIn` list.** Forgetting it means the key works but never appears in the filter UI.
- **Stable keys.** Never rename an existing key (`http-request`, `ws-sent`, `db-query`, …) — filters and exported sessions depend on them. New keys are additive.
- **`ISpectLogType` is a `final class`, not an enum** — no `values`/exhaustive switches.
- For the broader capture/redaction/correlation rules around interceptors, see the `diagnostics-interceptor-change` skill.
