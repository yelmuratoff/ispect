part of 'base.dart';

/// Log emitted when a Bloc or Cubit is instantiated.
///
/// Corresponds to [BlocObserver.onCreate].
/// Useful for tracking when lazy-loaded blocs are created.
final class BlocCreateLog extends BlocLifecycleLog {
  factory BlocCreateLog({
    required BlocBase<dynamic> bloc,
  }) {
    final typeName = bloc.runtimeType.toString();
    return BlocCreateLog._internal(bloc: bloc, typeName: typeName);
  }

  BlocCreateLog._internal({
    required super.bloc,
    required String typeName,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () => '$typeName created',
        );

  static const String logKey = 'bloc-create';
}
