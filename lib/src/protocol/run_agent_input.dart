// ── Message content parts ─────────────────────────────────────────────────────

/// A single part of a mixed-content message (text, image, or file).
///
/// Use [buildAgUiMessage] to compose a message entry for
/// [RunAgentInput.messages]:
///
/// ```dart
/// buildAgUiMessage('user',
///   text: 'Look at this image',
///   parts: [ImageUrlContentPart(url: 'https://...')],
/// )
/// ```
sealed class MessageContentPart {
  const MessageContentPart();
  Map<String, dynamic> toJson();
}

/// Plain text content part.
final class TextContentPart extends MessageContentPart {
  const TextContentPart(this.text);
  final String text;
  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

/// Image referenced by URL or data URI (`data:image/jpeg;base64,...`).
final class ImageUrlContentPart extends MessageContentPart {
  const ImageUrlContentPart({required this.url, this.detail});
  final String url;

  /// Resolution hint: `'low'`, `'high'`, or `'auto'` (model-dependent).
  final String? detail;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image_url',
        'image_url': {
          'url': url,
          if (detail != null) 'detail': detail,
        },
      };
}

/// File referenced by a backend-assigned file ID.
final class FileContentPart extends MessageContentPart {
  const FileContentPart({required this.fileId, this.mimeType, this.name});
  final String fileId;
  final String? mimeType;
  final String? name;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'file',
        'file': {
          'file_id': fileId,
          if (mimeType != null) 'mime_type': mimeType,
          if (name != null) 'name': name,
        },
      };
}

/// Builds a message entry for [RunAgentInput.messages] supporting mixed content.
///
/// If [parts] are provided, the message `content` field becomes an array;
/// otherwise it is a plain string.
Map<String, dynamic> buildAgUiMessage(
  String role, {
  String? text,
  List<MessageContentPart>? parts,
}) {
  if (parts != null && parts.isNotEmpty) {
    final allParts = [
      if (text != null && text.isNotEmpty) TextContentPart(text),
      ...parts,
    ];
    return {
      'role': role,
      'content': allParts.map((p) => p.toJson()).toList(),
    };
  }
  return {'role': role, 'content': text ?? ''};
}

// ── RunAgentInput ─────────────────────────────────────────────────────────────

/// The payload sent to the backend to start or resume an agent run.
///
/// ```dart
/// final input = RunAgentInput(
///   threadId: 'thread-1',
///   runId: 'run-42',
///   messages: history.map((m) => m.toHistoryEntry()).toList(),
/// );
/// await dio.post('/agent/run', data: input.toJson());
/// ```
///
/// To resume after an [AgUiInterruptOutcome], populate [resume] with one
/// [ResumePayload] per interrupt:
///
/// ```dart
/// final input = RunAgentInput(
///   threadId: 'thread-1',
///   runId: 'run-43',
///   messages: history,
///   resume: [
///     ResumePayload(
///       interruptId: interrupt.id,
///       status: ResumeStatus.resolved,
///       response: {'approved': true},
///     ),
///   ],
/// );
/// ```
class RunAgentInput {
  const RunAgentInput({
    required this.threadId,
    required this.runId,
    this.messages = const [],
    this.tools = const [],
    this.context = const [],
    this.state,
    this.forwardedProps,
    this.resume = const [],
  });

  final String threadId;
  final String runId;

  /// Full conversation history — each entry is a `{role, content}` map.
  final List<Map<String, dynamic>> messages;

  /// Tool definitions available to the agent for this run.
  final List<Map<String, dynamic>> tools;

  /// Arbitrary context entries passed through to the agent.
  final List<dynamic> context;

  /// Agent state carried over from a previous run (e.g. from STATE_SNAPSHOT).
  final dynamic state;

  /// Custom props forwarded verbatim to the backend.
  final Map<String, dynamic>? forwardedProps;

  /// Resume payloads for each open interrupt from the previous run.
  final List<ResumePayload> resume;

  Map<String, dynamic> toJson() => {
        'threadId': threadId,
        'runId': runId,
        'messages': messages,
        if (tools.isNotEmpty) 'tools': tools,
        if (context.isNotEmpty) 'context': context,
        if (state != null) 'state': state,
        if (forwardedProps != null) 'forwardedProps': forwardedProps,
        if (resume.isNotEmpty) 'resume': resume.map((r) => r.toJson()).toList(),
      };
}

/// One resolved or cancelled response to a single [AgUiInterrupt].
class ResumePayload {
  const ResumePayload({
    required this.interruptId,
    required this.status,
    this.response,
  });

  /// The [AgUiInterrupt.id] this payload addresses.
  final String interruptId;
  final ResumeStatus status;

  /// Required when [status] is [ResumeStatus.resolved]; must satisfy the
  /// interrupt's `responseSchema` if one was provided.
  final dynamic response;

  Map<String, dynamic> toJson() => {
        'interruptId': interruptId,
        'status': status.apiValue,
        if (response != null) 'response': response,
      };
}

enum ResumeStatus {
  resolved,
  cancelled;

  String get apiValue => switch (this) {
        ResumeStatus.resolved => 'resolved',
        ResumeStatus.cancelled => 'cancelled',
      };
}
