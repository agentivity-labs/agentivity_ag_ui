import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake provider ─────────────────────────────────────────────────────────────

class FakeChatProvider implements IChatProvider {
  final List<ChatThread> threads;
  final List<ChatMessage> messages;
  int sendCallCount = 0;

  FakeChatProvider({this.threads = const [], this.messages = const []});

  @override
  Future<List<ChatThread>> listThreads({required String contextId}) async => threads;

  @override
  Future<ChatThread> fetchThread({required String contextId, required String threadId}) async {
    return threads.firstWhere((t) => t.threadId == threadId);
  }

  @override
  Future<List<ChatMessage>> listMessages({required String contextId, required String threadId}) async {
    return messages;
  }

  @override
  Future<void> sendMessage({
    required String contextId,
    String? threadId,
    required String text,
    List<ChatAttachment>? attachments,
  }) async {
    sendCallCount++;
  }
}

ChatThread _makeThread(String id, String title) => ChatThread.fromJson({
      'id': id,
      'contextId': 'ctx1',
      'runId': 'r1',
      'title': title,
      'isDefault': false,
      'status': 'active',
    });

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ChatController', () {
    late FakeChatProvider provider;
    late ChatController ctrl;

    setUp(() {
      provider = FakeChatProvider(
        threads: [
          _makeThread('t1', 'Support Chat'),
          _makeThread('t2', 'Sales Inquiry'),
        ],
      );
      ctrl = ChatController(provider: provider, contextId: 'ctx1');
    });

    tearDown(() => ctrl.dispose());

    test('initial state is empty', () {
      expect(ctrl.threads, isEmpty);
      expect(ctrl.isLoading, isFalse);
      expect(ctrl.errorMessage, isNull);
    });

    test('loadThreads populates threads', () async {
      await ctrl.loadThreads();
      expect(ctrl.threads, hasLength(2));
      expect(ctrl.isLoading, isFalse);
    });

    test('loadThreads notifies listeners', () async {
      var notified = 0;
      ctrl.addListener(() => notified++);
      await ctrl.loadThreads();
      expect(notified, greaterThan(0));
    });

    test('setSearchQuery filters threads', () async {
      await ctrl.loadThreads();
      ctrl.setSearchQuery('support');
      expect(ctrl.filteredThreads, hasLength(1));
      expect(ctrl.filteredThreads.first.title, 'Support Chat');
    });

    test('setSearchQuery is case-insensitive', () async {
      await ctrl.loadThreads();
      ctrl.setSearchQuery('SALES');
      expect(ctrl.filteredThreads, hasLength(1));
    });

    test('empty search query returns all threads', () async {
      await ctrl.loadThreads();
      ctrl.setSearchQuery('support');
      ctrl.setSearchQuery('');
      expect(ctrl.filteredThreads, hasLength(2));
    });

    test('sendMessage delegates to provider', () async {
      await ctrl.sendMessage(threadId: 't1', text: 'Hello');
      expect(provider.sendCallCount, 1);
    });

    test('openThread composes thread and messages', () async {
      await ctrl.loadThreads();
      final detail = await ctrl.openThread(threadId: 't1');
      expect(detail.thread.threadId, 't1');
      expect(detail.messages, isEmpty);
    });

    test('clearError resets error', () {
      ctrl.clearError();
      expect(ctrl.errorMessage, isNull);
    });
  });
}
