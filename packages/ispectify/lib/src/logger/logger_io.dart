// ignore_for_file: avoid_print

/// Outputs a log message by splitting it into lines and printing each line separately.
///
/// This function takes a `message` string, splits it into multiple lines using
/// the newline character (`\n`) as a delimiter, and prints each line individually.
///
/// - Parameter [message`: The log message to be output. It can contain multiple lines.
void outputLog(String message) => message.split('\n').forEach(
      print,
    );
