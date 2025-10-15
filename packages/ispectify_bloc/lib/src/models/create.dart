part of 'base.dart';

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
