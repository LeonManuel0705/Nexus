class TimetablePeriod {
  final int id;
  final int periodNumber;
  final String? name;
  final String startTime;
  final String endTime;
  final bool hasSplit;
  final int? splitBreakMinutes;
  final DateTime createdAt;

  TimetablePeriod({
    required this.id,
    required this.periodNumber,
    this.name,
    required this.startTime,
    required this.endTime,
    this.hasSplit = false,
    this.splitBreakMinutes,
    required this.createdAt,
  });

  String get displayName => name ?? '$periodNumber. Stunde';

  String? get firstHalfEnd {
    if (!hasSplit) return endTime;
    return _calculateMidpoint();
  }

  String? get secondHalfStart {
    if (!hasSplit) return null;
    return _calculateSecondHalfStart();
  }

  String get timeRange => '$startTime - $endTime';

  String? get firstHalfTimeRange {
    if (!hasSplit) return null;
    return '$startTime - $firstHalfEnd';
  }

  String? get secondHalfTimeRange {
    if (!hasSplit) return null;
    return '$secondHalfStart - $endTime';
  }

  String _calculateMidpoint() {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final breakMinutes = splitBreakMinutes ?? 5;

    final totalDuration = endMinutes - startMinutes - breakMinutes;
    final firstHalfDuration = totalDuration ~/ 2;
    final midMinutes = startMinutes + firstHalfDuration;

    final hours = midMinutes ~/ 60;
    final minutes = midMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _calculateSecondHalfStart() {
    final midpoint = _calculateMidpoint();
    final midParts = midpoint.split(':');
    final midMinutes = int.parse(midParts[0]) * 60 + int.parse(midParts[1]);
    final breakMinutes = splitBreakMinutes ?? 5;

    final secondHalfStartMinutes = midMinutes + breakMinutes;
    final hours = secondHalfStartMinutes ~/ 60;
    final minutes = secondHalfStartMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  factory TimetablePeriod.fromMap(Map<String, dynamic> map) {
    return TimetablePeriod(
      id: map['id'] as int,
      periodNumber: map['period_number'] as int,
      name: map['name'] as String?,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      hasSplit: (map['has_split'] as int?) == 1,
      splitBreakMinutes: map['split_break_minutes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_number': periodNumber,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'has_split': hasSplit ? 1 : 0,
      'split_break_minutes': splitBreakMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TimetablePeriod copyWith({
    int? id,
    int? periodNumber,
    String? name,
    String? startTime,
    String? endTime,
    bool? hasSplit,
    int? splitBreakMinutes,
    DateTime? createdAt,
  }) {
    return TimetablePeriod(
      id: id ?? this.id,
      periodNumber: periodNumber ?? this.periodNumber,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hasSplit: hasSplit ?? this.hasSplit,
      splitBreakMinutes: splitBreakMinutes ?? this.splitBreakMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
