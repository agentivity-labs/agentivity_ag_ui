import 'dart:typed_data';

import '../../shared/json_helpers.dart';

// ── Attachments ───────────────────────────────────────────────────────────────

/// An attachment that can be sent with a chat message.
///
/// The provider implementation decides how to serialize attachments for the
/// backend. Three concrete subtypes are available:
/// - [ImageUrlAttachment] — image referenced by URL or data URI
/// - [ImageBytesAttachment] — raw image bytes (e.g. from the camera)
/// - [FileAttachment] — file referenced by a backend file ID
sealed class ChatAttachment {
  const ChatAttachment({this.name, this.mimeType});
  final String? name;
  final String? mimeType;
}

/// Image referenced by a URL (`https://`) or data URI (`data:image/jpeg;base64,...`).
final class ImageUrlAttachment extends ChatAttachment {
  const ImageUrlAttachment({required this.url, super.name});
  final String url;
}

/// Raw image bytes — encode as needed in the provider (e.g. to base64 data URI).
final class ImageBytesAttachment extends ChatAttachment {
  ImageBytesAttachment({required this.bytes, super.name, super.mimeType});
  final Uint8List bytes;
}

/// File referenced by a backend-assigned file ID.
final class FileAttachment extends ChatAttachment {
  const FileAttachment({required this.fileId, super.name, super.mimeType});
  final String fileId;
}

// ── Message role ──────────────────────────────────────────────────────────────

enum ChatMessageRole {
  user,
  assistant,
  system,
  tool,
  unknown;

  factory ChatMessageRole.fromRaw(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'user':
        return ChatMessageRole.user;
      case 'assistant':
        return ChatMessageRole.assistant;
      case 'system':
        return ChatMessageRole.system;
      case 'tool':
        return ChatMessageRole.tool;
      default:
        return ChatMessageRole.unknown;
    }
  }
}

class ChatThread {
  const ChatThread({
    required this.threadId,
    required this.contextId,
    required this.runId,
    required this.title,
    required this.isDefault,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String threadId;
  final String contextId;
  final String runId;
  final String title;
  final bool isDefault;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      threadId: jsonStr(json, 'id'),
      contextId: jsonStr(json, 'contextId'),
      runId: jsonStr(json, 'runId'),
      title: jsonStr(json, 'title'),
      isDefault: jsonBool(json, 'isDefault'),
      status: jsonStr(json, 'status'),
      createdAt: jsonDateTime(json, 'createdAt'),
      updatedAt: jsonDateTime(json, 'updatedAt'),
    );
  }
}

class ChatThreadDetail {
  const ChatThreadDetail({required this.thread, required this.messages});

  final ChatThread thread;
  final List<ChatMessage> messages;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.contextId,
    required this.threadId,
    required this.runId,
    required this.text,
    this.authorId,
    this.authorName,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final ChatMessageRole role;
  final String contextId;
  final String threadId;
  final String runId;
  final String text;
  final String? authorId;
  final String? authorName;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: jsonStr(json, 'id'),
      role: ChatMessageRole.fromRaw(jsonStr(json, 'authorType')),
      contextId: jsonStr(json, 'contextId'),
      threadId: jsonStr(json, 'threadId'),
      runId: jsonStr(json, 'runId'),
      text: jsonStr(json, 'text'),
      authorId: jsonOpt(json, 'authorId'),
      authorName: jsonOpt(json, 'authorName'),
      metadata: jsonMap(json, 'metadata'),
      createdAt: jsonDateTime(json, 'createdAt'),
      updatedAt: jsonDateTime(json, 'updatedAt'),
      deletedAt: jsonDateTime(json, 'deletedAt'),
    );
  }
}
