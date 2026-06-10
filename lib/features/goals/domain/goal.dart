enum GoalType {
  daily,
  weekly,
  monthly,
  longTerm;

  String get label => switch (this) {
        GoalType.daily => 'Daily',
        GoalType.weekly => 'Weekly',
        GoalType.monthly => 'Monthly',
        GoalType.longTerm => 'Long-term',
      };
}

/// A user goal with progress tracking and optional milestones.
class Goal {
  Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.type = GoalType.weekly,
    this.target = 7,
    this.progress = 0,
    this.colorValue = 0xFF818CF8,
    DateTime? createdAt,
    this.deadline,
    this.milestones = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final GoalType type;
  final int target;
  final int progress;
  final int colorValue;
  final DateTime createdAt;
  final DateTime? deadline;
  final List<String> milestones;

  double get percent => target == 0 ? 0 : (progress / target).clamp(0, 1);
  bool get isComplete => progress >= target;

  Goal copyWith({String? title, int? progress, int? target}) => Goal(
        id: id,
        title: title ?? this.title,
        description: description,
        type: type,
        target: target ?? this.target,
        progress: progress ?? this.progress,
        colorValue: colorValue,
        createdAt: createdAt,
        deadline: deadline,
        milestones: milestones,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'target': target,
        'progress': progress,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'milestones': milestones,
      };

  factory Goal.fromJson(Map json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: GoalType.values.firstWhere((t) => t.name == json['type'], orElse: () => GoalType.weekly),
        target: json['target'] as int? ?? 1,
        progress: json['progress'] as int? ?? 0,
        colorValue: json['colorValue'] as int? ?? 0xFF818CF8,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
        milestones: (json['milestones'] as List?)?.map((e) => e as String).toList() ?? const [],
      );
}
