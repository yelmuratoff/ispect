// ignore_for_file: avoid_setters_without_getters

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/services/google_ai.dart';
import 'package:ispect/src/common/utils/icons.dart';
import 'package:ispect/src/features/talker/bloc/ai_chat/ai_chat_bloc.dart';
import 'package:ispect/src/features/talker/bloc/ai_reporter/ai_reporter_cubit.dart';
import 'package:ispect/src/features/talker/bloc/log_descriptions/log_descriptions_cubit.dart';
import 'package:ispect/src/features/talker/core/data/datasource/ai_remote_ds.dart';
import 'package:ispect/src/features/talker/core/data/repositories/ai_repository.dart';
import 'package:provider/provider.dart';

/// `ISpectScopeModel` is a model class that holds the state of the ISpect scope.
class ISpectScopeModel with ChangeNotifier {
  bool _isISpectEnabled = false;
  bool _isPerformanceTrackingEnabled = false;
  ISpectOptions _options = const ISpectOptions(
    locale: Locale('en'),
  );
  ISpectTheme _theme = const ISpectTheme();

  GlobalKey<NavigatorState>? _navigatorKey;

  bool get isISpectEnabled => _isISpectEnabled;

  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;

  ISpectOptions get options => _options;

  ISpectTheme get theme => _theme;

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  set navigatorKey(GlobalKey<NavigatorState>? value) {
    _navigatorKey = value;
    notifyListeners();
  }

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
    ISpectGoogleAi.init(options.googleAiToken ?? '');
    notifyListeners();
  }

  void setTheme(ISpectTheme? theme) {
    if (theme != null) {
      _theme = theme.copyWith(
        logIcons: {
          ...typeIcons,
          ...theme.logIcons,
        },
      );
    }
    notifyListeners();
  }
}

/// `ISpectScopeWrapper` is a wrapper widget that provides the `ISpectScopeModel` to its children.
class ISpectScopeWrapper extends StatelessWidget {
  const ISpectScopeWrapper({
    required this.child,
    required this.options,
    required this.isISpectEnabled,
    this.theme,
    super.key,
  });
  final Widget child;
  final ISpectOptions options;
  final ISpectTheme? theme;
  final bool isISpectEnabled;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<ISpectScopeModel>(
        create: (_) => ISpectScopeModel()
          ..setISpect = isISpectEnabled
          ..setOptions(options)
          ..setTheme(theme),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<LogDescriptionsCubit>(
              create: (_) => LogDescriptionsCubit(
                aiRepository: const AiRepository(
                  remoteDataSource: AiRemoteDataSource(),
                ),
              ),
            ),
            BlocProvider<AiReporterCubit>(
              create: (_) => AiReporterCubit(
                aiRepository: const AiRepository(
                  remoteDataSource: AiRemoteDataSource(),
                ),
              ),
            ),
            BlocProvider<AiChatBloc>(
              create: (_) => AiChatBloc(
                aiRepository: const AiRepository(
                  remoteDataSource: AiRemoteDataSource(),
                ),
              ),
            ),
          ],
          child: child,
        ),
      );
}
