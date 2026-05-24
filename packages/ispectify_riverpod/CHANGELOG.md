## 5.2.0-dev.7

* Initial release of `ispectify_riverpod`.
* `ISpectRiverpodObserver` logs `didAddProvider`, `didUpdateProvider`,
  `didDisposeProvider`, and `providerDidFail` under the `riverpod-add`,
  `riverpod-update`, `riverpod-dispose`, and `riverpod-fail` log keys.
* `ISpectRiverpodSettings` toggles per-event logging, full-value logging,
  provider/update filtering, and metadata redaction.
* `ISpectRiverpodSettings.printValues` defaults to `true` — raw `value` /
  `previous-value` / `new-value` are written to trace meta on every lifecycle
  event. Switch to `ISpectRiverpodSettings.compact` (or `printValues: false`)
  when provider state may carry PII and only runtime types are wanted.
