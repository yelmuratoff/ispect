import 'package:ispect/src/features/ai/core/data/datasource/ai_remote_ds.dart';
import 'package:ispect/src/features/ai/core/data/models/log_description.dart';
import 'package:ispect/src/features/ai/core/data/models/log_report.dart';
import 'package:ispect/src/features/ai/core/domain/ai_repository.dart';

final class AiRepository implements IAiRepository {
  const AiRepository({
    required IAiRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final IAiRemoteDataSource _remoteDataSource;

  @override
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  }) async {
    try {
      return await _remoteDataSource.generateLogDescription(payload: payload);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> generateReport({
    required AiLogsPayload payload,
  }) async {
    try {
      return await _remoteDataSource.generateReport(payload: payload);
    } catch (e) {
      rethrow;
    }
  }
}
