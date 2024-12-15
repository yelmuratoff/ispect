part of 'ai_reporter_cubit.dart';

@immutable
sealed class AiReporterState {
  const AiReporterState();
}

final class AiReporterInitial extends AiReporterState {
  const AiReporterInitial();
}

final class AiReporterLoading extends AiReporterState {
  const AiReporterLoading();
}

final class AiReporterLoaded extends AiReporterState {
  const AiReporterLoaded({
    required this.report,
  });

  final String report;
}

final class AiReporterError extends AiReporterState {
  const AiReporterError({
    required this.message,
  });

  final String message;
}
