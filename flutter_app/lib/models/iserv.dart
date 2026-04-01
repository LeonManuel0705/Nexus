import 'dart:convert';
import 'event.dart';

class IServCredentials {
  final String username;
  final String iservUrl;
  final String credentialKey;
  final DateTime createdAt;

  IServCredentials({
    required this.username,
    required this.iservUrl,
    required this.credentialKey,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'iserv_url': iservUrl,
      'credential_key': credentialKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IServCredentials.fromMap(Map<String, dynamic> map) {
    return IServCredentials(
      username: map['username'] as String,
      iservUrl: map['iserv_url'] as String,
      credentialKey: map['credential_key'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class IServNotification {
  final String id;
  final String title;
  final String? message;
  final String? type;
  final bool read;
  final DateTime timestamp;
  final DateTime cachedAt;

  IServNotification({
    required this.id,
    required this.title,
    this.message,
    this.type,
    this.read = false,
    required this.timestamp,
    required this.cachedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'read': read ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory IServNotification.fromMap(Map<String, dynamic> map) {
    return IServNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String?,
      type: map['type'] as String?,
      read: (map['read'] as int?) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      cachedAt: DateTime.parse(map['cached_at'] as String),
    );
  }

  IServNotification copyWith({bool? read}) {
    return IServNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      read: read ?? this.read,
      timestamp: timestamp,
      cachedAt: cachedAt,
    );
  }
}

class IServExercise {
  final String id;
  final String title;
  final String? description;
  final String? course;
  final String? teacher;
  final DateTime? dueDate;
  final String status;
  final List<String>? attachments;
  final DateTime cachedAt;

  IServExercise({
    required this.id,
    required this.title,
    this.description,
    this.course,
    this.teacher,
    this.dueDate,
    this.status = 'open',
    this.attachments,
    required this.cachedAt,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status == 'open';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'course': course,
      'teacher': teacher,
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'attachments_json': attachments != null ? jsonEncode(attachments) : null,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory IServExercise.fromMap(Map<String, dynamic> map) {
    return IServExercise(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      course: map['course'] as String?,
      teacher: map['teacher'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      status: map['status'] as String? ?? 'open',
      attachments: map['attachments_json'] != null
          ? (jsonDecode(map['attachments_json'] as String) as List)
              .cast<String>()
          : null,
      cachedAt: DateTime.parse(map['cached_at'] as String),
    );
  }
}

class IServEvent {
  final String id;
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final String? description;
  final String? calendar;
  final bool allDay;
  final DateTime cachedAt;

  IServEvent({
    required this.id,
    required this.title,
    this.startTime,
    this.endTime,
    this.location,
    this.description,
    this.calendar,
    this.allDay = false,
    required this.cachedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'description': description,
      'calendar': calendar,
      'all_day': allDay ? 1 : 0,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory IServEvent.fromMap(Map<String, dynamic> map) {
    return IServEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      location: map['location'] as String?,
      description: map['description'] as String?,
      calendar: map['calendar'] as String?,
      allDay: (map['all_day'] as int?) == 1,
      cachedAt: DateTime.parse(map['cached_at'] as String),
    );
  }

  Event? toCalendarEvent() {
    if (startTime == null) return null;

    return Event(
      id: 'iserv_$id',
      title: title,
      description: description,
      location: location,
      startTime: startTime!,
      endTime: endTime ?? startTime!,
      allDay: allDay,
      category: 'school',
      createdAt: cachedAt,
      updatedAt: cachedAt,
    );
  }
}

class IServEmail {
  final String id;
  final String from;
  final String? fromName;
  final String to;
  final String subject;
  final String? preview;
  final String? body;
  final DateTime date;
  final bool read;
  final String folder;
  final DateTime cachedAt;

  IServEmail({
    required this.id,
    required this.from,
    this.fromName,
    required this.to,
    required this.subject,
    this.preview,
    this.body,
    required this.date,
    this.read = false,
    this.folder = 'INBOX',
    required this.cachedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_email': from,
      'from_name': fromName,
      'to_address': to,
      'subject': subject,
      'preview': preview,
      'body': body,
      'date': date.toIso8601String(),
      'is_read': read ? 1 : 0,
      'folder': folder,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory IServEmail.fromMap(Map<String, dynamic> map) {
    return IServEmail(
      id: map['id'] as String,
      from: map['from_email'] as String,
      fromName: map['from_name'] as String?,
      to: map['to_address'] as String? ?? '',
      subject: map['subject'] as String,
      preview: map['preview'] as String?,
      body: map['body'] as String?,
      date: DateTime.parse(map['date'] as String),
      read: (map['is_read'] as int?) == 1,
      folder: map['folder'] as String? ?? 'INBOX',
      cachedAt: DateTime.parse(map['cached_at'] as String),
    );
  }
}
