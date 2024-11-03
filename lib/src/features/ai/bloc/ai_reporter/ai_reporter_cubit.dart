import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/src/features/ai/core/data/models/log_report.dart';
import 'package:ispect/src/features/ai/core/domain/ai_repository.dart';
import 'package:meta/meta.dart';

part 'ai_reporter_state.dart';

class AiReporterCubit extends Cubit<AiReporterState> {
  AiReporterCubit({
    required this.aiRepository,
  }) : super(const AiReporterInitial());

  final IAiRepository aiRepository;

  Future<void> generateReport({
    required AiLogsPayload payload,
  }) async {
    emit(const AiReporterLoading());
    try {
      final report = await aiRepository.generateReport(payload: payload);
      if (report != null) {
        emit(AiReporterLoaded(report: report));
      } else {
        emit(const AiReporterError(message: 'No report generated'));
      }
    } catch (e) {
      emit(AiReporterError(message: e.toString()));
    }
  }
}
