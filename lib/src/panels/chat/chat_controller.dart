import 'package:flutter/foundation.dart';

import '../../protocol/api_contract.dart';
import 'chat_models.dart';
import 'i_chat_provider.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required IChatProvider provider,
    required String contextId,
  })  : _provider = provider,
        _contextId = contextId;

  final IChatProvider _provider;
  final String _contextId;

  List<ChatThread> _threads = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<ChatThread> get threads => _threads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<ChatThread> get filteredThreads {
    if (_searchQuery.isEmpty) return _threads;
    final q = _searchQuery.toLowerCase();
    return _threads
        .where((t) =>
            t.threadId.toLowerCase().contains(q) ||
            t.title.toLowerCase().contains(q) ||
            t.status.toLowerCase().contains(q))
        .toList();
  }

  Future<void> loadThreads({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _threads = await _provider.listThreads(contextId: _contextId);
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'ChatController.loadThreads');
      _errorMessage = userFacingErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatThreadDetail> openThread({required String threadId}) async {
    final thread =
        await _provider.fetchThread(contextId: _contextId, threadId: threadId);
    final messages =
        await _provider.listMessages(contextId: _contextId, threadId: threadId);
    return ChatThreadDetail(thread: thread, messages: messages);
  }

  Future<List<ChatMessage>> loadMessages({required String threadId}) {
    return _provider.listMessages(contextId: _contextId, threadId: threadId);
  }

  Future<void> sendMessage({
    String? threadId,
    required String text,
    List<ChatAttachment>? attachments,
  }) async {
    await _provider.sendMessage(
      contextId: _contextId,
      threadId: threadId,
      text: text,
      attachments: attachments,
    );
    await loadThreads(forceRefresh: true);
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
