import 'dart:async';

import 'package:flutter/foundation.dart';

import '../protocol/ag_ui_protocol.dart';

/// State of the agent run tracked by [AgUiRunLifecycleController].
enum AgUiRunState { idle, running, finished, error }

/// SSE-native run lifecycle controller.
///
/// Tracks run lifecycle from [AgUiEvent] streams:
/// [RunStartedEvent], [RunFinishedEvent], [RunErrorEvent],
/// [StepStartedEvent], [StepFinishedEvent].
///
/// **When to use [AgUiRunLifecycleController] vs [AgentRunController]:**
/// - Use **[AgUiRunLifecycleController]** when you consume a raw [AgUiEvent]
///   SSE stream (e.g. from [AgUiSseChannel]). It is the AG-UI-native approach
///   and pairs with [AgUiGenerativeController] for full generative chat. Combine
///   with [RunAgentInput] + [ResumePayload] for interrupt/resume flows.
/// - Use **[AgentRunController]** when your backend exposes a separate REST
///   contract for runs (start, list, fetch result, cancel) and you need a
///   dedicated "Agent Run" management panel.
///
/// ```dart
/// final lifecycle = AgUiRunLifecycleController(events: channel.stream);
///
/// ListenableBuilder(
///   listenable: lifecycle,
///   builder: (context, _) {
///     if (lifecycle.isInterrupted) return _ResumePrompt(lifecycle.interrupts);
///     if (lifecycle.hasError)      return Text(lifecycle.errorMessage!);
///     if (lifecycle.currentStep != null) return Text('Step: ${lifecycle.currentStep}');
///     return const SizedBox.shrink();
///   },
/// )
/// ```
class AgUiRunLifecycleController extends ChangeNotifier {
  AgUiRunLifecycleController({required Stream<AgUiEvent> events}) {
    _sub = events.listen(_onEvent, onError: (_) {}, cancelOnError: false);
  }

  AgUiRunState _runState = AgUiRunState.idle;
  String? _runId;
  String? _threadId;
  String? _errorMessage;
  String? _errorCode;
  String? _currentStep;
  AgUiRunOutcome? _outcome;
  dynamic _result;

  StreamSubscription<AgUiEvent>? _sub;

  AgUiRunState get runState => _runState;
  String? get runId => _runId;
  String? get threadId => _threadId;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;

  /// The step currently executing, or `null` between steps.
  String? get currentStep => _currentStep;

  /// Raw result value from [RunFinishedEvent], if any.
  dynamic get result => _result;

  /// The run outcome, set when [runState] is [AgUiRunState.finished].
  AgUiRunOutcome? get outcome => _outcome;

  bool get isIdle => _runState == AgUiRunState.idle;
  bool get isRunning => _runState == AgUiRunState.running;
  bool get isFinished => _runState == AgUiRunState.finished;
  bool get hasError => _runState == AgUiRunState.error;

  /// `true` when the run finished with an interrupt — check [interrupts] for details.
  bool get isInterrupted => _outcome is AgUiInterruptOutcome;

  /// The interrupts from the last run, or empty if none.
  List<AgUiInterrupt> get interrupts => _outcome is AgUiInterruptOutcome
      ? (_outcome as AgUiInterruptOutcome).interrupts
      : const [];

  void _onEvent(AgUiEvent event) {
    switch (event) {
      case RunStartedEvent e:
        _runState = AgUiRunState.running;
        _runId = e.runId;
        _threadId = e.threadId;
        _errorMessage = null;
        _errorCode = null;
        _outcome = null;
        _result = null;
        _currentStep = null;
        notifyListeners();

      case RunFinishedEvent e:
        _runState = AgUiRunState.finished;
        _outcome = e.outcome;
        _result = e.result;
        _currentStep = null;
        notifyListeners();

      case RunErrorEvent e:
        _runState = AgUiRunState.error;
        _errorMessage = e.message;
        _errorCode = e.code;
        _currentStep = null;
        notifyListeners();

      case StepStartedEvent e:
        _currentStep = e.stepName;
        notifyListeners();

      case StepFinishedEvent e:
        if (_currentStep == e.stepName) _currentStep = null;
        notifyListeners();

      default:
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
