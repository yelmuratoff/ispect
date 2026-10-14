import 'package:ispect/src/ispect.dart';
import 'package:ispectify/ispectify.dart';

abstract final class ISpectResourceLimits {
  static DiagnosticResourceLimits? get configured =>
      ISpect.loggerIfInitialized?.options.resourceLimits;

  static DiagnosticResourceLimits get current =>
      configured ?? DiagnosticResourceLimits.balanced;
}
