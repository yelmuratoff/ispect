/// Platform directory abstraction base, independent of dart:io.
///
/// Implementations may return platform-specific objects (e.g., `Directory` on
/// native). The return type is `Object` to avoid importing `dart:io` in the
/// base, keeping web builds happy. Callers on native can cast to `Directory`.
abstract class PlatformDirectoryProvider {
  Future<Object> logsBaseDirectory();
  Future<Object> tempDirectory();
}
