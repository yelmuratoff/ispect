import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ispect/src/common/services/google_ai.dart';
import 'package:ispect/src/features/talker/core/data/models/log_description.dart';
import 'package:ispect/src/features/talker/core/data/models/log_report.dart';
import 'package:path_provider/path_provider.dart';

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

  @override
  Future<String?> generateReport({
    required AiLogsPayload payload,
  }) async {
    try {
      final prompt = '''Generate a detailed report on the monitoring logs, keep order.
        The report should be more detailed specifically for the developer.
        Take the latest logs where there are errors as a basis and describe exactly how the failure occurred.
        Also, give some statistics on logs, for example, how many times a particular type of log occurs.
        Which is the most popular one. Which failure occurs most often. etc.
        Language of report - ${payload.locale}.
        Response example in JSON schema:
        {
        "report": "Sample report."
        }
        ''';

      final file = await generateFile(payload.logs);

      final bytes = file.readAsBytesSync();

      final content = [
        Content.text(prompt),
        Content.data(
          'text/plain',
          bytes,
        ),
      ];

      final response = await ISpectGoogleAi.instance.model.generateContent(content);

      final result = jsonDecode(response.text?.trim() ?? '{}') as Map<String, dynamic>;

      final report = result['report'] as String?;

      return report;
    } catch (e) {
      rethrow;
    }
  }
}

Future<File> generateFile(String logs) async {
  final dir = await getTemporaryDirectory();
  final dirPath = dir.path;
  final fmtDate = DateTime.now().toString().replaceAll(':', ' ');
  final file = await File('$dirPath/talker_logs_$fmtDate.txt').create(recursive: true);
  await file.writeAsString(logs);
  return file;
}
