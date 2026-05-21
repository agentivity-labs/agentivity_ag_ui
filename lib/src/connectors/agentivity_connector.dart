import 'dart:async';

import 'package:dio/dio.dart';

import '../protocol/ag_ui_protocol.dart';
import '../protocol/run_agent_input.dart';
import 'ag_ui_generic_connector.dart';

/// Connector for the [Agentivity](https://agentivity.com) platform.
///
/// Provides typed methods for running single agents or teams of agents,
/// resuming interrupted runs, and cancelling in-progress runs — all backed
/// by the AG-UI event protocol.
///
/// ## Quick start
///
/// ```dart
/// final connector = AgentivityConnector(
///   apiKey: 'ag_live_...',
///   organizationId: 'org_...',
/// );
///
/// // Run a single agent
/// final stream = connector.runAgent(
///   agentId: 'product-search',
///   input: RunAgentInput(
///     threadId: 'thread-1',
///     runId: 'run-1',
///     messages: [buildAgUiMessage('user', text: 'Find me an espresso machine')],
///   ),
/// );
///
/// // Run a team of agents
/// final stream = connector.runTeam(
///   teamId: 'shopping-team',
///   input: RunAgentInput(threadId: 'thread-2', runId: 'run-2', messages: [...]),
/// );
/// ```
///
/// ## Resuming after an interrupt
///
/// ```dart
/// // The run finished with an interrupt — show your UI, collect user input,
/// // then resume:
/// final resumeStream = connector.resumeAgent(
///   agentId: 'product-search',
///   input: RunAgentInput(
///     threadId: 'thread-1',
///     runId: 'run-2',           // new run ID for the resume run
///     messages: previousMessages,
///     resume: [
///       ResumePayload(
///         interruptId: interrupt.id,
///         status: ResumeStatus.resolved,
///         response: {'choice': 'p2'},
///       ),
///     ],
///   ),
/// );
/// ```
///
/// ## Wiring controllers
///
/// ```dart
/// final broadcast = connector.runAgent(agentId: id, input: input)
///     .asBroadcastStream();
///
/// _lifecycle = AgUiRunLifecycleController(events: broadcast);
/// _activity  = AgUiActivityController(events: broadcast);
/// _state     = AgUiStateController(events: broadcast);
/// _gen       = AgUiGenerativeController(events: broadcast);
/// ```
class AgentivityConnector {
  AgentivityConnector({
    required this.apiKey,
    this.baseUrl = 'https://api.agentivity.com',
    this.organizationId,
    Dio? dio,
  }) : _inner = AgUiGenericConnector(
          baseUrl: baseUrl,
          headers: {
            'x-api-key': apiKey,
            if (organizationId != null) 'x-organization-id': organizationId,
          },
          dio: dio,
        );

  /// Your Agentivity API key.
  final String apiKey;

  /// Agentivity API base URL. Override for self-hosted deployments.
  ///
  /// Defaults to `'https://api.agentivity.com'`.
  final String baseUrl;

  /// Optional organisation ID. Required if your key has access to multiple
  /// organisations.
  final String? organizationId;

  final AgUiGenericConnector _inner;

  // ── Single-agent runs ──────────────────────────────────────────────────────

  /// Starts a run for the agent identified by [agentId] and returns a live
  /// stream of [AgUiEvent]s.
  ///
  /// The stream ends when [RunFinishedEvent] or [RunErrorEvent] arrives.
  /// Reconnection is handled automatically.
  ///
  /// To resume after an interrupt, populate [input.resume] with the resolved
  /// [ResumePayload]s and call this method again — or use the convenience
  /// [resumeAgent] wrapper.
  Stream<AgUiEvent> runAgent({
    required String agentId,
    required RunAgentInput input,
  }) =>
      _inner.run(
        path: '/v1/agents/$agentId/runs',
        input: input,
      );

  /// Convenience wrapper: resumes agent [agentId] after an interrupt.
  ///
  /// Equivalent to calling [runAgent] with [input.resume] populated. The
  /// [input] should carry a new [RunAgentInput.runId] and the conversation
  /// history (including messages produced during the previous run).
  Stream<AgUiEvent> resumeAgent({
    required String agentId,
    required RunAgentInput input,
  }) {
    assert(
      input.resume.isNotEmpty,
      'resumeAgent: input.resume must contain at least one ResumePayload. '
      'Did you mean to call runAgent() instead?',
    );
    return runAgent(agentId: agentId, input: input);
  }

  // ── Team runs ──────────────────────────────────────────────────────────────

  /// Starts a run for the agent team identified by [teamId] and returns a
  /// live stream of [AgUiEvent]s.
  ///
  /// A team run orchestrates multiple agents in coordination. The event stream
  /// is identical in shape to a single-agent run — individual agent steps are
  /// surfaced as [StepStartedEvent] / [StepFinishedEvent] events.
  Stream<AgUiEvent> runTeam({
    required String teamId,
    required RunAgentInput input,
  }) =>
      _inner.run(
        path: '/v1/teams/$teamId/runs',
        input: input,
      );

  /// Convenience wrapper: resumes team [teamId] after an interrupt.
  ///
  /// See [resumeAgent] for the resume pattern — the same rules apply.
  Stream<AgUiEvent> resumeTeam({
    required String teamId,
    required RunAgentInput input,
  }) {
    assert(
      input.resume.isNotEmpty,
      'resumeTeam: input.resume must contain at least one ResumePayload. '
      'Did you mean to call runTeam() instead?',
    );
    return runTeam(teamId: teamId, input: input);
  }

  // ── Cancellation ───────────────────────────────────────────────────────────

  /// Cancels an in-progress agent or team run.
  ///
  /// Sends `DELETE /v1/runs/{runId}`. Callers should also dispose any active
  /// [AgUiSseChannel] or controller listening to the run's event stream.
  ///
  /// Throws a [DioException] if the server returns a non-2xx status.
  Future<void> cancel({required String runId}) async {
    final dio = Dio()
      ..options.headers['x-api-key'] = apiKey;
    if (organizationId != null) {
      dio.options.headers['x-organization-id'] = organizationId;
    }
    await dio.delete('$baseUrl/v1/runs/$runId');
    dio.close();
  }
}
