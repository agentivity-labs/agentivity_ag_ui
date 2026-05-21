import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../protocol/ag_ui_protocol.dart';
import '../protocol/ag_ui_sse_channel.dart';
import '../protocol/run_agent_input.dart';

/// Connector for [LangGraph Cloud](https://langchain-ai.github.io/langgraph/cloud/)
/// and self-hosted LangGraph deployments.
///
/// ## Backend requirement
///
/// Your LangGraph graph must use the official AG-UI adapter so that it emits
/// AG-UI-compatible SSE events. In Python, install and wrap your graph with
/// the [`ag-ui` package](https://github.com/ag-ui-protocol/ag-ui):
///
/// ```python
/// # server.py
/// from ag_ui.langgraph import add_agui_route
/// from your_graph import graph
///
/// app = FastAPI()
/// add_agui_route(app, graph, path="/agent")
/// ```
///
/// The connector then POSTs a [RunAgentInput] body to that endpoint and
/// consumes the AG-UI SSE stream — identical to any other AG-UI backend.
///
/// If you are using **LangGraph Cloud** (hosted service), the `deploymentUrl`
/// is the `LANGGRAPH_API_URL` shown in the LangSmith dashboard and the
/// `apiKey` is an `lsv2_*` key.
///
/// ## Quick start
///
/// ```dart
/// final connector = LangGraphConnector(
///   deploymentUrl: 'https://my-graph.langchain.app',
///   apiKey: 'lsv2_pt_...',
///   assistantId: 'my-assistant',   // the graph name or assistant UUID
/// );
///
/// final stream = connector.run(
///   input: RunAgentInput(
///     threadId: 'thread-1',
///     runId: 'run-1',
///     messages: [buildAgUiMessage('user', text: 'Plan my trip to Lisbon')],
///   ),
/// );
/// ```
///
/// ## Thread management
///
/// LangGraph persists conversation history by thread. Use [createThread] to
/// obtain a server-side thread ID before your first run, or pass any
/// client-generated UUID as `input.threadId` — LangGraph will create the
/// thread on first use.
///
/// ```dart
/// final threadId = await connector.createThread();
///
/// final stream = connector.run(
///   input: RunAgentInput(
///     threadId: threadId,
///     runId: uuid.v4(),
///     messages: [...],
///   ),
/// );
/// ```
///
/// ## Wiring controllers
///
/// ```dart
/// final broadcast = connector.run(input: input).asBroadcastStream();
///
/// _lifecycle = AgUiRunLifecycleController(events: broadcast);
/// _activity  = AgUiActivityController(events: broadcast);
/// _state     = AgUiStateController(events: broadcast);
/// _gen       = AgUiGenerativeController(events: broadcast);
/// ```
class LangGraphConnector {
  LangGraphConnector({
    required this.deploymentUrl,
    required this.apiKey,
    required this.assistantId,
    this.agentPath = '/agent',
    this.streamMode = const ['events'],
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// LangGraph Cloud deployment URL or your self-hosted server URL.
  ///
  /// No trailing slash. Example:
  /// - Cloud: `'https://my-graph-abc123.api.langchain.com'`
  /// - Self-hosted: `'http://localhost:8000'`
  final String deploymentUrl;

  /// LangGraph Cloud API key (`lsv2_*`) or your own auth token.
  final String apiKey;

  /// The LangGraph assistant or graph name to run.
  ///
  /// On LangGraph Cloud this is the assistant UUID or the graph name as
  /// configured in `langgraph.json`. Forwarded to the backend via
  /// [RunAgentInput.forwardedProps] under the key `'assistant_id'`.
  final String assistantId;

  /// Path to the AG-UI endpoint on your backend.
  ///
  /// Defaults to `'/agent'` — the path used by `add_agui_route`.
  /// Change this if you mounted the route at a different path.
  final String agentPath;

  /// LangGraph stream mode(s) forwarded to the backend as a hint.
  ///
  /// Forwarded via [RunAgentInput.forwardedProps] under `'stream_mode'`.
  /// The AG-UI adapter ignores this if it manages streaming itself; it is
  /// available for custom adapters that need it.
  ///
  /// Defaults to `['events']`.
  final List<String> streamMode;

  final Dio _dio;

  // ── Thread management ──────────────────────────────────────────────────────

  /// Creates a new thread on the LangGraph server and returns its ID.
  ///
  /// Call this before your first [run] if you want a server-managed thread ID.
  /// Alternatively, pass any UUID as `input.threadId` — LangGraph creates the
  /// thread on first use.
  Future<String> createThread({Map<String, dynamic>? metadata}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$deploymentUrl/threads',
      data: {if (metadata != null) 'metadata': metadata},
      options: Options(
        headers: _authHeaders(),
        responseType: ResponseType.json,
      ),
    );
    final body = response.data;
    final threadId = body?['thread_id'] as String?;
    if (threadId == null || threadId.isEmpty) {
      throw StateError(
          'LangGraphConnector.createThread: server did not return a thread_id. '
          'Response: $body');
    }
    return threadId;
  }

  // ── Run ────────────────────────────────────────────────────────────────────

  /// Starts an agent run and returns a live stream of [AgUiEvent]s.
  ///
  /// The stream ends when [RunFinishedEvent] or [RunErrorEvent] arrives.
  ///
  /// [assistantId] and [streamMode] are forwarded to the backend via
  /// [RunAgentInput.forwardedProps] so the AG-UI adapter can pass them to
  /// LangGraph's internal streaming API.
  ///
  /// [input.threadId] identifies the LangGraph thread. If the thread does not
  /// exist yet, LangGraph will create it automatically.
  Stream<AgUiEvent> run({required RunAgentInput input}) {
    // Merge caller-supplied forwardedProps with LangGraph-specific hints.
    final merged = <String, dynamic>{
      'assistant_id': assistantId,
      'stream_mode': streamMode,
      ...?input.forwardedProps,
    };
    final enriched = RunAgentInput(
      threadId: input.threadId,
      runId: input.runId,
      messages: input.messages,
      tools: input.tools,
      context: input.context,
      state: input.state,
      forwardedProps: merged,
      resume: input.resume,
    );
    return _runStream(path: agentPath, body: enriched.toJson());
  }

  /// Resumes the agent after an interrupt.
  ///
  /// Equivalent to [run] with [input.resume] populated.
  ///
  /// ```dart
  /// connector.resume(
  ///   input: RunAgentInput(
  ///     threadId: 'thread-1',
  ///     runId: 'run-2',
  ///     messages: previousMessages,
  ///     resume: [
  ///       ResumePayload(
  ///         interruptId: interrupt.id,
  ///         status: ResumeStatus.resolved,
  ///         response: {'approved': true},
  ///       ),
  ///     ],
  ///   ),
  /// );
  /// ```
  Stream<AgUiEvent> resume({required RunAgentInput input}) {
    assert(
      input.resume.isNotEmpty,
      'LangGraphConnector.resume: input.resume must contain at least one '
      'ResumePayload. Did you mean to call run() instead?',
    );
    return run(input: input);
  }

  // ── Cancellation ───────────────────────────────────────────────────────────

  /// Cancels an in-progress run for [threadId].
  ///
  /// Sends `POST /threads/{threadId}/runs/cancel` to the LangGraph Cloud API.
  /// Callers should also dispose any controller or channel listening to the
  /// run's event stream.
  ///
  /// [wait] — if `true`, the call blocks until the run is fully cancelled.
  ///
  /// Throws [DioException] if the server returns a non-2xx status.
  Future<void> cancel({required String threadId, bool wait = false}) async {
    await _dio.post<void>(
      '$deploymentUrl/threads/$threadId/runs/cancel',
      data: wait ? {'wait': true} : null,
      options: Options(headers: _authHeaders()),
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Map<String, String> _authHeaders() => {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      };

  Stream<AgUiEvent> _runStream({
    required String path,
    required Map<String, dynamic> body,
  }) async* {
    final channel = AgUiSseChannel<AgUiEvent>(
      opener: (p, {lastEventId, cancelToken}) async {
        final response = await _dio.post<ResponseBody>(
          deploymentUrl + p,
          data: body,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Accept': 'text/event-stream',
              if (lastEventId != null) 'Last-Event-ID': lastEventId,
              ..._authHeaders(),
            },
          ),
        );
        return response.data!;
      },
      path: path,
      parser: _parseAgUiEvent,
    );

    channel.start();
    try {
      await for (final event in channel.stream) {
        yield event;
        if (event is RunFinishedEvent || event is RunErrorEvent) break;
      }
    } finally {
      await channel.dispose();
    }
  }

  static AgUiEvent? _parseAgUiEvent(String event, String? id, String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) return AgUiEvent.fromJson(json);
    } catch (_) {
      // Malformed frame — silently discard.
    }
    return null;
  }
}
