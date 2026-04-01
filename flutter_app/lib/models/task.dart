class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool completed;
  final String priority;
  final String category;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? repeatType;
  final List<int>? repeatWeekdays;
  final DateTime? repeatEndDate;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.completed = false,
    this.priority = 'medium',
    this.category = 'general',
    this.estimatedMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.repeatType,
    this.repeatWeekdays,
    this.repeatEndDate,
  });

  static const timeEstimates = {
    15: '15 Min',
    30: '30 Min',
    45: '45 Min',
    60: '1 Std',
    90: '1,5 Std',
    120: '2 Std',
    180: '3 Std',
    240: '4 Std',
  };

  static const categories = {
    'general': 'Allgemein',
    'school': 'Schule',
    'training': 'Training',
    'project': 'Projekt',
    'personal': 'Privat',
  };

  static const repeatTypes = {
    'daily': 'Täglich',
    'weekly': 'Wöchentlich',
    'monthly': 'Monatlich',
    'yearly': 'Jährlich',
    'custom': 'Benutzerdefiniert',
  };

  static const weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'completed': completed ? 1 : 0,
      'priority': priority,
      'category': category,
      'estimated_minutes': estimatedMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'repeat_type': repeatType,
      'repeat_weekdays': repeatWeekdays?.join(','),
      'repeat_end_date': repeatEndDate?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    List<int>? weekdays;
    if (map['repeat_weekdays'] != null && (map['repeat_weekdays'] as String).isNotEmpty) {
      weekdays = (map['repeat_weekdays'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();
    }

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      completed: map['completed'] == 1,
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'general',
      estimatedMinutes: map['estimated_minutes'] as int?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      repeatType: map['repeat_type'] as String?,
      repeatWeekdays: weekdays,
      repeatEndDate: map['repeat_end_date'] != null
          ? DateTime.parse(map['repeat_end_date'])
          : null,
    );
  }

  static const _sentinel = Object();

  Task copyWith({
    String? id,
    String? title,
    Object? description = _sentinel,
    Object? dueDate = _sentinel,
    bool? completed,
    String? priority,
    String? category,
    Object? estimatedMinutes = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? repeatType = _sentinel,
    Object? repeatWeekdays = _sentinel,
    Object? repeatEndDate = _sentinel,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description == _sentinel ? this.description : description as String?,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes == _sentinel ? this.estimatedMinutes : estimatedMinutes as int?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      repeatType: repeatType == _sentinel ? this.repeatType : repeatType as String?,
      repeatWeekdays: repeatWeekdays == _sentinel ? this.repeatWeekdays : repeatWeekdays as List<int>?,
      repeatEndDate: repeatEndDate == _sentinel ? this.repeatEndDate : repeatEndDate as DateTime?,
    );
  }
}
