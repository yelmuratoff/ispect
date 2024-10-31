class AiLogsPayload {
  const AiLogsPayload({
    required this.logsText,
    required this.locale,
  });

  final String logsText;
  final String locale;

  String text() => (logsText.length > 5000) ? '${logsText.substring(0, 5000)}...' : logsText;

  Map<String, dynamic> toJson() => {
        'logs': logsText,
        'locale': locale,
      };
}
