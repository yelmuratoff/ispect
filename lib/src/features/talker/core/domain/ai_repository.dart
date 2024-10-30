import 'package:ispect/src/features/talker/core/data/models/log_description.dart';

abstract interface class IAiRepository {
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  });
}
