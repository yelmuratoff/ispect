class JiraBoard {
  const JiraBoard({
    required this.id,
    required this.self,
    required this.name,
    required this.type,
  });

  factory JiraBoard.fromJson(Map<String, Object?> json) => JiraBoard(
        id: (json['id'] as num?)?.toInt() ?? 0,
        self: json['self'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'self': self,
        'name': name,
        'type': type,
      };

  final int id;
  final String self;
  final String name;
  final String type;
}
