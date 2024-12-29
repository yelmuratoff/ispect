import 'package:ispectify/ispectify.dart';

final _defaultTitles = {
  /// Base logs section
  ISpectifyLogType.critical.key: 'critical',
  ISpectifyLogType.warning.key: 'warning',
  ISpectifyLogType.verbose.key: 'verbose',
  ISpectifyLogType.info.key: 'info',
  ISpectifyLogType.debug.key: 'debug',
  ISpectifyLogType.error.key: 'error',
  ISpectifyLogType.exception.key: 'exception',

  /// Http section
  ISpectifyLogType.httpError.key: 'http-error',
  ISpectifyLogType.httpRequest.key: 'http-request',
  ISpectifyLogType.httpResponse.key: 'http-response',

  /// Bloc section
  ISpectifyLogType.blocEvent.key: 'bloc-event',
  ISpectifyLogType.blocTransition.key: 'bloc-transition',
  ISpectifyLogType.blocCreate.key: 'bloc-create',
  ISpectifyLogType.blocClose.key: 'bloc-close',

  /// Riverpod section
  ISpectifyLogType.riverpodAdd.key: 'riverpod-add',
  ISpectifyLogType.riverpodUpdate.key: 'riverpod-update',
  ISpectifyLogType.riverpodDispose.key: 'riverpod-dispose',
  ISpectifyLogType.riverpodFail.key: 'riverpod-fail',

  /// Flutter section
  ISpectifyLogType.route.key: 'route',
};

final _defaultColors = {
  /// Base logs section
  ISpectifyLogType.critical.key: AnsiPen()..red(),
  ISpectifyLogType.warning.key: AnsiPen()..yellow(),
  ISpectifyLogType.verbose.key: AnsiPen()..gray(),
  ISpectifyLogType.info.key: AnsiPen()..blue(),
  ISpectifyLogType.debug.key: AnsiPen()..gray(),
  ISpectifyLogType.error.key: AnsiPen()..red(),
  ISpectifyLogType.exception.key: AnsiPen()..red(),

  /// Http section
  ISpectifyLogType.httpError.key: AnsiPen()..red(),
  ISpectifyLogType.httpRequest.key: AnsiPen()..xterm(219),
  ISpectifyLogType.httpResponse.key: AnsiPen()..xterm(46),

  /// Bloc section
  ISpectifyLogType.blocEvent.key: AnsiPen()..xterm(51),
  ISpectifyLogType.blocTransition.key: AnsiPen()..xterm(49),
  ISpectifyLogType.blocCreate.key: AnsiPen()..xterm(35),
  ISpectifyLogType.blocClose.key: AnsiPen()..xterm(198),

  /// Riverpod section
  ISpectifyLogType.riverpodAdd.key: AnsiPen()..xterm(51),
  ISpectifyLogType.riverpodUpdate.key: AnsiPen()..xterm(49),
  ISpectifyLogType.riverpodDispose.key: AnsiPen()..xterm(198),
  ISpectifyLogType.riverpodFail.key: AnsiPen()..red(),

  /// Flutter section
  ISpectifyLogType.route.key: AnsiPen()..xterm(135),
};

final _fallbackPen = AnsiPen()..gray();

/// {@template talker_settings}
/// This class used for setup [ISpectiy] configuration
/// {@endtemplate}
class ISpectifyOptions {
  ISpectifyOptions({
    this.enabled = true,
    bool useHistory = true,
    bool useConsoleLogs = true,
    int maxHistoryItems = 1000,
    Map<String, String>? titles,
    Map<String, AnsiPen>? colors,
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  })  : _useHistory = useHistory,
        _useConsoleLogs = useConsoleLogs,
        _maxHistoryItems = maxHistoryItems,
        _timeFormat = timeFormat {
    if (colors != null) {
      _defaultColors.addAll(colors);
    }
    if (titles != null) {
      _defaultTitles.addAll(titles);
    }
    this.colors.addAll(_defaultColors);
    this.titles.addAll(_defaultTitles);
  }
  // _writeToFile = writeToFile;

  /// By default iSpectify write all Errors / Exceptions and logs in history list
  /// (base dart [List] field in core)
  /// If [true] - writing in history
  /// If [false] - not writing
  bool get useHistory => _useHistory && enabled;
  final bool _useHistory;

  /// By default iSpectify print all Errors / Exceptions and logs in console.
  /// If [true] - printing in console [false] - not printing.
  bool get useConsoleLogs => _useConsoleLogs && enabled;
  final bool _useConsoleLogs;

  /// Max records count in history list
  int get maxHistoryItems => _maxHistoryItems;
  final int _maxHistoryItems;

  /// The time format of the logs [TimeFormat]
  TimeFormat get timeFormat => _timeFormat;
  final TimeFormat _timeFormat;

  /// Use writing iSpectify records in file
  // bool get writeToFile => _writeToFile && enabled;
  // final bool _writeToFile;

  /// The main rule that is responsible
  /// for the operation of the package
  /// All log and handle error / exception methods are working when [true] and not working when [false]
  bool enabled;

  /// Custom Logger Titles.
  ///
  /// The `titles` field is intended for storing custom titles for the logger, associated with various log types.
  /// Each title is associated with a specific log type represented as an enum called `ISpectifyTitle`. This allows you to
  /// provide informative and unique titles for each log type, making logging more readable and informative.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final customTitles = {
  ///   ISpectifyTitle.info.key: "Information",
  ///   ISpectifyTitle.error.key: "Error",
  ///   ISpectifyTitle.warning.key: "Warning",
  /// };
  ///
  /// final logger = ISpectiy(
  ///   settings: ISpectifyOptions(
  ///     titles: customTitles,
  ///   )
  /// );
  /// ```
  final Map<String, String> titles = _defaultTitles;

  /// Custom Logger Colors.
  ///
  /// The `colors` field is designed for setting custom text colors for the logger, associated with specific log keys.
  /// Each color is associated with a specific log key represented as an enum called `ISpectifyKey`. This allows you to
  /// define custom text colors for each log key, enhancing the visual representation of logs in the console.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final customColors = {
  ///   ISpectifyKey.info.key: AnsiPen()..white(bold: true),
  ///   ISpectifyKey.error.key: AnsiPen()..red(bold: true),
  ///   ISpectifyKey.warning.key: AnsiPen()..yellow(bold: true),
  /// };
  ///
  /// final logger = ISpectiy(
  ///   settings: ISpectifyOptions(
  ///     colors: customColors,
  ///   )
  /// );
  /// ```
  ///
  /// By using the `colors` field, you can customize the text colors for specific log keys in the console.
  final Map<String, AnsiPen> colors = _defaultColors;

  String getTitleByLogKey(String key) {
    return titles[key] ?? key;
  }

  AnsiPen getAnsiPenByLogType(ISpectifyLogType type, {ISpectiyData? logData}) =>
      getPenByLogKey(type.key, fallbackPen: logData?.pen);

  AnsiPen getPenByLogKey(String key, {AnsiPen? fallbackPen}) {
    return colors[key] ?? fallbackPen ?? _fallbackPen;
  }

  ISpectifyOptions copyWith({
    bool? enabled,
    bool? useHistory,
    bool? useConsoleLogs,
    int? maxHistoryItems,
    Map<String, String>? titles,
    Map<String, AnsiPen>? colors,
  }) {
    return ISpectifyOptions(
      useHistory: useHistory ?? _useHistory,
      useConsoleLogs: useConsoleLogs ?? _useConsoleLogs,
      maxHistoryItems: maxHistoryItems ?? _maxHistoryItems,
      enabled: enabled ?? this.enabled,
      titles: titles ?? this.titles,
      colors: colors ?? this.colors,
    );
  }
}
