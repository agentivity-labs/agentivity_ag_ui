import 'chat_models.dart';

/// Generic chat provider — implement this against any backend.
abstract interface class IChatProvider {
  Future<List<ChatThread>> listThreads({required String contextId});
  Future<ChatThread> fetchThread({required String contextId, required String threadId});
  Future<List<ChatMessage>> listMessages({required String contextId, required String threadId});

  /// Send a message, optionally with [attachments].
  ///
  /// Implementations should convert [ChatAttachment] subtypes to whatever
  /// format the backend expects (e.g. [ImageUrlAttachment] → `image_url` content
  /// part, [ImageBytesAttachment] → base64 data URI, [FileAttachment] → file ID).
  Future<void> sendMessage({
    required String contextId,
    String? threadId,
    required String text,
    List<ChatAttachment>? attachments,
  });
}
