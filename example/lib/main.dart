import 'package:flutter/material.dart';

import 'steps/step_01_sse_connection.dart';
import 'steps/step_02_streaming_text.dart';
import 'steps/step_03_tool_calls.dart';
import 'steps/step_04_generative_ui.dart';
import 'steps/step_05_reasoning.dart';
import 'steps/step_06_state_sync.dart';
import 'steps/step_07_hil_forms.dart';
import 'steps/step_08_interrupts_resume.dart';
import 'steps/step_09_full_stack.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AG-UI Flutter — Step by Step',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _StepListScreen(),
    );
  }
}

// ── Step definition ───────────────────────────────────────────────────────────

class _Step {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final int number;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

// ── Step catalogue ────────────────────────────────────────────────────────────

final _steps = <_Step>[
  _Step(
    number: 1,
    title: 'SSE Connection',
    subtitle: 'Open an event stream and display raw events as they arrive.',
    builder: (_) => const Step01SseConnection(),
  ),
  _Step(
    number: 2,
    title: 'Streaming Text',
    subtitle:
        'Feed events into AgUiGenerativeController and render live text bubbles.',
    builder: (_) => const Step02StreamingText(),
  ),
  _Step(
    number: 3,
    title: 'Tool Calls',
    subtitle:
        'Watch TOOL_CALL_START / END events become status cards with spinner & result.',
    builder: (_) => const Step03ToolCalls(),
  ),
  _Step(
    number: 4,
    title: 'Generative UI',
    subtitle:
        'Register a WeatherCard component — the agent renders it by name.',
    builder: (_) => const Step04GenerativeUi(),
  ),
  _Step(
    number: 5,
    title: 'Reasoning Blocks',
    subtitle:
        'Chain-of-thought blocks stream in, collapse automatically when done.',
    builder: (_) => const Step05Reasoning(),
  ),
  _Step(
    number: 6,
    title: 'State Sync',
    subtitle:
        'AgUiStateController applies JSON-Patch deltas to keep a live state map.',
    builder: (_) => const Step06StateSync(),
  ),
  _Step(
    number: 7,
    title: 'HIL Forms',
    subtitle:
        'AgUiFormPanel presents human-in-the-loop approval and input requests.',
    builder: (_) => const Step07HilForms(),
  ),
  _Step(
    number: 8,
    title: 'Interrupts & Resume',
    subtitle:
        'Detect an interrupt, show a prompt, and resume the run with ResumePayload.',
    builder: (_) => const Step08InterruptsResume(),
  ),
  _Step(
    number: 9,
    title: 'Full Stack',
    subtitle:
        'All features together: SSE lifecycle, activity bar, state sync, generative UI.',
    builder: (_) => const Step09FullStack(),
  ),
];

// ── Step list screen ──────────────────────────────────────────────────────────

class _StepListScreen extends StatelessWidget {
  const _StepListScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AG-UI Flutter — Step by Step'),
        centerTitle: false,
        backgroundColor: cs.inversePrimary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _steps.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) {
          final step = _steps[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                '${step.number}',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(step.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(step.subtitle,
                style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: step.builder,
                settings: RouteSettings(name: 'step_${step.number}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
