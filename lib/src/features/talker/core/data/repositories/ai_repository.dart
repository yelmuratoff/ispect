import 'package:ispect/src/features/talker/core/data/datasource/ai_remote_ds.dart';
import 'package:ispect/src/features/talker/core/data/models/log_description.dart';
import 'package:ispect/src/features/talker/core/domain/ai_repository.dart';

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
}
