import 'agent_run_models.dart';

/// Generic agent run provider — implement this against any backend.
abstract interface class IAgentRunProvider {
  /// Browse the catalog of runnable entities (agents, teams, workflows…).
  Future<List<AgentEntity>> listEntities({String? kind});

  Future<AgentRunStarted> startRun({required String agentId, required String input});
  Future<AgentRunStatus> fetchRun({required String agentId, required String runId});
  Future<List<AgentRunStatus>> listRuns({required String agentId});
  Future<void> cancelRun({required String agentId, required String runId});

  /// Stream of SSE events for a running agent.
  /// The implementation decides the transport (SSE, WebSocket, polling…).
  /// Use [AgUiSseChannel] from the `protocol` package as a building block.
  Stream<AgentRunStreamEvent> streamRun({required String runId});
}
