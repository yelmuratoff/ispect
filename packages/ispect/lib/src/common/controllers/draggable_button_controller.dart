import 'package:flutter/material.dart';

final class DraggableButtonController extends ChangeNotifier {
  bool _inLoggerPage = false;

  bool get inLoggerPage => _inLoggerPage;

  void setInLoggerPage({
    required bool inLoggerPage,
  }) {
    _inLoggerPage = inLoggerPage;
    notifyListeners();
  }

  void reset() {
    _inLoggerPage = false;
    notifyListeners();
  }
}
