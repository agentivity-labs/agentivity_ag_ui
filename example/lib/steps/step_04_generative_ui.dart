/// Step 4 — Generative UI
///
/// Register Flutter widgets under names. The agent calls a tool with that
/// name (or emits a CUSTOM render event) and the controller replaces the
/// placeholder with your real widget — no rebuild required.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step04GenerativeUi extends StatefulWidget {
  const Step04GenerativeUi({super.key});

  @override
  State<Step04GenerativeUi> createState() => _State();
}

class _State extends State<Step04GenerativeUi> {
  AgUiGenerativeController? _ctrl;
  bool _running = false;

  // ── Widget registry ─────────────────────────────────────────────────────────
  final _registry = AgUiWidgetRegistry({
    // Tool name "WeatherCard" maps directly to a Flutter widget.
    'WeatherCard': (props) => _WeatherCard(
          city: jsonStr(props, 'city'),
          tempC: (jsonInt(props, 'tempC') ?? 0).toDouble(),
          condition: jsonStr(props, 'condition'),
          icon: _weatherIcon(jsonOpt(props, 'condition')),
        ),
    // A CUSTOM render event with component="StockTicker" lands here too.
    'StockTicker': (props) => _StockTicker(
          ticker: jsonStr(props, 'ticker'),
          price: jsonStr(props, 'price'),
          change: jsonStr(props, 'change'),
          up: jsonBool(props, 'up'),
        ),
  });

  static IconData _weatherIcon(String? condition) {
    final c = condition?.toLowerCase() ?? '';
    if (c.contains('sun') || c.contains('clear')) return Icons.wb_sunny;
    if (c.contains('cloud')) return Icons.cloud;
    if (c.contains('rain')) return Icons.water_drop;
    if (c.contains('snow')) return Icons.ac_unit;
    return Icons.thermostat;
  }

  Future<void> _run() async {
    _ctrl?.dispose();
    final ctrl = AgUiGenerativeController(
      events: _buildEvents(),
      widgetRegistry: _registry,
    );
    setState(() {
      _ctrl = ctrl;
      _running = true;
    });
    ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    await Future.delayed(const Duration(seconds: 6));
    if (mounted) setState(() => _running = false);
  }

  Stream<AgUiEvent> _buildEvents() async* {
    yield AgUiEvent.fromJson({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'm1',
      'role': 'assistant',
    });
    for (final c in ["Here's the ", "weather and ", "stock update:"]) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm1', 'delta': c});
    }
    yield AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});

    await Future.delayed(const Duration(milliseconds: 300));

    // Via tool call — controller replaces placeholder with WeatherCard widget
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_START',
      'toolCallId': 'tc1',
      'toolCallName': 'WeatherCard',
    });
    await Future.delayed(const Duration(milliseconds: 100));
    yield AgUiEvent.fromJson({
      'type': 'TOOL_CALL_ARGS',
      'toolCallId': 'tc1',
      'delta': '{"city":"Paris","tempC":22,"condition":"Partly cloudy"}',
    });
    await Future.delayed(const Duration(milliseconds: 600));
    yield AgUiEvent.fromJson({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'});

    await Future.delayed(const Duration(milliseconds: 500));

    // Via CUSTOM render event — second path to generative UI
    yield AgUiEvent.fromJson({
      'type': 'CUSTOM',
      'name': 'ag-ui:render',
      'value': {
        'component': 'StockTicker',
        'props': {
          'ticker': 'ACME',
          'price': '\$142.80',
          'change': '+1.3 %',
          'up': true,
        },
      },
    });

    await Future.delayed(const Duration(milliseconds: 300));

    yield AgUiEvent.fromJson({
      'type': 'TEXT_MESSAGE_START',
      'messageId': 'm2',
      'role': 'assistant',
    });
    for (final c in ['Both rendered as ', 'Flutter widgets — ', 'no WebView!']) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield AgUiEvent.fromJson(
          {'type': 'TEXT_MESSAGE_CONTENT', 'messageId': 'm2', 'delta': c});
    }
    yield AgUiEvent.fromJson({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 4 — Generative UI')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.widgets_outlined,
            title: 'AgUiWidgetRegistry — two injection paths',
            body: 'Register Flutter widgets by name. The agent either calls a '
                'tool with that name (TOOL_CALL_START/END) or emits a CUSTOM '
                '"ag-ui:render" event with component + props. Both paths '
                'resolve through the same registry — typed via json helpers.',
          ),
          StepRunBar(
            running: _running,
            onRun: _run,
            onReset: _ctrl == null
                ? null
                : () {
                    _ctrl!.clear();
                    setState(() => _running = false);
                  },
          ),
          Expanded(
            child: _ctrl == null
                ? Center(
                    child: Text('Press Run to see generative widgets.',
                        style: TextStyle(color: cs.outline)))
                : AgUiGenerativeView(
                    controller: _ctrl!,
                    registry: _registry,
                    fallbackBuilder: (name, _) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Unknown: $name',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── WeatherCard ───────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.city,
    required this.tempC,
    required this.condition,
    required this.icon,
  });

  final String city;
  final double tempC;
  final String condition;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 44, color: cs.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('${tempC.toStringAsFixed(0)} °C  ·  $condition',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

// ── StockTicker ───────────────────────────────────────────────────────────────

class _StockTicker extends StatelessWidget {
  const _StockTicker({
    required this.ticker,
    required this.price,
    required this.change,
    required this.up,
  });

  final String ticker;
  final String price;
  final String change;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = up ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('via CUSTOM ag-ui:render event',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.outline)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Icon(up ? Icons.trending_up : Icons.trending_down,
                      size: 16, color: color),
                  const SizedBox(width: 2),
                  Text(change,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
