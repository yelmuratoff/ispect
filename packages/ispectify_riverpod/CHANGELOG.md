# Changelog

## 5.2.0-dev.7

- Initial release. `ISpectRiverpodObserver` routes `didAddProvider`, `didUpdateProvider`, `didDisposeProvider`, and `providerDidFail` to the `riverpod-add`, `riverpod-update`, `riverpod-dispose`, and `riverpod-fail` log keys.
- `ISpectRiverpodSettings` toggles per-event logging, value capture, provider/update filters, and redaction. `silent`, `minimal`, and `compact` presets.
- `printValues: true` by default — raw values land in trace meta. Use `ISpectRiverpodSettings.compact` when provider state may carry PII.
