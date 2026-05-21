/// Step 7 — Human-in-the-Loop Forms
///
/// AgUiFormPanel presents approval and input requests. Tap Approve/Reject on
/// an approval card, or fill in fields on an input request.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Step07HilForms extends StatefulWidget {
  const Step07HilForms({super.key});

  @override
  State<Step07HilForms> createState() => _State();
}

class _State extends State<Step07HilForms> {
  late final FormController _ctrl = FormController(
    provider: _FakeFormProvider(),
    contextId: 'demo',
    channel: 'forms',
  );

  bool _loaded = false;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onCtrl);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ctrl.dispose();
    super.dispose();
  }

  void _onCtrl() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loaded = true;
      _log.clear();
    });
    await _ctrl.loadPending();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 7 — HIL Forms')),
      body: Column(
        children: [
          const StepInfoCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'AgUiFormPanel — Approval & Input',
            body: 'FormController loads pending requests via IFormProvider. '
                'AgUiFormPanel renders approval cards (approve/reject) and '
                'dynamic input forms (text, number, select, multiline). '
                'Submitting calls provider.submitResponse().',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _ctrl.isLoading ? null : _load,
                  icon: const Icon(Icons.download),
                  label: const Text('Load requests'),
                ),
              ],
            ),
          ),

          // Submission log
          if (_log.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submissions',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.outline)),
                  const SizedBox(height: 4),
                  ..._log.map((l) => Text(l, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: !_loaded
                ? Center(
                    child: Text('Press "Load requests" to see HIL forms.',
                        style: TextStyle(color: cs.outline)))
                : _ctrl.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _ctrl.requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 48, color: Colors.green),
                                const SizedBox(height: 8),
                                const Text('All requests resolved!'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _ctrl.requests.length,
                            itemBuilder: (context, i) {
                              final req = _ctrl.requests[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AgUiFormPanel(
                                  request: req,
                                  controller: _ctrl,
                                  onSubmitted: () {
                                    setState(() {
                                      _log.add('✓ Submitted ${req.id}');
                                    });
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Fake provider ─────────────────────────────────────────────────────────────

class _FakeFormProvider implements IFormProvider {
  @override
  Future<List<FormRequest>> listPending(
      {required String contextId, String? channel}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      FormRequest.fromJson({
        'id': 'req1',
        'contextId': contextId,
        'runId': 'r1',
        'nodeId': 'n1',
        'kind': 'approval',
        'channelType': 'forms',
        'title': 'Deploy to Production',
        'description':
            'Version **2.4.1** is ready. All CI checks passed.\n\n'
            '- 3 new features\n- 5 bug fixes\n- Zero breaking changes',
        'fields': <dynamic>[],
        'createdAt': '2025-01-15T09:00:00Z',
      }),
      FormRequest.fromJson({
        'id': 'req2',
        'contextId': contextId,
        'runId': 'r2',
        'nodeId': 'n2',
        'kind': 'input',
        'channelType': 'forms',
        'title': 'Configure Report',
        'description': 'Specify the report parameters.',
        'fields': [
          {
            'name': 'reportName',
            'label': 'Report name',
            'type': 'text',
            'required': true,
            'hint': 'e.g. Q2 Sales',
          },
          {
            'name': 'period',
            'label': 'Period',
            'type': 'select',
            'required': true,
            'options': ['Q1 2025', 'Q2 2025', 'Q3 2025', 'Q4 2025'],
          },
          {
            'name': 'notes',
            'label': 'Additional notes',
            'type': 'multilineText',
            'required': false,
          },
        ],
        'createdAt': '2025-01-15T09:05:00Z',
      }),
    ];
  }

  @override
  Future<FormRequest> fetchRequest({
    required String contextId,
    required String requestId,
    String? channel,
  }) =>
      throw UnimplementedError();

  @override
  Future<FormSubmitResult> submitResponse({
    required String contextId,
    required String requestId,
    required FormResponse response,
    String? channel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return FormSubmitResult(
        status: 'ok',
        contextId: contextId,
        runId: 'r1',
        requestId: requestId);
  }
}
