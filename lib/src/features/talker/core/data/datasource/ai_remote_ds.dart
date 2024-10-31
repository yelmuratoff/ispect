import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ispect/src/common/services/google_ai.dart';
import 'package:ispect/src/features/talker/core/data/models/log_description.dart';

part 'interface.dart';

final class AiRemoteDataSource implements IAiRemoteDataSource {
  const AiRemoteDataSource();

  @override
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  }) async {
    try {
      final prompt = '''Generate descriptions of logs for monitoring inside the application for me.
        Language of descriptions - ${payload.locale}.
        For example:
        "info" - An informative log.
        "route" - The navigation log between the screens. etc.
        Use only this keys:
        Logs: ${payload.logKeys.join(', ')}.
        Do not add another logs types.

        The response must be in JSON schema. Wihtout anything else. It is important.
        In the format:
        {
        "data": [
        {
          "key": "info",
          "description": "The log is informative in nature."
        },
        {
          "key": "route",
          "description": "The navigation log between the screens."
        }
        ]}
        ''';
      final content = [Content.text(prompt)];
      final response = await ISpectGoogleAi.instance.model.generateContent(content);

      final result = jsonDecode(response.text ?? '{}') as Map<String, dynamic>;

      final list = result['data'] as List? ?? [];

      return LogDescriptionItem.fromJsonList(list);
    } catch (e) {
      rethrow;
    }
  }
}
