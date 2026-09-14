/// Controls whether diagnostics may use application-defined formatters.
enum DiagnosticCaptureMode {
  /// Captures useful, bounded diagnostic text and structured `toJson()` data.
  ///
  /// Application-defined `toJson()` and `toString()` methods may run inside
  /// guarded capture boundaries. Values are bounded immediately and should be
  /// redacted before they leave the active diagnostic pipeline.
  balanced,

  /// Never invokes application-defined formatters.
  ///
  /// Unknown values are represented by opaque markers. Use this mode for
  /// shared, high-risk, or metadata-only environments.
  strict,
}
