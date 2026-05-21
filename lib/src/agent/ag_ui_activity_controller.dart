import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../protocol/ag_ui_protocol.dart';
import '../shared/json_patch.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// A single agent activity received via [ActivitySnapshotEvent] or
/// [ActivityDeltaEvent] — represents what the agent is currently doing
/// (e.g. "Searching the web…", "Reading document X…").
class AgUiActivity {
  const AgUiActivity({
    required this.messageId,
    required this.activityType,
    required this.content,
  });

  final String messageId;

  /// Categorical type set by the agent (e.g. `"search"`, `"read"`, `"think"`).
  final String activityType;

  /// Free-form content map. Inspect [label], [description], and [progress]
  /// for the most common fields, or read [content] directly.
  final Map<String, dynamic> content;

  /// Short display label, or falls back to [activityType].
  String get label => content['label']?.toString() ?? activityType;

  /// Longer human-readable description, if provided.
  String? get description => content['description']?.toString();

  /// Progress value in [0, 1], or `null` for indeterminate.
  double? get progress {
    final v = content['progress'];
    if (v is num) return v.toDouble().clamp(0.0, 1.0);
    return null;
  }

  AgUiActivity _patch(List<dynamic> ops) => AgUiActivity(
        messageId: messageId,
        activityType: activityType,
        content: AgUiJsonPatch.apply(content, ops),
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

/// Consumes [ActivitySnapshotEvent] and [ActivityDeltaEvent] from an
/// [AgUiEvent] stream and exposes the live set of agent activities.
///
/// Activities are cleared automatically when a [RunFinishedEvent] or
/// [RunErrorEvent] arrives.
///
/// ```dart
/// final activity = AgUiActivityController(events: channel.stream);
///
/// AgUiActivityView(controller: activity)  // drop-in progress indicator
///
/// // Or read manually:
/// ListenableBuilder(
///   listenable: activity,
///   builder: (context, _) => Text(activity.current?.label ?? 'Idle'),
/// )
/// ```
class AgUiActivityController extends ChangeNotifier {
  AgUiActivityController({required Stream<AgUiEvent> events}) {
    _sub = events.listen(_onEvent, onError: (_) {}, cancelOnError: false);
  }

  final Map<String, AgUiActivity> _activities = {};
  StreamSubscription<AgUiEvent>? _sub;

  /// All active activities, in insertion order.
  List<AgUiActivity> get activities => _activities.values.toList();

  /// The most recent activity, or `null` when idle.
  AgUiActivity? get current =>
      _activities.isEmpty ? null : _activities.values.last;

  bool get hasActivity => _activities.isNotEmpty;

  void _onEvent(AgUiEvent event) {
    switch (event) {
      case ActivitySnapshotEvent e:
        if (e.replace || !_activities.containsKey(e.messageId)) {
          _activities[e.messageId] = AgUiActivity(
            messageId: e.messageId,
            activityType: e.activityType,
            content: Map<String, dynamic>.from(e.content),
          );
          notifyListeners();
        }

      case ActivityDeltaEvent e:
        final existing = _activities[e.messageId];
        if (existing != null && e.patch.isNotEmpty) {
          _activities[e.messageId] = existing._patch(e.patch);
          notifyListeners();
        }

      case RunFinishedEvent _:
      case RunErrorEvent _:
        if (_activities.isNotEmpty) {
          _activities.clear();
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

// ── Widget ────────────────────────────────────────────────────────────────────

/// Displays the current agent activity from [AgUiActivityController].
///
/// Renders nothing when [AgUiActivityController.current] is `null`.
/// Provide [builder] to customize; otherwise a default progress row is shown.
///
/// ```dart
/// AgUiActivityView(
///   controller: activityController,
///   builder: (context, activity) => LinearProgressIndicator(
///     value: activity.progress,
///   ),
/// )
/// ```
class AgUiActivityView extends StatelessWidget {
  const AgUiActivityView({
    super.key,
    required this.controller,
    this.builder,
  });

  final AgUiActivityController controller;

  /// Custom renderer — return any widget for the current [AgUiActivity].
  final Widget Function(BuildContext context, AgUiActivity activity)? builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final activity = controller.current;
        if (activity == null) return const SizedBox.shrink();
        if (builder != null) return builder!(context, activity);
        return _DefaultActivityRow(activity: activity);
      },
    );
  }
}

class _DefaultActivityRow extends StatelessWidget {
  const _DefaultActivityRow({required this.activity});
  final AgUiActivity activity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final desc = activity.description;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: activity.progress,
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: colorScheme.onSurface),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
