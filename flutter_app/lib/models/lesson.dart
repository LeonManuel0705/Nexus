class Lesson {
  final String id;
  final String subject;
  final String? teacher;
  final String? room;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int lessonNumber;
  final String? color;
  final String? lessonType; // Seminarkurs, Grundkurs, Leistungskurs
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson({
    required this.id,
    required this.subject,
    this.teacher,
    this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.lessonNumber,
    this.color,
    this.lessonType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'lesson_number': lessonNumber,
      'color': color,
      'lesson_type': lessonType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      subject: map['subject'],
      teacher: map['teacher'],
      room: map['room'],
      dayOfWeek: map['day_of_week'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      lessonNumber: map['lesson_number'],
      color: map['color'],
      lessonType: map['lesson_type'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Lesson copyWith({
    String? id,
    String? subject,
    String? teacher,
    String? room,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? lessonNumber,
    String? color,
    String? lessonType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      color: color ?? this.color,
      lessonType: lessonType ?? this.lessonType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get timeRange => '$startTime - $endTime';

  static String dayName(int day) {
    const days = ['', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    return days[day];
  }

  static const lessonTypes = ['Grundkurs', 'Leistungskurs', 'Seminarkurs'];
}
