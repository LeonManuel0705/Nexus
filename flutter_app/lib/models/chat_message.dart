import 'dart:convert';

class ChatMessage {
  final String id;
  final String content;
  final String role;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.metadata,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      content: map['content'] as String,
      role: map['role'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ChatMessage.user({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      role: 'user',
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory ChatMessage.assistant({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      role: 'assistant',
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}