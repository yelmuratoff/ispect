library ispectify_bloc_lifecycle_logs;

import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

part 'close.dart';
part 'create.dart';
part 'done.dart';
part 'error.dart';
part 'event.dart';
part 'state.dart';
part 'transition.dart';

/// Base class for all Bloc lifecycle logs emitted to ISpectify.
///
/// Provides a shared contract for building messages lazily while keeping the
/// underlying [ISpectifyData] immutable.
sealed class BlocLifecycleLog extends ISpectifyData {
  BlocLifecycleLog({
    required this.bloc,
    required super.key,
    required super.title,
    required String Function() messageBuilder,
    Map<String, dynamic>? additionalData,
    Object? exception,
    Error? error,
    StackTrace? stackTrace,
    LogLevel? logLevel,
  })  : _messageBuilder = messageBuilder,
        super(
          '',
          exception: exception,
          error: error,
          stackTrace: stackTrace,
          additionalData: additionalData,
          logLevel: logLevel,
        );

  /// The originating Bloc or Cubit.
  final BlocBase<dynamic> bloc;

  final String Function() _messageBuilder;

  @override
  String get messageText => _messageBuilder();
}
