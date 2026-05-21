import 'package:flutter/foundation.dart';

import '../shared/json_helpers.dart';

/// A runnable entity in the catalog (agent, team, workflow, …).
@immutable
class AgentEntity {
  const AgentEntity({
    required this.id,
    required this.displayName,
    required this.kind,
    this.description,
    this.inputs = const [],
    this.outputs = const [],
  });

  final String id;
  final String displayName;

  /// e.g. "agent" | "team" | "workflow"
  final String kind;
  final String? description;
  final List<AgentEntityPort> inputs;
  final List<AgentEntityPort> outputs;

  factory AgentEntity.fromJson(Map<String, dynamic> json) {
    List<AgentEntityPort> parsePorts(dynamic raw) {
      if (raw is! List) return const [];
      return raw.whereType<Object>().map((e) {
        final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
        return AgentEntityPort.fromJson(map);
      }).toList(growable: false);
    }

    return AgentEntity(
      id: jsonStr(json, 'id'),
      displayName: jsonStr(json, 'displayName'),
      kind: jsonStr(json, 'kind').toLowerCase(),
      description: jsonOpt(json, 'description'),
      inputs: parsePorts(jsonLookup(json, 'inputs')),
      outputs: parsePorts(jsonLookup(json, 'outputs')),
    );
  }
}

@immutable
class AgentEntityPort {
  const AgentEntityPort({required this.name, required this.type, this.description});

  final String name;
  final String type;
  final String? description;

  factory AgentEntityPort.fromJson(Map<String, dynamic> json) {
    return AgentEntityPort(
      name: jsonStr(json, 'name'),
      type: jsonStr(json, 'type'),
      description: jsonOpt(json, 'description'),
    );
  }
}

@immutable
class AgentRunStarted {
  const AgentRunStarted({
    required this.runId,
    required this.agentId,
    required this.streamUrl,
    required this.statusUrl,
  });

  final String runId;
  final String agentId;
  final String streamUrl;
  final String statusUrl;

  factory AgentRunStarted.fromJson(Map<String, dynamic> json) {
    return AgentRunStarted(
      runId: jsonStr(json, 'runId'),
      agentId: jsonStr(json, 'agentId'),
      streamUrl: jsonStr(json, 'streamUrl'),
      statusUrl: jsonStr(json, 'statusUrl'),
    );
  }
}

enum AgentRunState {
  running,
  completed,
  failed,
  cancelled;

  factory AgentRunState.fromApi(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'completed':
        return AgentRunState.completed;
      case 'failed':
        return AgentRunState.failed;
      case 'cancelled':
        return AgentRunState.cancelled;
      default:
        return AgentRunState.running;
    }
  }

  bool get isTerminal =>
      this == completed || this == failed || this == cancelled;
}

@immutable
class AgentRunStatus {
  const AgentRunStatus({
    required this.runId,
    required this.agentId,
    required this.state,
    this.content,
    this.error,
    this.createdAt,
    this.completedAt,
  });

  final String runId;
  final String agentId;
  final AgentRunState state;
  final String? content;
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory AgentRunStatus.fromJson(Map<String, dynamic> json) {
    return AgentRunStatus(
      runId: jsonStr(json, 'runId'),
      agentId: jsonStr(json, 'agentId'),
      state: AgentRunState.fromApi(jsonStr(json, 'state')),
      content: jsonOpt(json, 'content'),
      error: jsonOpt(json, 'error'),
      createdAt: jsonDateTime(json, 'createdAt'),
      completedAt: jsonDateTime(json, 'completedAt'),
    );
  }
}

/// SSE event emitted by the agent run stream.
class AgentRunStreamEvent {
  const AgentRunStreamEvent({
    required this.eventId,
    required this.runId,
    required this.kind,
    required this.eventName,
    required this.occurredAt,
    required this.payload,
  });

  final String eventId;
  final String runId;
  final String kind;
  final String eventName;
  final String occurredAt;
  final Map<String, dynamic> payload;

  static const _terminalEvents = {'run_completed', 'run_failed', 'run_cancelled'};

  bool get isTerminal => _terminalEvents.contains(eventName);

  factory AgentRunStreamEvent.fromJson(Map<String, dynamic> json) {
    return AgentRunStreamEvent(
      eventId: json['eventId'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      eventName: json['eventName'] as String? ?? '',
      occurredAt: json['occurredAt'] as String? ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : json['payload'] is Map
              ? Map<String, dynamic>.from(json['payload'] as Map)
              : const {},
    );
  }
}
