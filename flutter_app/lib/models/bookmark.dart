class Bookmark {
  final String id;
  final String title;
  final String url;
  final String category;
  final String? favicon;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const List<String> categories = ['Work', 'Personal', 'Dev', 'Other'];

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.category = 'Other',
    this.favicon,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'category': category,
      'favicon': favicon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      category: map['category'] as String? ?? 'Other',
      favicon: map['favicon'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Bookmark copyWith({
    String? id,
    String? title,
    String? url,
    String? category,
    String? favicon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      category: category ?? this.category,
      favicon: favicon ?? this.favicon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }
}
