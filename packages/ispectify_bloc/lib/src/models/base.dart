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

/// Base class for all Bloc lifecycle logs emitted to ISpectLogger.
///
/// Provides a shared contract for building messages lazily while keeping the
/// underlying [ISpectLogData] immutable.
///
/// Stores only the bloc's runtime type name and hash code instead of a live
/// reference to the [BlocBase] instance, so logs do not prevent garbage
/// collection of closed blocs.
sealed class BlocLifecycleLog extends ISpectLogData {
  BlocLifecycleLog({
    required BlocBase<dynamic> bloc,
    required super.key,
    required super.title,
    required String Function() messageBuilder,
    Map<String, dynamic>? additionalData,
    Object? exception,
    Error? error,
    StackTrace? stackTrace,
    LogLevel? logLevel,
  })  : blocTypeName = bloc.runtimeType.toString(),
        blocHashCode = bloc.hashCode,
        _messageBuilder = messageBuilder,
        super(
          '',
          exception: exception,
          error: error,
          stackTrace: stackTrace,
          additionalData: additionalData,
          logLevel: logLevel,
        );

  /// The runtime type name of the originating Bloc or Cubit.
  final String blocTypeName;

  /// The hash code of the originating Bloc or Cubit (for identification).
  final int blocHashCode;

  final String Function() _messageBuilder;

  @override
  String get messageText => _messageBuilder();
}
