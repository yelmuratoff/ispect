import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/models/_models.dart';

/// Settings for DB logger integration
class ISpectDbLoggerSettings {
  const ISpectDbLoggerSettings({
    this.enabled = true,
    this.enableRedaction = true,
    this.printQuery = true,
    this.printParams = true,
    this.printResult = true,
    this.printDuration = true,
    this.printError = true,
    this.queryPen,
    this.resultPen,
    this.errorPen,
    this.queryFilter,
    this.resultFilter,
    this.errorFilter,
  });

  final bool enabled;
  final bool enableRedaction;

  final bool printQuery;
  final bool printParams;
  final bool printResult;
  final bool printDuration;
  final bool printError;

  final AnsiPen? queryPen;
  final AnsiPen? resultPen;
  final AnsiPen? errorPen;

  /// Filter callbacks to include/exclude logs
  final bool Function(DbQueryLog log)? queryFilter;
  final bool Function(DbResultLog log)? resultFilter;
  final bool Function(DbErrorLog log)? errorFilter;

  ISpectDbLoggerSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    bool? printQuery,
    bool? printParams,
    bool? printResult,
    bool? printDuration,
    bool? printError,
    AnsiPen? queryPen,
    AnsiPen? resultPen,
    AnsiPen? errorPen,
    bool Function(DbQueryLog log)? queryFilter,
    bool Function(DbResultLog log)? resultFilter,
    bool Function(DbErrorLog log)? errorFilter,
  }) =>
      ISpectDbLoggerSettings(
        enabled: enabled ?? this.enabled,
        enableRedaction: enableRedaction ?? this.enableRedaction,
        printQuery: printQuery ?? this.printQuery,
        printParams: printParams ?? this.printParams,
        printResult: printResult ?? this.printResult,
        printDuration: printDuration ?? this.printDuration,
        printError: printError ?? this.printError,
        queryPen: queryPen ?? this.queryPen,
        resultPen: resultPen ?? this.resultPen,
        errorPen: errorPen ?? this.errorPen,
        queryFilter: queryFilter ?? this.queryFilter,
        resultFilter: resultFilter ?? this.resultFilter,
        errorFilter: errorFilter ?? this.errorFilter,
      );
}
