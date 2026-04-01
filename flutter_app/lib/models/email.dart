import 'dart:convert';

enum EmailAccountType { imap, gmail }

class EmailAccount {
  final String id;
  final String email;
  final String? displayName;
  final EmailAccountType type;
  final String? imapHost;
  final int? imapPort;
  final String? smtpHost;
  final int? smtpPort;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastSyncAt;

  EmailAccount({
    required this.id,
    required this.email,
    this.displayName,
    required this.type,
    this.imapHost,
    this.imapPort,
    this.smtpHost,
    this.smtpPort,
    this.isDefault = false,
    required this.createdAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'type': type.name,
      'imap_host': imapHost,
      'imap_port': imapPort,
      'smtp_host': smtpHost,
      'smtp_port': smtpPort,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory EmailAccount.fromMap(Map<String, dynamic> map) {
    return EmailAccount(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      type: EmailAccountType.values.byName(map['type'] as String),
      imapHost: map['imap_host'] as String?,
      imapPort: map['imap_port'] as int?,
      smtpHost: map['smtp_host'] as String?,
      smtpPort: map['smtp_port'] as int?,
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastSyncAt: map['last_sync_at'] != null
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
    );
  }

  EmailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    EmailAccountType? type,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastSyncAt,
  }) {
    return EmailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

class EmailFolder {
  final String id;
  final String accountId;
  final String name;
  final String path;
  final int unreadCount;
  final int totalCount;
  final bool isSystem;

  EmailFolder({
    required this.id,
    required this.accountId,
    required this.name,
    required this.path,
    this.unreadCount = 0,
    this.totalCount = 0,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'path': path,
      'unread_count': unreadCount,
      'total_count': totalCount,
      'is_system': isSystem ? 1 : 0,
    };
  }

  factory EmailFolder.fromMap(Map<String, dynamic> map) {
    return EmailFolder(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      unreadCount: map['unread_count'] as int? ?? 0,
      totalCount: map['total_count'] as int? ?? 0,
      isSystem: (map['is_system'] as int?) == 1,
    );
  }

  EmailFolder copyWith({
    String? id,
    String? accountId,
    String? name,
    String? path,
    int? unreadCount,
    int? totalCount,
    bool? isSystem,
  }) {
    return EmailFolder(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      path: path ?? this.path,
      unreadCount: unreadCount ?? this.unreadCount,
      totalCount: totalCount ?? this.totalCount,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}

class Email {
  final String id;
  final String accountId;
  final String folderId;
  final String? messageId;
  final String subject;
  final String from;
  final String? fromName;
  final List<String> to;
  final List<String>? cc;
  final List<String>? bcc;
  final String? bodyPlain;
  final String? bodyHtml;
  final DateTime date;
  final bool isRead;
  final bool isStarred;
  final bool hasAttachments;
  final List<EmailAttachment>? attachments;

  Email({
    required this.id,
    required this.accountId,
    required this.folderId,
    this.messageId,
    required this.subject,
    required this.from,
    this.fromName,
    required this.to,
    this.cc,
    this.bcc,
    this.bodyPlain,
    this.bodyHtml,
    required this.date,
    this.isRead = false,
    this.isStarred = false,
    this.hasAttachments = false,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'folder_id': folderId,
      'message_id': messageId,
      'subject': subject,
      'from_address': from,
      'from_name': fromName,
      'to_addresses': jsonEncode(to),
      'cc_addresses': cc != null ? jsonEncode(cc) : null,
      'bcc_addresses': bcc != null ? jsonEncode(bcc) : null,
      'body_plain': bodyPlain,
      'body_html': bodyHtml,
      'date': date.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'is_starred': isStarred ? 1 : 0,
      'has_attachments': hasAttachments ? 1 : 0,
      'attachments': attachments != null
          ? jsonEncode(attachments!.map((a) => a.toMap()).toList())
          : null,
    };
  }

  factory Email.fromMap(Map<String, dynamic> map) {
    return Email(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      folderId: map['folder_id'] as String,
      messageId: map['message_id'] as String?,
      subject: map['subject'] as String,
      from: map['from_address'] as String,
      fromName: map['from_name'] as String?,
      to: (jsonDecode(map['to_addresses'] as String) as List).cast<String>(),
      cc: map['cc_addresses'] != null
          ? (jsonDecode(map['cc_addresses'] as String) as List).cast<String>()
          : null,
      bcc: map['bcc_addresses'] != null
          ? (jsonDecode(map['bcc_addresses'] as String) as List).cast<String>()
          : null,
      bodyPlain: map['body_plain'] as String?,
      bodyHtml: map['body_html'] as String?,
      date: DateTime.parse(map['date'] as String),
      isRead: (map['is_read'] as int?) == 1,
      isStarred: (map['is_starred'] as int?) == 1,
      hasAttachments: (map['has_attachments'] as int?) == 1,
      attachments: map['attachments'] != null
          ? (jsonDecode(map['attachments'] as String) as List)
              .map((a) => EmailAttachment.fromMap(a as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Email copyWith({
    String? id,
    String? accountId,
    String? folderId,
    String? messageId,
    String? subject,
    String? from,
    String? fromName,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? bodyPlain,
    String? bodyHtml,
    DateTime? date,
    bool? isRead,
    bool? isStarred,
    bool? hasAttachments,
    List<EmailAttachment>? attachments,
  }) {
    return Email(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      folderId: folderId ?? this.folderId,
      messageId: messageId ?? this.messageId,
      subject: subject ?? this.subject,
      from: from ?? this.from,
      fromName: fromName ?? this.fromName,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      bodyPlain: bodyPlain ?? this.bodyPlain,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachments: attachments ?? this.attachments,
    );
  }

  String get displayFrom => fromName ?? from;

  String get preview {
    final text = bodyPlain ?? '';
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }
}

class EmailAttachment {
  final String id;
  final String filename;
  final String mimeType;
  final int size;
  final String? localPath;

  EmailAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.localPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'mime_type': mimeType,
      'size': size,
      'local_path': localPath,
    };
  }

  factory EmailAttachment.fromMap(Map<String, dynamic> map) {
    return EmailAttachment(
      id: map['id'] as String,
      filename: map['filename'] as String,
      mimeType: map['mime_type'] as String,
      size: map['size'] as int,
      localPath: map['local_path'] as String?,
    );
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class EmailDraft {
  final String? id;
  final String accountId;
  final String? inReplyTo;
  final String subject;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String body;
  final bool isHtml;
  final List<String> attachmentPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailDraft({
    this.id,
    required this.accountId,
    this.inReplyTo,
    required this.subject,
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    required this.body,
    this.isHtml = false,
    this.attachmentPaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'in_reply_to': inReplyTo,
      'subject': subject,
      'to_addresses': jsonEncode(to),
      'cc_addresses': jsonEncode(cc),
      'bcc_addresses': jsonEncode(bcc),
      'body': body,
      'is_html': isHtml ? 1 : 0,
      'attachment_paths': jsonEncode(attachmentPaths),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EmailDraft.fromMap(Map<String, dynamic> map) {
    return EmailDraft(
      id: map['id'] as String?,
      accountId: map['account_id'] as String,
      inReplyTo: map['in_reply_to'] as String?,
      subject: map['subject'] as String,
      to: (jsonDecode(map['to_addresses'] as String) as List).cast<String>(),
      cc: (jsonDecode(map['cc_addresses'] as String) as List).cast<String>(),
      bcc: (jsonDecode(map['bcc_addresses'] as String) as List).cast<String>(),
      body: map['body'] as String,
      isHtml: (map['is_html'] as int?) == 1,
      attachmentPaths: (jsonDecode(map['attachment_paths'] as String) as List).cast<String>(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  EmailDraft copyWith({
    String? id,
    String? accountId,
    String? inReplyTo,
    String? subject,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? body,
    bool? isHtml,
    List<String>? attachmentPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailDraft(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      subject: subject ?? this.subject,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      body: body ?? this.body,
      isHtml: isHtml ?? this.isHtml,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}