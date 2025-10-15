part of 'base.dart';

/// Log emitted when a Bloc or Cubit is closed.
///
/// Corresponds to [BlocObserver.onClose].
/// Called just before the bloc is closed and will no longer emit states.
final class BlocCloseLog extends BlocLifecycleLog {
  BlocCloseLog({
    required super.bloc,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () => '${bloc.runtimeType} closed',
        );

  static const String logKey = 'bloc-close';
}
