import 'assistant_models.dart';

/// Generic assistant provider — implement this against any backend.
abstract interface class IAssistantProvider {
  /// Send a message and get a complete response.
  Future<AssistantResult> send({
    required String message,
    List<Map<String, String>> history,
    Map<String, dynamic>? context,
  });

  /// Send a message and stream the response chunk by chunk.
  Stream<AssistantChunk> stream({
    required String message,
    List<Map<String, String>> history,
    Map<String, dynamic>? context,
  });

  Future<AssistantHealth> checkHealth();
}
