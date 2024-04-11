import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/ispect_options.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// `ISpectScopeModel` is a model class that holds the state of the ISpect scope.
class ISpectScopeModel with ChangeNotifier {
  bool _isISpectEnabled = false;
  bool _isPerformanceTrackingEnabled = false;
  ISpectOptions _options = ISpectOptions(
    talker: Talker(),
    themeMode: ThemeMode.system,
    lightTheme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    locale: const Locale('en'),
  );

  bool get isISpectEnabled => _isISpectEnabled;

  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;

  ISpectOptions get options => _options;

  void toggleISpect() {
    _isISpectEnabled = !_isISpectEnabled;
    notifyListeners();
  }

  set setISpect(bool value) {
    _isISpectEnabled = value;
    notifyListeners();
  }

  void togglePerformanceTracking() {
    _isPerformanceTrackingEnabled = !_isPerformanceTrackingEnabled;
    notifyListeners();
  }

  set setPerformanceTracking(bool value) {
    _isPerformanceTrackingEnabled = value;
    notifyListeners();
  }

  void setOptions(ISpectOptions options) {
    _options = options;
    notifyListeners();
  }
}

/// `ISpectScopeWrapper` is a wrapper widget that provides the `ISpectScopeModel` to its children.
class ISpectScopeWrapper extends StatelessWidget {
  final Widget child;
  final ISpectOptions options;
  final bool isISpectEnabled;

  const ISpectScopeWrapper({
    super.key,
    required this.child,
    required this.options,
    required this.isISpectEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ISpectScopeModel>(
      create: (context) => ISpectScopeModel()
        ..setOptions(options)
        ..setISpect = isISpectEnabled,
      child: child,
    );
  }
}
