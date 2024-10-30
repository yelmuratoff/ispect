part of 'ai_remote_ds.dart';

abstract interface class IAiRemoteDataSource {
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  });
}
