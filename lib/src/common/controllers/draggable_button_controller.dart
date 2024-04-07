import 'dart:async';

import 'package:flutter/material.dart';

/// `DraggableButtonController` is a controller class for the `DraggableButton` widget.
final class DraggableButtonController extends ChangeNotifier {
  double _xPos = 0.0;
  double _yPos = 600.0;
  bool _isCollapsed = false;
  Timer? _collapseTimer;
  bool _inLoggerPage = false;

  double get xPos => _xPos;
  double get yPos => _yPos;
  bool get isCollapsed => _isCollapsed;
  Timer? get collapseTimer => _collapseTimer;
  bool get inLoggerPage => _inLoggerPage;

  void startAutoCollapseTimer() {
    cancelAutoCollapseTimer();
    _collapseTimer = Timer(const Duration(seconds: 5), () {
      _isCollapsed = true;
      notifyListeners();
    });
  }

  void cancelAutoCollapseTimer() {
    _collapseTimer?.cancel();
  }

  set xPos(double xPos) {
    _xPos = xPos;
    notifyListeners();
  }

  set yPos(double yPos) {
    _yPos = yPos;
    notifyListeners();
  }

  void setIsCollapsed(bool isCollapsed) {
    _isCollapsed = isCollapsed;
    notifyListeners();
  }

  void setInLoggerPage(bool inLoggerPage) {
    _inLoggerPage = inLoggerPage;
    notifyListeners();
  }

  void reset() {
    _xPos = 0.0;
    _yPos = 600.0;
    _isCollapsed = false;
    _collapseTimer = null;
    _inLoggerPage = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }
}
