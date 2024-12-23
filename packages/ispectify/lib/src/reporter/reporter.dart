abstract interface class ILogReporter {
  /// Default constructor for [ILogReporter].
  const ILogReporter();

  /// Reports a log message with optional metadata.
  ///
  /// ### Parameters:
  /// - `message`: The log message to report.
  void report({
    required String message,
  });
}
