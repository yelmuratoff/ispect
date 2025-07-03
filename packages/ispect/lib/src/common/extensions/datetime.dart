import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Formats the DateTime to a string in the format 'dd.MM.yyyy'.
  ///
  /// Example:
  /// ```dart
  /// DateTime now = DateTime.now();
  /// String formatted = now.toFormattedString(); // e.g., '25.10.2023'
  /// ```
  String toFormattedString() => DateFormat('dd.MM.yyyy').format(this);
}
