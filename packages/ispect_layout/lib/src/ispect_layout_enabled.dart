/// Compile-time gate for the standalone layout inspector.
///
/// The inspector is inert unless the app is built with
/// `--dart-define=ISPECT_ENABLED=true`.
const bool kISpectLayoutEnabled = bool.fromEnvironment('ISPECT_ENABLED');
