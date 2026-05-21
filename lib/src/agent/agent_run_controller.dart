import 'dart:async';

import 'package:flutter/foundation.dart';

import '../protocol/api_contract.dart';
import 'agent_run_models.dart';
import 'i_agent_run_provider.dart';

/// REST-polling agent run controller.
///
/// Manages a complete run lifecycle against a [IAgentRunProvider] that exposes
/// discrete HTTP endpoints (start, stream domain events, fetch result, cancel).
///
/// **Typical flow:**
/// 1. Call [startRun] → triggers `startRun` on the provider, opens the event stream.
/// 2. Domain [AgentRunStreamEvent]s arrive via [events] as the run executes.
/// 3. On a terminal event, [fetchRun] is called automatically to get [result].
/// 4. Call [cancelRun] to abort a running job.
///
/// **When to use [AgentRunController] vs [AgUiRunLifecycleController]:**
/// - Use **[AgentRunController]** when your backend exposes a "run" resource
///   with its own REST contract (list runs, start, poll status, cancel). Good
///   for long-running jobs and a separate "Agent Run" panel.
/// - Use **[AgUiRunLifecycleController]** (+ [AgUiGenerativeController]) when
///   you consume a raw [AgUiEvent] SSE stream directly. This is the AG-UI-native
///   streaming approach and pairs with [AgUiSseChannel].
class AgentRunController extends ChangeNotifier {
  AgentRunController({
    required IAgentRunProvider provider,
    required String agentId,
  })  : _provider = provider,
        _agentId = agentId;

  final IAgentRunProvider _provider;
  final String _agentId;

  String? _runId;
  bool _isStarting = false;
  bool _isConnected = false;
  bool _isCancelling = false;
  List<AgentRunStreamEvent> _events = const [];
  AgentRunStatus? _result;
  String? _errorMessage;

  StreamSubscription<AgentRunStreamEvent>? _eventSub;

  String? get runId => _runId;
  bool get isStarting => _isStarting;
  bool get isConnected => _isConnected;
  bool get isCancelling => _isCancelling;
  List<AgentRunStreamEvent> get events => _events;
  AgentRunStatus? get result => _result;
  String? get errorMessage => _errorMessage;

  bool get isActive =>
      _runId != null &&
      (_isStarting || _isConnected) &&
      (_result == null || !_result!.state.isTerminal);

  Future<void> startRun({required String input}) async {
    if (isActive) return;
    _isStarting = true;
    _events = const [];
    _result = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final started =
          await _provider.startRun(agentId: _agentId, input: input);
      _runId = started.runId;
      _isStarting = false;
      notifyListeners();
      _openStream(started.runId);
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'AgentRunController.startRun');
      _isStarting = false;
      _errorMessage = userFacingErrorMessage(e);
      notifyListeners();
    }
  }

  void _openStream(String runId) {
    _closeStream();
    final stream = _provider.streamRun(runId: runId);
    _isConnected = true;
    notifyListeners();

    _eventSub = stream.listen(
      (event) {
        _events = [..._events, event];
        notifyListeners();
        if (event.isTerminal) _fetchResult(runId);
      },
      onError: (Object e) {
        _isConnected = false;
        _errorMessage = userFacingErrorMessage(e);
        notifyListeners();
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  Future<void> _fetchResult(String runId) async {
    try {
      _result =
          await _provider.fetchRun(agentId: _agentId, runId: runId);
      _isConnected = false;
      _closeStream();
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'AgentRunController._fetchResult');
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancelRun() async {
    final runId = _runId;
    if (runId == null || _isCancelling) return;
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _provider.cancelRun(agentId: _agentId, runId: runId);
      _closeStream();
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'AgentRunController.cancelRun');
      _errorMessage = userFacingErrorMessage(e);
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  void reset() {
    _closeStream();
    _runId = null;
    _isStarting = false;
    _isConnected = false;
    _isCancelling = false;
    _events = const [];
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _closeStream() {
    _eventSub?.cancel();
    _eventSub = null;
    _isConnected = false;
  }

  @override
  void dispose() {
    _closeStream();
    super.dispose();
  }
}
