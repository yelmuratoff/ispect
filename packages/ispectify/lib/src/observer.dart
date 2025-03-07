import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/error.dart';
import 'package:ispectify/src/models/exception.dart';

abstract class ISpectifyObserver {
  const ISpectifyObserver();

  void onError(ISpectifyError err) {}

  void onException(ISpectifyException err) {}

  void onLog(ISpectifyData log) {}
}
