enum AssistantRole { user, assistant, system }

extension AssistantRoleExt on AssistantRole {
  String get apiValue {
    switch (this) {
      case AssistantRole.user:
        return 'user';
      case AssistantRole.assistant:
        return 'assistant';
      case AssistantRole.system:
        return 'system';
    }
  }

  static AssistantRole fromApi(String value) {
    switch (value.trim().toLowerCase()) {
      case 'assistant':
        return AssistantRole.assistant;
      case 'system':
        return AssistantRole.system;
      default:
        return AssistantRole.user;
    }
  }
}

const Object _tokensSentinel = Object();

/// A single message in an assistant conversation (UI-facing model).
class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.tokensUsed,
  });

  final AssistantRole role;
  final String content;
  final DateTime timestamp;
  final int? tokensUsed;

  Map<String, String> toHistoryEntry() => {'role': role.apiValue, 'content': content};

  AssistantMessage copyWith({
    AssistantRole? role,
    String? content,
    DateTime? timestamp,
    Object? tokensUsed = _tokensSentinel,
  }) {
    return AssistantMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      tokensUsed: tokensUsed == _tokensSentinel ? this.tokensUsed : tokensUsed as int?,
    );
  }
}

/// Result from a non-streaming assistant call.
class AssistantResult {
  const AssistantResult({required this.message, this.tokensUsed});

  final String message;
  final int? tokensUsed;
}

/// Server health/status from the assistant backend.
class AssistantHealth {
  const AssistantHealth({
    required this.isHealthy,
    required this.statusLabel,
    required this.service,
    required this.version,
  });

  final bool isHealthy;
  final String statusLabel;
  final String service;
  final String version;
}

/// A single chunk emitted by a streaming assistant response.
class AssistantChunk {
  const AssistantChunk({
    this.content,
    this.tokensUsed,
    this.error,
    this.isDone = false,
  });

  final String? content;
  final int? tokensUsed;
  final String? error;
  final bool isDone;

  bool get hasError => error != null && error!.isNotEmpty;

  static AssistantChunk done({int? tokensUsed}) =>
      AssistantChunk(isDone: true, tokensUsed: tokensUsed);
  static AssistantChunk errorChunk(String message) =>
      AssistantChunk(error: message, isDone: true);

  factory AssistantChunk.fromJson(Map<String, dynamic> json) {
    final content = _readFirst(json, ['content', 'Content', 'data', 'Data']);
    final error = _readFirst(json, ['error', 'Error']);
    final done = _readFirst(json, ['done', 'Done', 'isDone', 'IsDone']);
    final tokens = _readFirst(json, ['tokensUsed', 'TokensUsed', 'tokens']);
    return AssistantChunk(
      content: _str(content, keepWhitespace: true),
      tokensUsed: _int(tokens),
      error: _str(error),
      isDone: _asBool(done),
    );
  }
}

// ── JSON helpers (assistant-specific: multi-key lookup on dynamic values) ─────

dynamic _readFirst(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k)) return json[k];
  }
  return null;
}

String? _str(dynamic v, {bool keepWhitespace = false}) {
  if (v == null) return null;
  final s = v.toString();
  final result = keepWhitespace ? s : s.trim();
  return result.isEmpty ? null : result;
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

bool _asBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final n = v.trim().toLowerCase();
    return n == 'true' || n == '1';
  }
  return false;
}
