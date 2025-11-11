import 'package:ispect/ispect.dart';

/// Service responsible for importing/validating logs content.
class LogImportService {
  const LogImportService({LogsJsonService? logsJsonService})
      : _logsJsonService = logsJsonService ?? const LogsJsonService();

  final LogsJsonService _logsJsonService;

  Future<List<ISpectLogData>> importLogsFromJson(String jsonContent) async =>
      _logsJsonService.importFromJson(jsonContent);

  bool validateLogsJsonContent(String jsonContent) =>
      _logsJsonService.validateJsonStructure(jsonContent);
}
