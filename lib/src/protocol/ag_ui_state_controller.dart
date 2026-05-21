import 'dart:async';

import 'package:flutter/widgets.dart';

import '../shared/json_patch.dart';
import 'ag_ui_protocol.dart';

/// Tracks agent state from [StateSnapshotEvent] and [StateDeltaEvent] events.
///
/// Connect to any `Stream<AgUiEvent>` (e.g. from [AgUiSseChannel]):
///
/// ```dart
/// final stateCtrl = AgUiStateController(events: channel.events);
///
/// AgUiStateBuilder(
///   controller: stateCtrl,
///   builder: (context, state) => Text('${state['userName']}'),
/// )
/// ```
class AgUiStateController extends ChangeNotifier {
  AgUiStateController({required Stream<AgUiEvent> events}) {
    _sub = events.listen(_onEvent, onError: (_) {}, cancelOnError: false);
  }

  Map<String, dynamic> _state = const {};
  StreamSubscription<AgUiEvent>? _sub;

  /// The current agent state. Replaced on STATE_SNAPSHOT, patched on STATE_DELTA.
  Map<String, dynamic> get state => _state;

  /// Convenience accessor for a single top-level key.
  dynamic operator [](String key) => _state[key];

  void _onEvent(AgUiEvent event) {
    switch (event) {
      case StateSnapshotEvent e:
        final s = e.snapshot;
        _state = s is Map<String, dynamic>
            ? Map<String, dynamic>.from(s)
            : s is Map
                ? Map<String, dynamic>.from(s)
                : const {};
        notifyListeners();

      case StateDeltaEvent e:
        if (e.delta.isNotEmpty) {
          _state = AgUiJsonPatch.apply(_state, e.delta);
          notifyListeners();
        }

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

/// Rebuilds whenever [AgUiStateController] state changes.
class AgUiStateBuilder extends StatelessWidget {
  const AgUiStateBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  final AgUiStateController controller;
  final Widget Function(BuildContext context, Map<String, dynamic> state) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => builder(context, controller.state),
    );
  }
}

// JSON Patch is provided by ../shared/json_patch.dart (AgUiJsonPatch).
