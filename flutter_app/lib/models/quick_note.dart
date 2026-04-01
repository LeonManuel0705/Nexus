class QuickNote {
  final String id;
  final String type;
  final String? title;
  final String content;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuickNote({
    required this.id,
    this.type = 'note',
    this.title,
    required this.content,
    this.wordCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'content': content,
      'word_count': wordCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory QuickNote.fromMap(Map<String, dynamic> map) {
    return QuickNote(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'note',
      title: map['title'] as String?,
      content: map['content'] as String,
      wordCount: map['word_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  QuickNote copyWith({
    String? id,
    String? type,
    String? title,
    String? content,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuickNote(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int calculateWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  String get preview {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    if (content.isEmpty) return '';
    final lines = content.split('\n');
    final firstLine = lines.first.trim();
    if (firstLine.length > 50) {
      return '${firstLine.substring(0, 50)}...';
    }
    return firstLine;
  }

  String get typeLabel {
    switch (type) {
      case 'idea':
        return 'Idee';
      case 'note':
      default:
        return 'Notiz';
    }
  }
}