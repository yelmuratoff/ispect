import 'package:ispect/src/features/talker/core/data/models/log_description.dart';
import 'package:ispect/src/features/talker/core/data/models/log_report.dart';

abstract interface class IAiRepository {
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  });

  Future<String?> generateReport({
    required AiLogsPayload payload,
  });
}
