import 'dart:typed_data';

class Drawing {
  final String id;
  final String name;
  final Uint8List imageData;
  final String backgroundType;
  final DateTime createdAt;
  final DateTime updatedAt;

  Drawing({
    required this.id,
    required this.name,
    required this.imageData,
    this.backgroundType = 'blank',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_data': imageData,
      'background_type': backgroundType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Drawing.fromMap(Map<String, dynamic> map) {
    return Drawing(
      id: map['id'] as String,
      name: map['name'] as String,
      imageData: map['image_data'] as Uint8List,
      backgroundType: map['background_type'] as String? ?? 'blank',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Drawing copyWith({
    String? id,
    String? name,
    Uint8List? imageData,
    String? backgroundType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Drawing(
      id: id ?? this.id,
      name: name ?? this.name,
      imageData: imageData ?? this.imageData,
      backgroundType: backgroundType ?? this.backgroundType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
