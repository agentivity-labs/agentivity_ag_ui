/// Generic Agentivity chat screen — minimal edition.
library;

import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/demo_stream.dart';
import '../theme_notifier.dart';
import '../widgets/generic/registry.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.demoMode = true,
    this.apiKey,
    this.baseUrl,
    this.agentId,
    this.teamId,
  });

  final bool demoMode;
  final String? apiKey;
  final String? baseUrl;
  final String? agentId;
  final String? teamId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── Hub ───────────────────────────────────────────────────────────────────
  final _hub = StreamController<AgUiEvent>.broadcast();

  // ── Persistent ────────────────────────────────────────────────────────────
  late final AgUiGenerativeController _genCtrl;
  late final AgUiStateController       _stateCtrl;
  late final AgUiWidgetRegistry        _registry;

  // ── Per-run ───────────────────────────────────────────────────────────────
  AgUiRunLifecycleController? _lifecycle;
  AgUiActivityController?     _activity;
  StreamSubscription<AgUiEvent>? _hubSub;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _running     = false;
  bool _interrupted = false;
  bool _done        = false;
  bool _demoPhase2  = false;
  int  _runCounter  = 0;

  final TextEditingController _inputCtrl  = TextEditingController();
  final FocusNode             _inputFocus = FocusNode();
  AgentivityConnector? _connector;

  @override
  void initState() {
    super.initState();

    _registry = buildGenericRegistry(
      onSubmit: (component, response) => _onWidgetSubmit(component, response),
    );

    _genCtrl  = AgUiGenerativeController(
        events: _hub.stream, widgetRegistry: _registry);
    _stateCtrl = AgUiStateController(events: _hub.stream);

    _genCtrl.addListener(() { if (mounted) setState(() {}); });
    _stateCtrl.addListener(() { if (mounted) setState(() {}); });

    if (!widget.demoMode && widget.apiKey != null) {
      _connector = AgentivityConnector(
        apiKey:  widget.apiKey!,
        baseUrl: widget.baseUrl ?? 'https://api.agentivity.ai',
      );
    }

    if (widget.demoMode) {
      Future.delayed(const Duration(milliseconds: 500), _runDemoPhase1);
    }
  }

  @override
  void dispose() {
    _disposeRun();
    _hub.close();
    _genCtrl.dispose();
    _stateCtrl.dispose();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── Run management ────────────────────────────────────────────────────────

  void _startRun(Stream<AgUiEvent> stream) {
    _disposeRun();
    final broadcast = stream.asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: broadcast);
    final activity  = AgUiActivityController(events: broadcast);
    final sub = broadcast.listen(
      (e) { if (!_hub.isClosed) _hub.add(e); },
      onError: (Object e) { if (!_hub.isClosed) _hub.addError(e); },
    );

    lifecycle.addListener(() => _onLifecycle(lifecycle));
    activity.addListener(() { if (mounted) setState(() {}); });

    setState(() {
      _lifecycle    = lifecycle;
      _activity     = activity;
      _hubSub       = sub;
      _running      = true;
      _interrupted  = false;
      _done         = false;
    });
  }

  void _disposeRun() {
    final lc  = _lifecycle;
    final ac  = _activity;
    final sub = _hubSub;
    _lifecycle = null;
    _activity  = null;
    _hubSub    = null;
    sub?.cancel();
    lc?.dispose();
    ac?.dispose();
  }

  void _onLifecycle(AgUiRunLifecycleController lc) {
    if (!mounted) return;
    if (lc.isInterrupted) {
      setState(() { _running = false; _interrupted = true; });
    } else if (lc.isFinished) {
      setState(() { _running = false; _done = true; _interrupted = false; });
    } else if (lc.hasError) {
      setState(() { _running = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lc.errorMessage ?? 'Error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  // ── Demo ──────────────────────────────────────────────────────────────────

  void _runDemoPhase1() {
    if (!mounted) return;
    setState(() { _demoPhase2 = false; });
    _startRun(buildDemoStream());
  }

  void _runDemoPhase2() {
    if (!mounted) return;
    setState(() { _demoPhase2 = true; _interrupted = false; });
    _startRun(buildResumeStream());
  }

  // ── Widget submit ─────────────────────────────────────────────────────────

  void _onWidgetSubmit(String component, Map<String, dynamic> response) {
    final echo = _formatResponse(component, response);
    final ts   = DateTime.now().millisecondsSinceEpoch;
    if (!_hub.isClosed) {
      _hub.add(AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_START', 'messageId': 'u-$ts', 'role': 'user'}));
      _hub.add(AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'u-$ts', 'delta': echo}));
      _hub.add(AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_END', 'messageId': 'u-$ts'}));
    }
  }

  String _formatResponse(String c, Map<String, dynamic> r) => switch (c) {
        'ChoiceWidget'    => '${r['selected']}',
        'TextInputWidget' => r['text']?.toString() ?? '',
        'DateWidget'      => r.containsKey('date')
            ? r['date'].toString()
            : r.containsKey('datetime')
                ? r['datetime'].toString()
                : '${r['start']} → ${r['end']}',
        'SliderWidget'    => r.containsKey('value')
            ? '${r['value']}'
            : '${r['min']} – ${r['max']}',
        'TagWidget'       => (r['tags'] as List?)?.join(', ') ?? '',
        'ConfirmWidget'   => r['confirmed'] == true ? 'Confirmed' : 'Declined',
        _                 => r.toString(),
      };

  // ── Live send ─────────────────────────────────────────────────────────────

  Future<void> _sendLive() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _running) return;
    _inputCtrl.clear();
    final connector = _connector;
    if (connector == null) return;

    _runCounter++;
    final threadId = widget.agentId ?? widget.teamId ?? 'thread';
    final input = RunAgentInput(
      threadId: threadId,
      runId: 'run-$_runCounter',
      messages: [buildAgUiMessage('user', text: text)],
    );

    try {
      _startRun(widget.agentId != null
          ? connector.runAgent(agentId: widget.agentId!, input: input)
          : connector.runTeam(teamId: widget.teamId!, input: input));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final activity = _activity?.current;

    return Scaffold(
      appBar: _buildAppBar(cs),
      body: Column(
        children: [
          // Activity bar
          if (activity != null) _ActivityBar(activity: activity, cs: cs),

          // Conversation
          Expanded(
            child: _genCtrl.items.isEmpty
                ? _Splash(cs: cs, demoMode: widget.demoMode)
                : AgUiGenerativeView(
                    controller: _genCtrl,
                    registry: _registry,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  ),
          ),

          // Demo banners
          if (widget.demoMode && _interrupted && !_demoPhase2)
            _Banner(
              label: 'Complete the cards above, then continue',
              action: 'Continue',
              onTap: _runDemoPhase2,
              cs: cs,
            ),
          if (widget.demoMode && _done)
            _Banner(
              label: 'Demo complete',
              action: 'Replay',
              onTap: () {
                _genCtrl.clear();
                _runDemoPhase1();
              },
              cs: cs,
              success: true,
            ),

          // Live input
          if (!widget.demoMode)
            _LiveInput(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              running: _running,
              onSend: _sendLive,
              cs: cs,
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ColorScheme cs) {
    final label = widget.demoMode
        ? 'Widget Demo'
        : widget.agentId != null
            ? 'Agent'
            : 'Team';

    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          SvgPicture.asset(
            'assets/agentivity_icon_blue.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
          ),
          const SizedBox(width: 7),
          Text(label),
          const SizedBox(width: 8),
          // Status dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _running
                  ? Colors.green
                  : _interrupted
                      ? Colors.orange
                      : _done
                          ? cs.primary
                          : cs.outlineVariant,
            ),
          ),
        ],
      ),
      actions: [
        _ThemeToggleIcon(),
        if (widget.demoMode && !_running)
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.replay_rounded, size: 16),
            onPressed: () {
              _genCtrl.clear();
              _runDemoPhase1();
            },
          ),
        const SizedBox(width: 4),
      ],
      bottom: _running
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                  minHeight: 2),
            )
          : null,
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class _Splash extends StatelessWidget {
  const _Splash({required this.cs, required this.demoMode});
  final ColorScheme cs;
  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/agentivity_icon_blue.svg',
            width: 40,
            height: 40,
            colorFilter: ColorFilter.mode(
                cs.onSurface.withValues(alpha: 0.15), BlendMode.srcIn),
          ),
          const SizedBox(height: 12),
          Text(
            demoMode ? 'Loading…' : 'Send a message to start',
            style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}

// ── Activity bar ──────────────────────────────────────────────────────────────

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.activity, required this.cs});
  final AgUiActivity activity;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final progress = activity.progress;
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              value: progress,
              color: cs.primary,
              backgroundColor: cs.outlineVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity.label,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          if (progress != null)
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 10,
                  color: cs.primary,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

// ── Continue / done banner ────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.label,
    required this.action,
    required this.onTap,
    required this.cs,
    this.success = false,
  });
  final String label;
  final String action;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: success
          ? cs.primaryContainer
          : cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: success
                        ? cs.onPrimaryContainer
                        : cs.onSurface.withValues(alpha: 0.7))),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 28),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

// ── Live input ────────────────────────────────────────────────────────────────

class _LiveInput extends StatelessWidget {
  const _LiveInput({
    required this.controller,
    required this.focusNode,
    required this.running,
    required this.onSend,
    required this.cs,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool running;
  final VoidCallback onSend;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surface,
      padding: EdgeInsets.fromLTRB(
          12, 6, 12, MediaQuery.of(context).viewInsets.bottom + 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !running,
                style: const TextStyle(fontSize: 13),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: running ? 'Thinking…' : 'Message…',
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: running ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: running
                      ? cs.surfaceContainerHighest
                      : cs.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: running
                    ? Padding(
                        padding: const EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: cs.primary),
                      )
                    : Icon(Icons.send_rounded,
                        color: cs.onPrimary, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme toggle icon ─────────────────────────────────────────────────────────

class _ThemeToggleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 16,
          ),
          onPressed: () => themeModeNotifier.value =
              isDark ? ThemeMode.light : ThemeMode.dark,
        );
      },
    );
  }
}
