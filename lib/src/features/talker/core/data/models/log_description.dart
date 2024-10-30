class LogDescriptionItem {
  const LogDescriptionItem({
    required this.key,
    required this.description,
  });

  factory LogDescriptionItem.fromJson(Map<String, dynamic> json) => LogDescriptionItem(
        key: json['key'] as String,
        description: json['description'] as String,
      );

  static List<LogDescriptionItem> fromJsonList(List<dynamic> json) =>
      json.map((e) => LogDescriptionItem.fromJson(e as Map<String, dynamic>)).toList();

  final String key;
  final String description;

  Map<String, dynamic> toJson() => {
        'key': key,
        'description': description,
      };
}

class LogDescriptionPayload {
  const LogDescriptionPayload({
    required this.logKeys,
    required this.locale,
  });

  final List<String?> logKeys;
  final String locale;

  Map<String, dynamic> toJson() => {
        'log_keys': logKeys,
        'locale': locale,
      };
}
