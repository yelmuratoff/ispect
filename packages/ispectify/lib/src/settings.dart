import 'package:ispectify/ispectify.dart';

final _defaultTitles = {
  ISpectifyLogType.critical.key: 'critical',
  ISpectifyLogType.warning.key: 'warning',
  ISpectifyLogType.verbose.key: 'verbose',
  ISpectifyLogType.info.key: 'info',
  ISpectifyLogType.debug.key: 'debug',
  ISpectifyLogType.error.key: 'error',
  ISpectifyLogType.exception.key: 'exception',
  ISpectifyLogType.httpError.key: 'http-error',
  ISpectifyLogType.httpRequest.key: 'http-request',
  ISpectifyLogType.httpResponse.key: 'http-response',
  ISpectifyLogType.blocEvent.key: 'bloc-event',
  ISpectifyLogType.blocTransition.key: 'bloc-transition',
  ISpectifyLogType.blocCreate.key: 'bloc-create',
  ISpectifyLogType.blocClose.key: 'bloc-close',
  ISpectifyLogType.riverpodAdd.key: 'riverpod-add',
  ISpectifyLogType.riverpodUpdate.key: 'riverpod-update',
  ISpectifyLogType.riverpodDispose.key: 'riverpod-dispose',
  ISpectifyLogType.riverpodFail.key: 'riverpod-fail',
  ISpectifyLogType.route.key: 'route',
};

final _defaultColors = {
  ISpectifyLogType.critical.key: AnsiPen()..red(),
  ISpectifyLogType.warning.key: AnsiPen()..yellow(),
  ISpectifyLogType.verbose.key: AnsiPen()..gray(),
  ISpectifyLogType.info.key: AnsiPen()..blue(),
  ISpectifyLogType.debug.key: AnsiPen()..gray(),
  ISpectifyLogType.error.key: AnsiPen()..red(),
  ISpectifyLogType.exception.key: AnsiPen()..red(),
  ISpectifyLogType.httpError.key: AnsiPen()..red(),
  ISpectifyLogType.httpRequest.key: AnsiPen()..xterm(219),
  ISpectifyLogType.httpResponse.key: AnsiPen()..xterm(46),
  ISpectifyLogType.blocEvent.key: AnsiPen()..xterm(51),
  ISpectifyLogType.blocTransition.key: AnsiPen()..xterm(49),
  ISpectifyLogType.blocCreate.key: AnsiPen()..xterm(35),
  ISpectifyLogType.blocClose.key: AnsiPen()..xterm(198),
  ISpectifyLogType.riverpodAdd.key: AnsiPen()..xterm(51),
  ISpectifyLogType.riverpodUpdate.key: AnsiPen()..xterm(49),
  ISpectifyLogType.riverpodDispose.key: AnsiPen()..xterm(198),
  ISpectifyLogType.riverpodFail.key: AnsiPen()..red(),
  ISpectifyLogType.route.key: AnsiPen()..xterm(135),
};

final _fallbackPen = AnsiPen()..gray();

class ISpectifyOptions {
  ISpectifyOptions({
    this.enabled = true,
    bool useHistory = true,
    bool useConsoleLogs = true,
    int maxHistoryItems = 1000,
    Map<String, String>? titles,
    Map<String, AnsiPen>? colors,
  })  : _useHistory = useHistory,
        _useConsoleLogs = useConsoleLogs,
        _maxHistoryItems = maxHistoryItems {
    if (colors != null) {
      _defaultColors.addAll(colors);
    }
    if (titles != null) {
      _defaultTitles.addAll(titles);
    }
    this.colors.addAll(_defaultColors);
    this.titles.addAll(_defaultTitles);
  }

  bool get useHistory => _useHistory && enabled;
  final bool _useHistory;

  bool get useConsoleLogs => _useConsoleLogs && enabled;
  final bool _useConsoleLogs;

  int get maxHistoryItems => _maxHistoryItems;
  final int _maxHistoryItems;

  bool enabled;

  final Map<String, String> titles = _defaultTitles;

  final Map<String, AnsiPen> colors = _defaultColors;

  String titleByKey(String key) {
    return titles[key] ?? key;
  }

  AnsiPen penByKey(String key, {AnsiPen? fallbackPen}) {
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
