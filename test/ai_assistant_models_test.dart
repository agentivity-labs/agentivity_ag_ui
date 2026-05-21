import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssistantRoleExt', () {
    test('apiValue', () {
      expect(AssistantRole.user.apiValue, 'user');
      expect(AssistantRole.assistant.apiValue, 'assistant');
      expect(AssistantRole.system.apiValue, 'system');
    });

    test('fromApi known values', () {
      expect(AssistantRoleExt.fromApi('assistant'), AssistantRole.assistant);
      expect(AssistantRoleExt.fromApi('system'), AssistantRole.system);
      expect(AssistantRoleExt.fromApi('user'), AssistantRole.user);
    });

    test('fromApi unknown defaults to user', () {
      expect(AssistantRoleExt.fromApi('robot'), AssistantRole.user);
    });

    test('fromApi case-insensitive', () {
      expect(AssistantRoleExt.fromApi('ASSISTANT'), AssistantRole.assistant);
    });
  });

  group('AssistantChunk.fromJson', () {
    test('content chunk', () {
      final c = AssistantChunk.fromJson({'content': 'Hello'});
      expect(c.content, 'Hello');
      expect(c.isDone, isFalse);
      expect(c.hasError, isFalse);
    });

    test('done chunk', () {
      final c = AssistantChunk.fromJson({'done': true, 'tokensUsed': 42});
      expect(c.isDone, isTrue);
      expect(c.tokensUsed, 42);
    });

    test('error chunk', () {
      final c = AssistantChunk.fromJson({'error': 'Failed', 'done': true});
      expect(c.hasError, isTrue);
      expect(c.error, 'Failed');
    });

    test('accepts alternate key names', () {
      final c = AssistantChunk.fromJson({'Content': 'World', 'TokensUsed': 10});
      expect(c.content, 'World');
      expect(c.tokensUsed, 10);
    });

    test('empty string content is treated as null', () {
      final c = AssistantChunk.fromJson({'content': ''});
      expect(c.content, isNull);
    });
  });

  group('AssistantChunk factories', () {
    test('done()', () {
      final c = AssistantChunk.done(tokensUsed: 99);
      expect(c.isDone, isTrue);
      expect(c.tokensUsed, 99);
      expect(c.hasError, isFalse);
    });

    test('errorChunk()', () {
      final c = AssistantChunk.errorChunk('something bad');
      expect(c.isDone, isTrue);
      expect(c.hasError, isTrue);
      expect(c.error, 'something bad');
    });
  });

  group('AssistantMessage.copyWith', () {
    final base = AssistantMessage(
      role: AssistantRole.assistant,
      content: 'Hello',
      timestamp: DateTime(2024),
      tokensUsed: 10,
    );

    test('copies with new content', () {
      final updated = base.copyWith(content: 'World');
      expect(updated.content, 'World');
      expect(updated.role, base.role);
      expect(updated.tokensUsed, base.tokensUsed);
    });

    test('can explicitly clear tokensUsed', () {
      final updated = base.copyWith(tokensUsed: null);
      expect(updated.tokensUsed, isNull);
    });

    test('preserves tokensUsed when not specified', () {
      final updated = base.copyWith(content: 'X');
      expect(updated.tokensUsed, 10);
    });

    test('toHistoryEntry', () {
      final entry = base.toHistoryEntry();
      expect(entry['role'], 'assistant');
      expect(entry['content'], 'Hello');
    });
  });
}
