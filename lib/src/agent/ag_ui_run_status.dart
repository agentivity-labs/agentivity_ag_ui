import 'package:flutter/material.dart';

import 'agent_run_controller.dart';
import 'agent_run_models.dart';

/// Compact status badge for an agent run.
///
/// Shows a colored dot + label reflecting [AgentRunController] state.
/// Wrap with [ListenableBuilder] to rebuild on controller changes:
///
/// ```dart
/// ListenableBuilder(
///   listenable: myController,
///   builder: (context, _) => AgUiRunStatusBadge(controller: myController),
/// )
/// ```
class AgUiRunStatusBadge extends StatelessWidget {
  const AgUiRunStatusBadge({
    super.key,
    required this.controller,
    this.labelStyle,
    this.dotSize = 10,
  });

  final AgentRunController controller;
  final TextStyle? labelStyle;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: labelStyle ?? Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  (String, Color) _resolve(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (controller.isStarting) return ('Starting…', colors.tertiary);
    if (controller.isCancelling) return ('Cancelling…', colors.tertiary);
    if (controller.isConnected) return ('Running', colors.primary);
    final result = controller.result;
    if (result != null) {
      return switch (result.state) {
        AgentRunState.completed => ('Completed', Colors.green),
        AgentRunState.failed => ('Failed', colors.error),
        AgentRunState.cancelled => ('Cancelled', colors.outline),
        AgentRunState.running => ('Running', colors.primary),
      };
    }
    if (controller.errorMessage != null) return ('Error', colors.error);
    return ('Idle', colors.outline);
  }
}

/// Full run panel: input field, start/cancel button, event log, result.
class AgUiRunPanel extends StatefulWidget {
  const AgUiRunPanel({
    super.key,
    required this.controller,
    this.inputHint = 'Enter input for the agent…',
    this.eventBuilder,
    this.resultBuilder,
  });

  final AgentRunController controller;
  final String inputHint;

  /// Override rendering of a single stream event.
  final Widget Function(AgentRunStreamEvent event)? eventBuilder;

  /// Override rendering of the final result.
  final Widget Function(AgentRunStatus result)? resultBuilder;

  @override
  State<AgUiRunPanel> createState() => _AgUiRunPanelState();
}

class _AgUiRunPanelState extends State<AgUiRunPanel> {
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(AgUiRunPanel old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _inputController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              AgUiRunStatusBadge(controller: ctrl),
              const Spacer(),
              if (ctrl.isActive)
                TextButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Cancel'),
                  style:
                      TextButton.styleFrom(foregroundColor: colorScheme.error),
                  onPressed: ctrl.cancelRun,
                ),
              if (!ctrl.isActive && ctrl.runId != null)
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  onPressed: ctrl.reset,
                ),
            ],
          ),
        ),

        if (!ctrl.isActive) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: widget.inputHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (v) => _start(v),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _start(_inputController.text),
                  child: const Text('Run'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (ctrl.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(ctrl.errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 13)),
          ),

        if (ctrl.events.isNotEmpty) ...[
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: ctrl.events.length,
              itemBuilder: (context, i) {
                final event = ctrl.events[i];
                if (widget.eventBuilder != null) {
                  return widget.eventBuilder!(event);
                }
                return _EventTile(event: event);
              },
            ),
          ),
        ],

        if (ctrl.result != null) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.resultBuilder?.call(ctrl.result!) ??
                _DefaultResult(result: ctrl.result!),
          ),
        ],
      ],
    );
  }

  void _start(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    _inputController.clear();
    widget.controller.startRun(input: trimmed);
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final AgentRunStreamEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6),
          const SizedBox(width: 8),
          Text(event.eventName,
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _DefaultResult extends StatelessWidget {
  const _DefaultResult({required this.result});
  final AgentRunStatus result;

  @override
  Widget build(BuildContext context) {
    final isOk = result.state == AgentRunState.completed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOk
            ? Colors.green.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isOk ? 'Completed' : 'Failed',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isOk
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  )),
          if (result.content != null) ...[
            const SizedBox(height: 4),
            Text(result.content!),
          ],
          if (result.error != null) ...[
            const SizedBox(height: 4),
            Text(result.error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
