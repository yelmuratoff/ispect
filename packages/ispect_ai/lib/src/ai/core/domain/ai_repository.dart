import '../data/models/log_description.dart';
import '../data/models/log_report.dart';

abstract interface class IAiRepository {
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  });

  Future<String?> generateReport({
    required AiLogsPayload payload,
  });
}
