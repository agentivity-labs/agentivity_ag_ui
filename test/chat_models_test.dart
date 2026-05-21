import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessageRole.fromRaw', () {
    test('known roles', () {
      expect(ChatMessageRole.fromRaw('user'), ChatMessageRole.user);
      expect(ChatMessageRole.fromRaw('assistant'), ChatMessageRole.assistant);
      expect(ChatMessageRole.fromRaw('system'), ChatMessageRole.system);
      expect(ChatMessageRole.fromRaw('tool'), ChatMessageRole.tool);
    });

    test('case-insensitive', () {
      expect(ChatMessageRole.fromRaw('ASSISTANT'), ChatMessageRole.assistant);
      expect(ChatMessageRole.fromRaw('User'), ChatMessageRole.user);
    });

    test('unknown value returns unknown', () {
      expect(ChatMessageRole.fromRaw('robot'), ChatMessageRole.unknown);
      expect(ChatMessageRole.fromRaw(''), ChatMessageRole.unknown);
    });
  });

  group('ChatThread.fromJson', () {
    test('parses all fields', () {
      final thread = ChatThread.fromJson({
        'id': 'th1',
        'contextId': 'ctx1',
        'runId': 'run1',
        'title': 'My Thread',
        'isDefault': true,
        'status': 'active',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-02T00:00:00Z',
      });
      expect(thread.threadId, 'th1');
      expect(thread.contextId, 'ctx1');
      expect(thread.title, 'My Thread');
      expect(thread.isDefault, isTrue);
      expect(thread.status, 'active');
      expect(thread.createdAt, isNotNull);
    });

    test('case-insensitive key lookup', () {
      final thread = ChatThread.fromJson({
        'ID': 'th2',
        'ContextId': 'ctx2',
        'RunId': 'run2',
        'Title': 'Thread 2',
        'IsDefault': false,
        'Status': 'pending',
      });
      expect(thread.threadId, 'th2');
      expect(thread.isDefault, isFalse);
    });

    test('missing optional dates are null', () {
      final thread = ChatThread.fromJson({
        'id': 'th3',
        'contextId': 'c',
        'runId': 'r',
        'title': 't',
        'isDefault': false,
        'status': 'active',
      });
      expect(thread.createdAt, isNull);
      expect(thread.updatedAt, isNull);
    });
  });

  group('ChatMessage.fromJson', () {
    test('parses all fields', () {
      final msg = ChatMessage.fromJson({
        'id': 'msg1',
        'authorType': 'assistant',
        'contextId': 'ctx1',
        'threadId': 'th1',
        'runId': 'r1',
        'text': 'Hello there',
        'authorId': 'bot-1',
        'authorName': 'Bot',
        'createdAt': '2024-06-01T12:00:00Z',
      });
      expect(msg.id, 'msg1');
      expect(msg.role, ChatMessageRole.assistant);
      expect(msg.text, 'Hello there');
      expect(msg.authorName, 'Bot');
    });

    test('optional fields are null when absent', () {
      final msg = ChatMessage.fromJson({
        'id': 'msg2',
        'authorType': 'user',
        'contextId': 'c',
        'threadId': 't',
        'runId': 'r',
        'text': 'hi',
      });
      expect(msg.authorId, isNull);
      expect(msg.metadata, isNull);
      expect(msg.deletedAt, isNull);
    });
  });
}
