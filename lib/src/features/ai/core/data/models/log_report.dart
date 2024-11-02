class AiLogsPayload {
  const AiLogsPayload({
    required this.logsText,
    required this.locale,
    required this.possibleKeys,
    required this.now,
  });

  final String logsText;
  final String locale;
  final List<String> possibleKeys;
  final DateTime now;

  String text() =>
      (logsText.length > 5000) ? '${logsText.substring(0, 5000)}...' : logsText;

  Map<String, dynamic> toJson() => {
        'logs': logsText,
        'locale': locale,
        'possibleKeys': possibleKeys,
        'now': now.toIso8601String(),
      };
}
