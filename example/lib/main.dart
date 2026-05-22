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

void main() => runApp(const ExampleApp());

// ── Root ─────────────────────────────────────────────────────────────────────

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Color _seed = const Color(0xFF6366f1); // indigo
  Brightness _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AG-UI Flutter — Step by Step',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: _brightness,
        ),
        useMaterial3: true,
      ),
      home: _StepListScreen(
        seed: _seed,
        brightness: _brightness,
        onSeedChanged: (c) => setState(() => _seed = c),
        onBrightnessChanged: (b) => setState(() => _brightness = b),
      ),
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
  const _StepListScreen({
    required this.seed,
    required this.brightness,
    required this.onSeedChanged,
    required this.onBrightnessChanged,
  });

  final Color seed;
  final Brightness brightness;
  final ValueChanged<Color> onSeedChanged;
  final ValueChanged<Brightness> onBrightnessChanged;

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ThemePickerSheet(
        seed: seed,
        brightness: brightness,
        onSeedChanged: onSeedChanged,
        onBrightnessChanged: onBrightnessChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AG-UI Flutter — Step by Step'),
        centerTitle: false,
        backgroundColor: cs.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Switch theme',
            onPressed: () => _openPicker(context),
          ),
        ],
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
            title: Text(
              step.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(step.subtitle, style: const TextStyle(fontSize: 12)),
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

// ── Theme picker sheet ────────────────────────────────────────────────────────

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({
    required this.seed,
    required this.brightness,
    required this.onSeedChanged,
    required this.onBrightnessChanged,
  });

  final Color seed;
  final Brightness brightness;
  final ValueChanged<Color> onSeedChanged;
  final ValueChanged<Brightness> onBrightnessChanged;

  static const _seeds = <(String, Color)>[
    ('Indigo', Color(0xFF6366f1)),
    ('Violet', Color(0xFF7c3aed)),
    ('Teal', Color(0xFF0d9488)),
    ('Rose', Color(0xFFe11d48)),
    ('Amber', Color(0xFFf59e0b)),
    ('Slate', Color(0xFF475569)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            // Brightness toggle
            Row(
              children: [
                _ModeChip(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  selected: brightness == Brightness.light,
                  onTap: () => onBrightnessChanged(Brightness.light),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  selected: brightness == Brightness.dark,
                  onTap: () => onBrightnessChanged(Brightness.dark),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'COLOR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _seeds.map((s) {
                final (label, color) = s;
                final isSelected = seed.value == color.value;
                return GestureDetector(
                  onTap: () => onSeedChanged(color),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? cs.onSurface
                                : Colors.transparent,
                            width: 2.5,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Mode chip ─────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? cs.onPrimaryContainer
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? cs.onPrimaryContainer
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
