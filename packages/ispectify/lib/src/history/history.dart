import 'package:ispectify/ispectify.dart';

abstract class LogHistory {
  List<ISpectifyData> get history;

  void clear();

  void add(ISpectifyData data);
}

class DefaultISpectifyHistory implements LogHistory {
  DefaultISpectifyHistory(this.settings, {List<ISpectifyData>? history}) {
    if (history != null) {
      _history.addAll(history);
    }
  }

  final ISpectifyOptions settings;

  final _history = <ISpectifyData>[];

  @override
  List<ISpectifyData> get history => _history;

  @override
  void clear() {
    if (settings.useHistory) {
      _history.clear();
    }
  }

  @override
  void add(ISpectifyData data) {
    if (settings.useHistory && settings.enabled) {
      if (settings.maxHistoryItems <= _history.length) {
        _history.removeAt(0);
      }
      _history.add(data);
    }
  }
}
