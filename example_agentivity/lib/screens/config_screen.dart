/// App entry — configure connection or launch the demo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme_notifier.dart';
import 'chat_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _apiKeyCtrl  = TextEditingController();
  final _baseUrlCtrl = TextEditingController(text: 'https://api.agentivity.ai');
  final _idCtrl      = TextEditingController();

  bool _useTeam    = false;
  bool _obscureKey = true;

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  void _startDemo() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ChatScreen(demoMode: true),
        ),
      );

  void _connect() {
    final apiKey = _apiKeyCtrl.text.trim();
    final id     = _idCtrl.text.trim();
    if (apiKey.isEmpty || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key and ID are required.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          demoMode: false,
          apiKey:   apiKey,
          baseUrl:  _baseUrlCtrl.text.trim(),
          agentId:  _useTeam ? null : id,
          teamId:   _useTeam ? id   : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Topbar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/agentivity_icon_blue.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      cs.onSurface, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agentivity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _ThemeToggle(),
                ],
              ),
            ),

            const Divider(),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Demo button
                    _DemoButton(cs: cs, onTap: _startDemo),

                    const SizedBox(height: 24),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or connect live',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ]),

                    const SizedBox(height: 20),

                    // API Key
                    const _Label('API Key'),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _apiKeyCtrl,
                      obscureText: _obscureKey,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'agentivity_live_…',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16,
                          ),
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Base URL
                    const _Label('Base URL'),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _baseUrlCtrl,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'https://api.agentivity.ai',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Agent / Team
                    const _Label('Connect to'),
                    const SizedBox(height: 5),
                    _Segment(
                      value: _useTeam,
                      onChange: (v) => setState(() => _useTeam = v),
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _idCtrl,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _useTeam
                            ? 'team-xxxxxxxx-…'
                            : 'agent-xxxxxxxx-…',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Connect button
                    SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: _connect,
                        icon: const Icon(Icons.bolt_rounded, size: 14),
                        label: const Text('Connect'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'API key stored in memory only — never persisted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Demo button ───────────────────────────────────────────────────────────────

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.cs, required this.onTap});
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.play_arrow_rounded,
                  color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run widget demo',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '7 widgets — choice, text, date, slider, tags, confirm, info',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ── Agent / Team segment ──────────────────────────────────────────────────────

class _Segment extends StatelessWidget {
  const _Segment(
      {required this.value, required this.onChange, required this.cs});
  final bool value;
  final ValueChanged<bool> onChange;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _SegBtn(
              label: 'Agent',
              icon: Icons.smart_toy_outlined,
              selected: !value,
              onTap: () => onChange(false),
              cs: cs),
          _SegBtn(
              label: 'Team',
              icon: Icons.groups_2_outlined,
              selected: value,
              onTap: () => onChange(true),
              cs: cs),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? cs.surfaceContainerLow : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: selected
                ? Border.all(color: cs.outlineVariant)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 12,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme toggle ──────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) ==
                    Brightness.dark);
        return GestureDetector(
          onTap: () => themeModeNotifier.value =
              isDark ? ThemeMode.light : ThemeMode.dark,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 5),
                Text(
                  isDark ? 'Dark' : 'Light',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}
