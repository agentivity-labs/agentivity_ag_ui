import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentRunState.fromApi', () {
    test('known values', () {
      expect(AgentRunState.fromApi('completed'), AgentRunState.completed);
      expect(AgentRunState.fromApi('failed'), AgentRunState.failed);
      expect(AgentRunState.fromApi('cancelled'), AgentRunState.cancelled);
      expect(AgentRunState.fromApi('running'), AgentRunState.running);
    });

    test('case-insensitive', () {
      expect(AgentRunState.fromApi('COMPLETED'), AgentRunState.completed);
      expect(AgentRunState.fromApi('Failed'), AgentRunState.failed);
    });

    test('unknown defaults to running', () {
      expect(AgentRunState.fromApi('unknown'), AgentRunState.running);
      expect(AgentRunState.fromApi(''), AgentRunState.running);
    });
  });

  group('AgentRunState.isTerminal', () {
    test('terminal states', () {
      expect(AgentRunState.completed.isTerminal, isTrue);
      expect(AgentRunState.failed.isTerminal, isTrue);
      expect(AgentRunState.cancelled.isTerminal, isTrue);
    });

    test('running is not terminal', () {
      expect(AgentRunState.running.isTerminal, isFalse);
    });
  });

  group('AgentRunStreamEvent', () {
    test('fromJson parses all fields', () {
      final e = AgentRunStreamEvent.fromJson({
        'eventId': 'e1',
        'runId': 'r1',
        'kind': 'lifecycle',
        'eventName': 'run_completed',
        'occurredAt': '2024-01-01T00:00:00Z',
        'payload': {'result': 'ok'},
      });
      expect(e.eventId, 'e1');
      expect(e.runId, 'r1');
      expect(e.eventName, 'run_completed');
      expect(e.payload, {'result': 'ok'});
    });

    test('fromJson handles missing fields gracefully', () {
      final e = AgentRunStreamEvent.fromJson({});
      expect(e.eventId, '');
      expect(e.eventName, '');
      expect(e.payload, isEmpty);
    });

    test('fromJson handles non-map payload', () {
      final e = AgentRunStreamEvent.fromJson({'payload': 'raw string'});
      expect(e.payload, isEmpty);
    });

    test('isTerminal for terminal event names', () {
      for (final name in ['run_completed', 'run_failed', 'run_cancelled']) {
        final e = AgentRunStreamEvent.fromJson({'eventName': name});
        expect(e.isTerminal, isTrue, reason: '$name should be terminal');
      }
    });

    test('isTerminal false for non-terminal events', () {
      final e = AgentRunStreamEvent.fromJson({'eventName': 'step_started'});
      expect(e.isTerminal, isFalse);
    });
  });

  group('AgentRunStatus.fromJson', () {
    test('parses completed run', () {
      final s = AgentRunStatus.fromJson({
        'runId': 'r1',
        'agentId': 'a1',
        'state': 'completed',
        'content': 'Done successfully',
      });
      expect(s.state, AgentRunState.completed);
      expect(s.content, 'Done successfully');
      expect(s.error, isNull);
    });

    test('parses failed run', () {
      final s = AgentRunStatus.fromJson({
        'runId': 'r2',
        'agentId': 'a1',
        'state': 'failed',
        'error': 'Timeout',
      });
      expect(s.state, AgentRunState.failed);
      expect(s.error, 'Timeout');
    });
  });

  group('AgentEntity.fromJson', () {
    test('parses entity with ports', () {
      final entity = AgentEntity.fromJson({
        'id': 'agent-1',
        'displayName': 'My Agent',
        'kind': 'Agent',
        'description': 'Does stuff',
        'inputs': [
          {'name': 'query', 'type': 'string', 'description': 'The query'},
        ],
        'outputs': [],
      });
      expect(entity.id, 'agent-1');
      expect(entity.kind, 'agent');
      expect(entity.inputs, hasLength(1));
      expect(entity.inputs.first.name, 'query');
    });
  });
}
