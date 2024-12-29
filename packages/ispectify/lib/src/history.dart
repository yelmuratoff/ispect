import 'package:ispectify/ispectify.dart';

class DefaultISpectifyHistory implements LogHistory {
  DefaultISpectifyHistory(this.settings, {List<ISpectiyData>? history}) {
    if (history != null) {
      _history.addAll(history);
    }
  }

  final ISpectifyOptions settings;

  final _history = <ISpectiyData>[];

  @override
  List<ISpectiyData> get history => _history;

  @override
  void clear() {
    if (settings.useHistory) {
      _history.clear();
    }
  }

  @override
  void add(ISpectiyData data) {
    if (settings.useHistory && settings.enabled) {
      if (settings.maxHistoryItems <= _history.length) {
        _history.removeAt(0);
      }
      _history.add(data);
    }
  }
}

abstract class LogHistory {
  List<ISpectiyData> get history;

  void clear();

  void add(ISpectiyData data);
}
