part of 'log_descriptions_cubit.dart';

@immutable
sealed class LogDescriptionsState {
  const LogDescriptionsState();
}

final class LogDescriptionsInitial extends LogDescriptionsState {
  const LogDescriptionsInitial();
}

final class LogDescriptionsLoading extends LogDescriptionsState {
  const LogDescriptionsLoading();
}

final class LogDescriptionsLoaded extends LogDescriptionsState {
  const LogDescriptionsLoaded({
    required this.logDescriptions,
  });

  final List<LogDescriptionItem> logDescriptions;
}

final class LogDescriptionsError extends LogDescriptionsState {
  const LogDescriptionsError({
    required this.message,
  });

  final String message;
}
