part of 'base.dart';

/// Log emitted when a Bloc or Cubit is closed.
///
/// Corresponds to [BlocObserver.onClose].
/// Called just before the bloc is closed and will no longer emit states.
final class BlocCloseLog extends BlocLifecycleLog {
  factory BlocCloseLog({
    required BlocBase<dynamic> bloc,
  }) {
    final typeName = bloc.runtimeType.toString();
    return BlocCloseLog._internal(bloc: bloc, typeName: typeName);
  }

  BlocCloseLog._internal({
    required super.bloc,
    required String typeName,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () => '$typeName closed',
        );

  static const String logKey = 'bloc-close';
}
