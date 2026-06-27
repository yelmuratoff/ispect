// Platform implementations are selected by LogsFileFactory and deliberately not
// re-exported: that keeps dart:io and dart:js_interop off the default import
// path, which WASM/cross-platform analysis requires.
export 'base/base.dart';
export 'factory/factory.dart';
