class JiraSprint {
  const JiraSprint({
    required this.id,
    required this.self,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.state,
    required this.goal,
  });

  factory JiraSprint.fromJson(Map<String, Object?> json) => JiraSprint(
        id: (json['id'] as num?)?.toInt() ?? 0,
        self: json['self'] as String? ?? '',
        name: json['name'] as String? ?? '',
        startDate: json['startDate'] == null ? null : DateTime.parse(json['startDate']! as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate']! as String),
        state: json['state'] as String? ?? '',
        goal: json['goal'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'self': self,
        'name': name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'state': state,
        'goal': goal,
      };

  final int id;
  final String self;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String state;
  final String goal;
}
