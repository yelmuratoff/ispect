import 'package:ispectify/ispectify.dart';

final class LogDetails {
  const LogDetails({
    required this.message,
    required this.level,
    required this.pen,
  });

  final Object? message;

  final LogLevel level;

  final AnsiPen pen;
}
