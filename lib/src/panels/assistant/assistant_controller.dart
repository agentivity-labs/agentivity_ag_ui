import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../protocol/api_contract.dart';
import 'assistant_models.dart';
import 'i_assistant_provider.dart';

class AssistantController extends ChangeNotifier {
  AssistantController({required IAssistantProvider provider})
      : _provider = provider;

  final IAssistantProvider _provider;

  List<AssistantMessage> _messages = const [];
  bool _isSending = false;
  bool _isOnline = false;
  bool _isCheckingHealth = false;
  bool _hasCheckedHealth = false;
  String? _errorMessage;
  String _statusLabel = 'unknown';
  int? _lastResponseTokens;

  List<AssistantMessage> get messages => _messages;
  bool get isSending => _isSending;
  bool get isOnline => _isOnline;
  bool get isCheckingHealth => _isCheckingHealth;
  bool get hasCheckedHealth => _hasCheckedHealth;
  String? get errorMessage => _errorMessage;
  String get statusLabel => _statusLabel;
  int? get lastResponseTokens => _lastResponseTokens;

  Future<void> checkHealth() async {
    if (_isCheckingHealth) return;
    _isCheckingHealth = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final health = await _provider.checkHealth();
      _isOnline = health.isHealthy;
      _statusLabel = health.statusLabel;
      _hasCheckedHealth = true;
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'AssistantController.checkHealth');
      _isOnline = false;
      _hasCheckedHealth = true;
      _errorMessage = userFacingErrorMessage(e);
      _appendSystem('Assistant unreachable. Try again shortly.');
    } finally {
      _isCheckingHealth = false;
      notifyListeners();
    }
  }

  /// Send [content] to the assistant.
  ///
  /// [context] is optional caller-provided data forwarded verbatim to the
  /// backend (e.g. a serialized workflow). The package does not inspect it.
  Future<void> sendMessage({
    required String content,
    Map<String, dynamic>? context,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _isSending) return;

    final previous = List<AssistantMessage>.from(_messages);
    final history = previous.map((m) => m.toHistoryEntry()).toList();

    _messages = [
      ...previous,
      AssistantMessage(
          role: AssistantRole.user,
          content: trimmed,
          timestamp: DateTime.now()),
    ];
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final baseMessages = List<AssistantMessage>.from(_messages);

    try {
      final tokensUsed = await _streamResponse(
          message: trimmed,
          history: history,
          context: context,
          baseMessages: baseMessages);
      _isOnline = true;
      _lastResponseTokens = tokensUsed;
    } on Object catch (e) {
      if (_shouldFallback(e)) {
        _messages = List<AssistantMessage>.from(baseMessages);
        notifyListeners();
        await _sendLegacy(
            message: trimmed,
            history: history,
            context: context,
            baseMessages: baseMessages);
        return;
      }
      _handleError(e, baseMessages);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<int?> _streamResponse({
    required String message,
    required List<Map<String, String>> history,
    Map<String, dynamic>? context,
    required List<AssistantMessage> baseMessages,
  }) async {
    final stream =
        _provider.stream(message: message, history: history, context: context);

    AssistantMessage? draft;
    var working = List<AssistantMessage>.from(baseMessages);
    int? tokensUsed;

    await for (final chunk in stream) {
      if (chunk.hasError) throw StateError(chunk.error!);

      if (chunk.content != null && chunk.content!.isNotEmpty) {
        final updated = AssistantMessage(
          role: AssistantRole.assistant,
          content: (draft?.content ?? '') + chunk.content!,
          timestamp: draft?.timestamp ?? DateTime.now(),
          tokensUsed: draft?.tokensUsed,
        );
        draft = updated;
        working = working.length > baseMessages.length
            ? ([...working]..[working.length - 1] = updated)
            : [...working, updated];
        _messages = working;
        notifyListeners();
      }

      if (chunk.tokensUsed != null) tokensUsed = chunk.tokensUsed;

      if (chunk.isDone) {
        if (draft != null && tokensUsed != null) {
          final finalDraft = draft.copyWith(tokensUsed: tokensUsed);
          _messages = [...working]..[working.length - 1] = finalDraft;
          notifyListeners();
        }
        return tokensUsed;
      }
    }

    if (draft == null) throw StateError('Stream ended without content.');
    return tokensUsed;
  }

  Future<void> _sendLegacy({
    required String message,
    required List<Map<String, String>> history,
    Map<String, dynamic>? context,
    required List<AssistantMessage> baseMessages,
  }) async {
    try {
      final result = await _provider.send(
          message: message, history: history, context: context);
      _messages = [
        ...baseMessages,
        AssistantMessage(
          role: AssistantRole.assistant,
          content: result.message,
          timestamp: DateTime.now(),
          tokensUsed: result.tokensUsed,
        ),
      ];
      _isOnline = true;
      _lastResponseTokens = result.tokensUsed;
    } on Object catch (e) {
      _handleError(e, baseMessages);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  bool _shouldFallback(Object e) {
    final code = apiHttpStatus(e);
    return code == 404 || code == 405 || code == 501;
  }

  void _handleError(Object e, List<AssistantMessage> baseMessages) {
    debugLogApiIssue(e, operation: 'AssistantController.sendMessage');
    final msg = userFacingErrorMessage(e);
    _messages = [
      ...baseMessages,
      AssistantMessage(
          role: AssistantRole.system,
          content: msg,
          timestamp: DateTime.now()),
    ];
    _errorMessage = msg;
    _isOnline = false;
  }

  void _appendSystem(String text) {
    _messages = [
      ..._messages,
      AssistantMessage(
          role: AssistantRole.system,
          content: text,
          timestamp: DateTime.now()),
    ];
    notifyListeners();
  }

  void clearMessages() {
    _messages = const [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
