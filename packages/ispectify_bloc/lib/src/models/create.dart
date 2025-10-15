part of 'base.dart';

/// Log emitted when a Bloc or Cubit is instantiated.
///
/// Corresponds to [BlocObserver.onCreate].
/// Useful for tracking when lazy-loaded blocs are created.
final class BlocCreateLog extends BlocLifecycleLog {
  BlocCreateLog({
    required super.bloc,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () => '${bloc.runtimeType} created',
        );

  static const String logKey = 'bloc-create';
}
