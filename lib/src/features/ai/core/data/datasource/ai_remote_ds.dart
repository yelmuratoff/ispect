import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ispect/src/common/services/google_ai.dart';
import 'package:ispect/src/common/utils/date_utils.dart';
import 'package:ispect/src/features/ai/core/data/models/log_description.dart';
import 'package:ispect/src/features/ai/core/data/models/log_report.dart';

part 'interface.dart';

final class AiRemoteDataSource implements IAiRemoteDataSource {
  const AiRemoteDataSource();

  @override
  Future<List<LogDescriptionItem>> generateLogDescription({
    required LogDescriptionPayload payload,
  }) async {
    try {
      final prompt =
          '''Generate descriptions of logs for monitoring inside the application for me.
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
      final response =
          await ISpectGoogleAi.instance.model.generateContent(content);

      final result = jsonDecode(response.text ?? '{}') as Map<String, dynamic>;

      final list = result['data'] as List? ?? [];

      return LogDescriptionItem.fromJsonList(list);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> generateReport({
    required AiLogsPayload payload,
  }) async {
    try {
      final prompt = '''
        Locale code for report - ${payload.locale}.
        Please, generate a report on the monitoring logs for me on this language (${payload.locale}).
        It is important. Do not forget about it. This message only on english only for prompt.
        All possible keys: ${payload.possibleKeys.join(', ')}.
        Date: ${payload.now.toIso8601String()}.
        Also, please format date and time in the report in a human-readable format.
        Generate a detailed report on the monitoring logs, keep order.
        The report should be more detailed specifically for the developer.
        Design everything beautifully and clearly, using bullet points where it is needed. You can use emojis, MD format.
        Take the latest logs where there are errors as a basis and describe exactly how the failure occurred.
        Also, give some statistics on logs, for example, how many times a particular type of log occurs, etc.
        Which is the most popular one. Which failure occurs most often. etc.
        If the logs are repeated, then they need to be combined into one item.
        It is not necessary to give a list of all logs, generalize. You are a reporter and a sammariser, so you need to generalize more and give valuable information.
        If these are different actions of the same log, then they need to be logically explained.
        If it is an 'http error', then add the url and the error code. Try to describe what the problem was.
        If there is an 'analytics' log type, then do an analysis based on them. For example, how many users visited the page.
        The report should be useful for both the developer and the analyst.
        It is not necessary to show incomprehensible symbols and words in errors, or something that does not give a clear picture. Only facts and useful information.
        ''';

      final file = await generateFile(payload.logsText);

      final bytes = file.readAsBytesSync();

      final content = [
        Content.text(prompt),
        Content.data(
          'text/plain',
          bytes,
        ),
      ];

      final response = await ISpectGoogleAi.instance.model.generateContent(
        content,
        generationConfig: GenerationConfig(responseMimeType: 'text/plain'),
      );

      final report = response.text;

      return report;
    } catch (e) {
      rethrow;
    }
  }
}
