class AiLogsPayload {
  const AiLogsPayload({
    required this.logs,
    required this.locale,
  });

  final String logs;
  final String locale;

  Map<String, dynamic> toJson() => {
        'logs': logs,
        'locale': locale,
      };
}
