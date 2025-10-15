part of 'base.dart';

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
